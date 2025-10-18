//
//  ScanCode.swift
//  CareSync
//
//  Created by Mikael Weiss on 10/11/25.
//

import SwiftUI
import VisionKit
import Vision

struct ScanCode: View {
    @State private var scannedCode: String?
    @State private var isShowingScanner = false
    @State private var isLoadingMedication = false
    @State private var scannedMedication: Medication?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoadingMedication {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Looking up medication...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if let medication = scannedMedication {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Medication Found")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent("Brand:", value: medication.brandName)
                            LabeledContent("Generic:", value: medication.genericName)
                            LabeledContent("Dosage:", value: medication.dosage)
                            LabeledContent("Form:", value: medication.form)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                } else if let code = scannedCode {
                    VStack(spacing: 12) {
                        Text("Scanned Barcode")
                            .font(.headline)
                        Text(code)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    .padding()
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }

                Button("Start Scanning") {
                    isShowingScanner = true
                    scannedMedication = nil
                    errorMessage = nil
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoadingMedication)

                Spacer()
            }
            .navigationTitle("Scan Barcode")
            .sheet(isPresented: $isShowingScanner) {
                BarcodeScannerView(scannedCode: $scannedCode, isPresented: $isShowingScanner)
                    .ignoresSafeArea()
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

        let medication = await MedicationAPIService.lookupMedication(barcode: barcode)

        await MainActor.run {
            isLoadingMedication = false
            if let medication = medication {
                scannedMedication = medication
            } else {
                errorMessage = "Medication not found for barcode: \(barcode)"
            }
        }
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
