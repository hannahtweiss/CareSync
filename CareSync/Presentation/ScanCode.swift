//
//  ScanCode.swift
//  CareSync
//
//  Created by Mikael Weiss on 10/11/25.
//

import SwiftUI
import VisionKit

struct ScanCode: View {
    @State private var scannedCode: String?
    @State private var isShowingScanner = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let code = scannedCode {
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

                Button("Start Scanning") {
                    isShowingScanner = true
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Scan Barcode")
            .sheet(isPresented: $isShowingScanner) {
                BarcodeScannerView(scannedCode: $scannedCode, isPresented: $isShowingScanner)
                    .ignoresSafeArea()
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
            recognizedDataTypes: [.barcode()],
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
