//
//  ScanCode.swift
//  CareSync
//
//  Created by Mikael Weiss on 10/11/25.
//

import SwiftUI
@preconcurrency import VisionKit
@preconcurrency import Vision
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
    @State private var scannedText: String?
    @State private var scanMode: ScanMode = .barcode
    @State private var recognizedTextPreview: [String] = []
    @State private var isReadingLabel: Bool = false

    enum ScanMode {
        case barcode
        case label
    }

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
                        // Mode selector
                        Picker("Scan Mode", selection: $scanMode) {
                            Text("Barcode").tag(ScanMode.barcode)
                            Text("Label").tag(ScanMode.label)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        Image(systemName: scanMode == .barcode ? "barcode.viewfinder" : "doc.text.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text(scanMode == .barcode ? "Scan Medication Barcode" : "Scan Prescription Label")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text(scanMode == .barcode ?
                             "Point your camera at the barcode on your medication bottle" :
                             "Point your camera at the prescription label text. Hold steady to capture.")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Start Scanning") {
                            isShowingScanner = true
                            scannedMedication = nil
                            errorMessage = nil
                            recognizedTextPreview = [] // Reset preview
                            isReadingLabel = false // Reset status
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
                BarcodeScannerView(
                    scannedCode: $scannedCode,
                    scannedText: $scannedText,
                    scanMode: scanMode,
                    isPresented: $isShowingScanner,
                    recognizedTextPreview: $recognizedTextPreview,
                    isReadingLabel: $isReadingLabel
                )
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
            .onChange(of: scannedText) { oldValue, newValue in
                if let newValue = newValue {
                    parsePrescriptionLabel(text: newValue)
                }
            }
        }
    }

    private func parsePrescriptionLabel(text: String) {
        isLoadingMedication = true
        errorMessage = nil

        print("Processing prescription label text...")

        Task {
            if let medication = await PrescriptionLabelParser.parsePrescriptionLabel(text: text) {
            // Parse dosage to get simplified instructions and times per day
            let timesPerDay = DosageParser.parseTimesPerDay(from: medication.schedule)
            let simplifiedInstructions = DosageParser.simplifyInstructions(
                from: medication.schedule,
                form: medication.form
            )

            medication.timesPerDay = timesPerDay
            medication.simplifiedInstructions = simplifiedInstructions
            medication.scheduledTimes = generateScheduledTimes(count: timesPerDay)

                await MainActor.run {
                    scannedMedication = medication
                    showingMedicationSheet = true
                    isLoadingMedication = false
                    print("Successfully created medication from prescription label")
                }
            } else {
                await MainActor.run {
                    errorMessage = "Could not read prescription label. Please try again or ensure the label is clearly visible."
                    isLoadingMedication = false
                    print("Failed to parse prescription label")
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

// MARK: - Scanner Overlay View with Animation
struct ScannerOverlayView: View {
    let scanMode: ScanCode.ScanMode
    @State private var animationOffset: CGFloat = 0
    @Binding var recognizedText: [String]
    @Binding var isReadingLabel: Bool
    var onCaptureButtonTapped: (() -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark overlay with cutout
                Color.black.opacity(0.5)
                    .overlay {
                        // Cutout for scan area
                        Rectangle()
                            .frame(width: geometry.size.width * 0.8, height: 200)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()

                // Guide box
                VStack(spacing: 0) {
                    Spacer()

                    ZStack {
                        // Corner brackets
                        CornerBracketsView()
                            .frame(width: geometry.size.width * 0.8, height: 200)

                        // Animated scanning line (only for barcode mode)
                        if scanMode == .barcode {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.yellow.opacity(0),
                                            Color.yellow.opacity(0.8),
                                            Color.yellow.opacity(0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: geometry.size.width * 0.8, height: 6)
                                .offset(y: animationOffset - 100) // Center the range at 0
                        }
                    }
                    .frame(width: geometry.size.width * 0.8, height: 200)

                    Spacer()
                }

                // Instructions and status
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.6)

                    // Show status for label mode
                    if scanMode == .label {
                        VStack(spacing: 12) {
                            // Status indicator
                            if isReadingLabel {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                                    Text("Processing label...")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                            } else {
                                Text("Position label in frame, then capture")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(10)

                                // Capture button
                                Button(action: {
                                    onCaptureButtonTapped?()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                        Text("Capture Label")
                                    }
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 16)
                                    .background(Color.yellow)
                                    .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                        }
                    } else {
                        Text("Align barcode within frame")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        withAnimation(
            Animation.linear(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            animationOffset = 200 // Goes from 0 to 200, which translates to -100 to +100 with the offset
        }
    }
}

// MARK: - Corner Brackets View
struct CornerBracketsView: View {
    var body: some View {
        ZStack {
            // Top-left corner
            Path { path in
                path.move(to: CGPoint(x: 30, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 30))
            }
            .stroke(Color.yellow, lineWidth: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Top-right corner
            Path { path in
                path.move(to: CGPoint(x: -30, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 30))
            }
            .stroke(Color.yellow, lineWidth: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // Bottom-left corner
            Path { path in
                path.move(to: CGPoint(x: 0, y: -30))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 30, y: 0))
            }
            .stroke(Color.yellow, lineWidth: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            // Bottom-right corner
            Path { path in
                path.move(to: CGPoint(x: 0, y: -30))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: -30, y: 0))
            }
            .stroke(Color.yellow, lineWidth: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
}

@MainActor
struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var scannedText: String?
    let scanMode: ScanCode.ScanMode
    @Binding var isPresented: Bool
    @Binding var recognizedTextPreview: [String]
    @Binding var isReadingLabel: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        var recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> = []

        switch scanMode {
        case .barcode:
            recognizedDataTypes = [
                .barcode(symbologies: [
                    .ean8, .ean13, .upce, .code39, .code93, .code128, .itf14, .i2of5
                ])
            ]
        case .label:
            recognizedDataTypes = [
                .text(languages: ["en"])
            ]
        }

        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .accurate,
            recognizesMultipleItems: scanMode == .label,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: false // Disable built-in highlighting to use custom overlay
        )

        scanner.delegate = context.coordinator

        // Start scanning automatically
        try? scanner.startScanning()

        // Hide any additional UI controls from DataScannerViewController
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.hideAllControlsRecursively(in: scanner.view)
        }

        // Create container view controller to hold scanner + overlay
        let containerVC = UIViewController()
        containerVC.addChild(scanner)
        containerVC.view.addSubview(scanner.view)
        scanner.view.frame = containerVC.view.bounds
        scanner.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scanner.didMove(toParent: containerVC)

        // Add SwiftUI overlay
        let overlayView = ScannerOverlayView(
            scanMode: scanMode,
            recognizedText: $recognizedTextPreview,
            isReadingLabel: $isReadingLabel,
            onCaptureButtonTapped: {
                // Capture snapshot when button is tapped
                context.coordinator.captureSnapshot(from: scanner)
            }
        )
        let hostingController = UIHostingController(rootView: overlayView)
        hostingController.view.backgroundColor = .clear
        containerVC.addChild(hostingController)
        containerVC.view.addSubview(hostingController.view)
        hostingController.view.frame = containerVC.view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: containerVC)

        // Store the scanner reference in coordinator
        context.coordinator.dataScanner = scanner

        return containerVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            scannedCode: $scannedCode,
            scannedText: $scannedText,
            scanMode: scanMode,
            isPresented: $isPresented,
            recognizedTextPreview: $recognizedTextPreview,
            isReadingLabel: $isReadingLabel
        )
    }

    // Helper function to recursively hide all UI controls
    private func hideAllControlsRecursively(in view: UIView) {
        for subview in view.subviews {
            // Hide buttons, controls, and any interactive overlays
            if subview is UIButton ||
               subview is UIControl ||
               String(describing: type(of: subview)).contains("Button") ||
               String(describing: type(of: subview)).contains("Overlay") {
                subview.isHidden = true
                subview.alpha = 0
            }
            // Recursively check subviews
            hideAllControlsRecursively(in: subview)
        }
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var scannedCode: String?
        @Binding var scannedText: String?
        let scanMode: ScanCode.ScanMode
        @Binding var isPresented: Bool
        @Binding var recognizedTextPreview: [String]
        @Binding var isReadingLabel: Bool
        weak var dataScanner: DataScannerViewController?

        init(scannedCode: Binding<String?>, scannedText: Binding<String?>, scanMode: ScanCode.ScanMode, isPresented: Binding<Bool>, recognizedTextPreview: Binding<[String]>, isReadingLabel: Binding<Bool>) {
            self._scannedCode = scannedCode
            self._scannedText = scannedText
            self.scanMode = scanMode
            self._isPresented = isPresented
            self._recognizedTextPreview = recognizedTextPreview
            self._isReadingLabel = isReadingLabel
        }

        // Capture snapshot and extract text using Vision framework
        func captureSnapshot(from scanner: DataScannerViewController) {
            print("📸 Capturing snapshot of prescription label...")

            Task { @MainActor in
                self.isReadingLabel = true
            }

            // Get the current frame from the scanner's view
            guard let capturedImage = captureImage(from: scanner.view) else {
                print("❌ Failed to capture image from scanner view")
                Task { @MainActor in
                    self.isReadingLabel = false
                }
                return
            }

            print("✅ Snapshot captured, extracting text...")

            // Extract text from the captured image using Vision
            extractText(from: capturedImage) { [weak self] extractedText in
                guard let self = self else { return }

                Task { @MainActor in
                    if let text = extractedText, !text.isEmpty {
                        print("✅ Extracted text from snapshot:")
                        print(text)
                        self.scannedText = text
                        scanner.stopScanning()
                        self.isPresented = false
                        self.isReadingLabel = false
                    } else {
                        print("❌ No text found in snapshot")
                        self.isReadingLabel = false
                    }
                }
            }
        }

        // Capture image from UIView
        private func captureImage(from view: UIView) -> UIImage? {
            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            return renderer.image { context in
                view.layer.render(in: context.cgContext)
            }
        }

        // Extract text from image using Vision framework
        private func extractText(from image: UIImage, completion: @escaping (String?) -> Void) {
            guard let cgImage = image.cgImage else {
                completion(nil)
                return
            }

            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("❌ Vision text recognition error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion(nil)
                    return
                }

                // Extract all recognized text
                let recognizedLines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedLines.joined(separator: "\n")
                completion(fullText.isEmpty ? nil : fullText)
            }

            // Configure text recognition
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true

            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async { [request, handler] in
                do {
                    try handler.perform([request])
                } catch {
                    print("❌ Failed to perform Vision request: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Only handle barcode scanning here - label scanning uses manual capture
            guard scanMode == .barcode else { return }

            guard let item = addedItems.first else { return }
            if case .barcode(let barcode) = item {
                if let payloadString = barcode.payloadStringValue {
                    scannedCode = payloadString
                    dataScanner.stopScanning()
                    isPresented = false
                }
            }
        }
    }
}
