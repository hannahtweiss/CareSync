//
//  ScanCode.swift
//  CareSync
//
//  Created by Mikael Weiss on 10/11/25.
//

import SwiftUI
import VisionKit
import Vision
import SwiftData

struct ScanCode: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scannedCode: String?
    @State private var isShowingScanner = false
    @State private var isLoadingMedication = false
    @State private var scannedMedication: Medication?
    @State private var errorMessage: String?
    @State private var showingMedicationSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoadingMedication {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Looking up medication...")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Scan Medication Barcode")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Point your camera at the barcode on your medication bottle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Start Scanning") {
                            isShowingScanner = true
                            scannedMedication = nil
                            errorMessage = nil
                        }
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)

                        if let errorMsg = errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)

                                Text("Scan Failed")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)

                                Text(errorMsg)
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)

                                Button("Try Again") {
                                    self.errorMessage = nil
                                    self.isShowingScanner = true
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.gray)
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                BarcodeScannerView(scannedCode: $scannedCode, isPresented: $isShowingScanner)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingMedicationSheet) {
                if let medication = scannedMedication {
                    MedicationDetailSheet(
                        medication: medication,
                        onAdd: {
                            saveMedication()
                        },
                        onCancel: {
                            showingMedicationSheet = false
                            scannedMedication = nil
                        }
                    )
                }
            }
            .onChange(of: scannedCode) { oldValue, newValue in
                if let newValue = newValue {
                    Task {
                        await lookupMedication(barcode: newValue)
                    }
                }
            }
        }
    }

    private func lookupMedication(barcode: String) async {
        isLoadingMedication = true
        errorMessage = nil

        print("Starting medication lookup for barcode: \(barcode)")
        let (medication, apiError) = await MedicationAPIService.lookupMedication(barcode: barcode)

        await MainActor.run {
            isLoadingMedication = false
            if let medication {
                print("Medication found, processing...")
                // Parse dosage to get simplified instructions and times per day
                let timesPerDay = DosageParser.parseTimesPerDay(from: medication.schedule)
                let simplifiedInstructions = DosageParser.simplifyInstructions(
                    from: medication.schedule,
                    form: medication.form
                )

                medication.timesPerDay = timesPerDay
                medication.simplifiedInstructions = simplifiedInstructions

                // Regenerate scheduled times based on the parsed timesPerDay
                medication.scheduledTimes = generateScheduledTimes(count: timesPerDay)

                scannedMedication = medication
                showingMedicationSheet = true
                print("Showing medication detail sheet")
            } else {
                // Show detailed error message from API
                let message = apiError ?? "Medication not found for barcode: \(barcode)"
                errorMessage = message
                print("Error: \(message)")
            }
        }
    }

    private func generateScheduledTimes(count: Int) -> [Date] {
        let calendar = Calendar.current
        var times: [Date] = []

        switch count {
        case 1:
            // Once daily at 9:00 AM
            times.append(calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
        case 2:
            // Twice daily at 9:00 AM and 9:00 PM
            times.append(calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date())
        case 3:
            // Three times daily at 8:00 AM, 2:00 PM, 8:00 PM
            times.append(calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date())
        case 4:
            // Four times daily at 8:00 AM, 12:00 PM, 4:00 PM, 8:00 PM
            times.append(calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date())
        default:
            // For more than 4 times, space them evenly throughout the day
            let hoursApart = 24 / max(count, 1)
            for i in 0..<count {
                let hour = 8 + (i * hoursApart)
                times.append(calendar.date(bySettingHour: hour % 24, minute: 0, second: 0, of: Date()) ?? Date())
            }
        }

        return times
    }

    private func saveMedication() {
        guard let medication = scannedMedication else { return }

        modelContext.insert(medication)

        // Dismiss both sheets
        showingMedicationSheet = false
        dismiss()

        // Reset state
        scannedMedication = nil
        scannedCode = nil
    }
}

#Preview {
    ScanCode()
}

@MainActor
struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [
                    .ean8, .ean13, .upce, .code39, .code93, .code128, .itf14, .i2of5
                ])
            ],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )

        scanner.delegate = context.coordinator

        // Start scanning automatically
        try? scanner.startScanning()

        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, isPresented: $isPresented)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var scannedCode: String?
        @Binding var isPresented: Bool

        init(scannedCode: Binding<String?>, isPresented: Binding<Bool>) {
            self._scannedCode = scannedCode
            self._isPresented = isPresented
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let item = addedItems.first else { return }

            switch item {
            case .barcode(let barcode):
                if let payloadString = barcode.payloadStringValue {
                    scannedCode = payloadString
                    dataScanner.stopScanning()
                    isPresented = false
                }
            default:
                break
            }
        }
    }
}
