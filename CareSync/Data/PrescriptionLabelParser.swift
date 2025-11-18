//
//  PrescriptionLabelParser.swift
//  CareSync
//
//  Created by Claude on 11/17/25.
//

import Foundation

struct PrescriptionLabelParser {

    /// Parses text from a prescription label and extracts medication information
    /// Uses AI (OpenAI GPT-3.5) for intelligent extraction with manual fallback
    static func parsePrescriptionLabel(text: String) async -> Medication? {
        print("📋 Parsing prescription label text...")

        // Try AI-powered parsing first
        if let aiResult = await OpenAIService.parsePrescriptionLabelWithAI(text: text) {
            return createMedicationFromAI(
                name: aiResult.name,
                directions: aiResult.directions,
                warnings: aiResult.warnings
            )
        }

        print("⚠️ AI parsing unavailable, using manual parsing...")
        return manualParsing(text: text)
    }

    /// Creates a Medication object from AI-extracted information
    private static func createMedicationFromAI(name: String, directions: String, warnings: String) -> Medication {
        print("🤖 Creating medication from AI-extracted data...")

        var brandName = name
        var dosage: String?
        var form: String?

        // Extract dosage from name (e.g., "LISINOPRIL 10MG")
        if let extractedDosage = extractDosage(from: name) {
            dosage = extractedDosage
            brandName = name.replacingOccurrences(of: extractedDosage, with: "").trimmingCharacters(in: .whitespaces)
        }

        // Extract form from name (e.g., "TABLET")
        if let extractedForm = extractForm(from: name.lowercased()) {
            form = extractedForm
            brandName = brandName.replacingOccurrences(of: extractedForm.uppercased(), with: "")
                .replacingOccurrences(of: extractedForm.capitalized, with: "")
                .trimmingCharacters(in: .whitespaces)
        }

        let medication = Medication(
            brandName: brandName,
            genericName: extractGenericFromBrandName(brandName),
            dosage: dosage ?? "See label",
            form: form ?? "Not specified",
            schedule: directions,
            duration: "As prescribed",
            warnings: warnings != "None listed" ? warnings : nil
        )

        print("✅ AI-powered medication created:")
        print("   Name: \(medication.brandName)")
        print("   Directions: \(medication.schedule)")
        print("   Warnings: \(medication.warnings ?? "None")")

        return medication
    }

    /// Manual parsing fallback when AI is unavailable
    private static func manualParsing(text: String) -> Medication? {
        print("📝 Using manual parsing...")

        let cleanedText = text.replacingOccurrences(of: "\n\n", with: "\n")
        let lines = cleanedText.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count >= 2 else {
            print("❌ Not enough lines for manual parsing")
            return nil
        }

        // FIRST LINE = Medication Name
        let medicationNameLine = lines[0]
        print("Medication name line: \(medicationNameLine)")

        // SUBSEQUENT LINES = Instructions
        let instructionLines = Array(lines[1...])
        let fullInstructions = instructionLines.joined(separator: " ")
        print("Instructions: \(fullInstructions)")

        // Extract medication information
        var brandName = medicationNameLine
        var genericName: String?
        var dosage: String?
        var form: String?

        // Extract dosage
        if let extractedDosage = extractDosage(from: medicationNameLine) {
            dosage = extractedDosage
            brandName = medicationNameLine.replacingOccurrences(of: extractedDosage, with: "").trimmingCharacters(in: .whitespaces)
        }

        // Extract form
        if let extractedForm = extractForm(from: medicationNameLine.lowercased()) {
            form = extractedForm
            brandName = brandName.replacingOccurrences(of: extractedForm.uppercased(), with: "")
                .replacingOccurrences(of: extractedForm.capitalized, with: "")
                .trimmingCharacters(in: .whitespaces)
        }

        // Extract generic name
        if let generic = extractParenthetical(from: medicationNameLine) {
            genericName = generic
        }

        let finalDosage = dosage ?? "See label"
        let finalForm = form ?? "Not specified"
        let finalGenericName = genericName ?? extractGenericFromBrandName(brandName)

        let medication = Medication(
            brandName: brandName,
            genericName: finalGenericName,
            dosage: finalDosage,
            form: finalForm,
            schedule: fullInstructions.isEmpty ? "As directed" : fullInstructions,
            duration: "As prescribed",
            warnings: nil
        )

        print("✅ Manual parsing complete:")
        print("   Brand: \(medication.brandName)")
        print("   Dosage: \(medication.dosage)")
        print("   Schedule: \(medication.schedule)")

        return medication
    }

    // MARK: - Helper Methods

    private static func extractParenthetical(from text: String) -> String? {
        if let start = text.firstIndex(of: "("),
           let end = text.firstIndex(of: ")"),
           start < end {
            let content = text[text.index(after: start)..<end]
            return String(content).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private static func extractDosage(from text: String) -> String? {
        let pattern = #"(\d+\.?\d*)\s*(mg|mcg|g|ml|iu|units?|%)\b"#

        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(match.range, in: text) {
                return String(text[range])
            }
        }

        return nil
    }

    private static func extractForm(from lowerText: String) -> String? {
        let forms = [
            "tablet", "tablets", "tab",
            "capsule", "capsules", "cap",
            "softgel", "softgels",
            "liquid", "solution", "suspension",
            "cream", "ointment", "gel",
            "patch", "patches",
            "inhaler", "spray",
            "injection", "injectable"
        ]

        for formWord in forms {
            if lowerText.contains(formWord) {
                if formWord == "tablets" || formWord == "tab" {
                    return "Tablet"
                } else if formWord == "capsules" || formWord == "cap" {
                    return "Capsule"
                } else {
                    return formWord.capitalized
                }
            }
        }

        return nil
    }

    private static func extractGenericFromBrandName(_ brandName: String) -> String {
        if let generic = extractParenthetical(from: brandName) {
            return generic
        }
        return brandName
    }
}
