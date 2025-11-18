//
//  ManualMedicationEntry.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct ManualMedicationEntry: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var medication: Medication
    @State private var showingDuplicateAlert = false
    @State private var duplicateMedicationName = ""

    init() {
        // Create a new empty medication
        _medication = State(initialValue: Medication(
            brandName: "",
            genericName: "",
            dosage: "1",
            form: "Capsules",
            schedule: "",
            duration: "Ongoing",
            timesPerDay: 1,
            simplifiedInstructions: ""
        ))
    }

    var body: some View {
        AddMedicationSheet(
            medication: medication,
            onAdd: { updatedMedication in
                // Validate that required fields are filled
                guard !updatedMedication.brandName.isEmpty else {
                    return
                }

                // Check for duplicates before inserting
                if modelContext.insertMedicationIfUnique(updatedMedication) {
                    // Successfully inserted, dismiss the sheet
                    dismiss()
                } else {
                    // Duplicate found, show alert
                    duplicateMedicationName = updatedMedication.brandName
                    showingDuplicateAlert = true
                }
            },
            onCancel: {
                dismiss()
            }
        )
        .alert("Medication Already Added", isPresented: $showingDuplicateAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("'\(duplicateMedicationName)' is already in your medication list.")
        }
    }
}

#Preview {
    ManualMedicationEntry()
}
