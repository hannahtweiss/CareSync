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

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.large)
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

        var medication = await MedicationAPIService.lookupMedication(barcode: barcode)

        await MainActor.run {
            isLoadingMedication = false
            if var medication = medication {
                // Parse dosage to get simplified instructions and times per day
                medication.timesPerDay = DosageParser.parseTimesPerDay(from: medication.schedule)
                medication.simplifiedInstructions = DosageParser.simplifyInstructions(
                    from: medication.schedule,
                    form: medication.form
                )

                scannedMedication = medication
                showingMedicationSheet = true
            } else {
                errorMessage = "Medication not found for barcode: \(barcode)"
            }
        }
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
