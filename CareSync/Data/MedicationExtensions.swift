//
//  MedicationExtensions.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI

extension Medication {
    /// Returns the SwiftUI Color for this medication based on its color string
    var displayColor: Color {
        guard let colorString = color else {
            return Color.Theme.primary // Default to theme primary if no color set
        }

        switch colorString.lowercased() {
        case "white":
            return Color.white
        case "yellow":
            return Color.yellow
        case "pink":
            return Color.pink
        case "blue":
            return Color.blue
        case "green":
            return Color.green
        case "orange":
            return Color.orange
        case "red":
            return Color.red
        case "purple":
            return Color.purple
        case "brown":
            return Color.brown
        case "gray":
            return Color.gray
        default:
            return Color.Theme.primary
        }
    }

    /// Returns the SF Symbol icon for this medication's form
    var formIcon: String {
        let lowercasedForm = form.lowercased()

        if lowercasedForm.contains("capsule") {
            return "capsule.righthalf.filled"
        } else if lowercasedForm.contains("gummy") || lowercasedForm.contains("gummies") {
            return "button.roundedtop.horizontal.fill"
        } else if lowercasedForm.contains("tablet") || lowercasedForm.contains("pill") {
            return "pills.fill"
        } else if lowercasedForm.contains("liquid") {
            return "drop.fill"
        } else if lowercasedForm.contains("powder") {
            return "hockey.puck.fill"
        } else if lowercasedForm.contains("inhaler") {
            return "inhaler.fill"
        } else if lowercasedForm.contains("injection") {
            return "syringe.fill"
        } else if lowercasedForm.contains("cream") {
            return "homepodmini.fill"
        } else {
            return "pills.fill" // Default icon
        }
    }
}
