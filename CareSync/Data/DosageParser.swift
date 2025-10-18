//
//  DosageParser.swift
//  CareSync
//
//  Created by Claude Code
//

import Foundation

struct DosageParser {

    /// Parses a dosage string and returns the number of times per day to take the medication
    static func parseTimesPerDay(from dosageString: String) -> Int {
        let lowercased = dosageString.lowercased()

        // Check for specific frequencies
        if lowercased.contains("four times") || lowercased.contains("4 times") || lowercased.contains("qid") {
            return 4
        }
        if lowercased.contains("three times") || lowercased.contains("3 times") || lowercased.contains("tid") {
            return 3
        }
        if lowercased.contains("twice") || lowercased.contains("two times") || lowercased.contains("2 times") || lowercased.contains("bid") {
            return 2
        }
        if lowercased.contains("once") || lowercased.contains("daily") || lowercased.contains("1 time") || lowercased.contains("one time") {
            return 1
        }

        // Check for "every X hours" patterns
        if let range = lowercased.range(of: #"every\s+(\d+)\s+hour"#, options: .regularExpression) {
            let hoursString = String(lowercased[range]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let hours = Int(hoursString), hours > 0 {
                return 24 / hours
            }
        }

        // Default to once daily if we can't parse
        return 1
    }

    /// Converts a dosage string into simplified, elderly-friendly instructions
    static func simplifyInstructions(from dosageString: String, form: String) -> String {
        let lowercased = dosageString.lowercased()
        let timesPerDay = parseTimesPerDay(from: dosageString)

        // Extract quantity (number of pills/tablets)
        var quantity = 1
        if let range = lowercased.range(of: #"\b(\d+)\s+(tablet|pill|capsule|caplet)"#, options: .regularExpression) {
            let quantityString = String(lowercased[range]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            quantity = Int(quantityString) ?? 1
        }

        // Determine the form name (pill, tablet, etc.)
        let formName: String
        if form.lowercased().contains("capsule") {
            formName = quantity == 1 ? "capsule" : "capsules"
        } else if form.lowercased().contains("tablet") {
            formName = quantity == 1 ? "tablet" : "tablets"
        } else if form.lowercased().contains("pill") {
            formName = quantity == 1 ? "pill" : "pills"
        } else {
            formName = quantity == 1 ? "pill" : "pills" // Default to "pill"
        }

        // Handle special cases
        if lowercased.contains("as directed") || lowercased.contains("as needed") {
            return "Take as your doctor tells you"
        }

        // Build simplified instruction
        let quantityText = quantity == 1 ? "1" : "\(quantity)"

        switch timesPerDay {
        case 1:
            return "Take \(quantityText) \(formName) each day"
        case 2:
            return "Take \(quantityText) \(formName) twice a day"
        case 3:
            return "Take \(quantityText) \(formName) 3 times a day"
        case 4:
            return "Take \(quantityText) \(formName) 4 times a day"
        default:
            return "Take \(quantityText) \(formName) \(timesPerDay) times a day"
        }
    }
}
