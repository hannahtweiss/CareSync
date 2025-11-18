//
//  ModelContextExtensions.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftData
import Foundation

extension ModelContext {
    /// Checks if a medication with the same brand name or UPC code already exists
    /// Returns the existing medication if found, nil otherwise
    func findExistingMedication(brandName: String, upcCode: String?) -> Medication? {
        let descriptor = FetchDescriptor<Medication>()

        guard let allMedications = try? fetch(descriptor) else {
            return nil
        }

        // Check for duplicate by brand name (case-insensitive)
        let nameMatch = allMedications.first { medication in
            medication.brandName.lowercased() == brandName.lowercased()
        }

        if nameMatch != nil {
            return nameMatch
        }

        // Check for duplicate by UPC code if provided
        if let upcCode = upcCode, !upcCode.isEmpty {
            let upcMatch = allMedications.first { medication in
                medication.upcCode == upcCode
            }
            return upcMatch
        }

        return nil
    }

    /// Inserts a medication only if it doesn't already exist
    /// Returns true if inserted, false if duplicate was found
    @discardableResult
    func insertMedicationIfUnique(_ medication: Medication) -> Bool {
        // Check for existing medication
        if let _ = findExistingMedication(
            brandName: medication.brandName,
            upcCode: medication.upcCode
        ) {
            return false // Duplicate found
        }

        // No duplicate found, insert the medication
        insert(medication)
        return true
    }
}
