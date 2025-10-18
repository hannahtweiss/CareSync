//
//  MedicationDetailSheet.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI

struct MedicationDetailSheet: View {
    let medication: Medication
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            // Header
            Text("New Medication")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 20)

            Spacer()

            // Medication Name
            VStack(spacing: 12) {
                Text(medication.brandName)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if !medication.genericName.isEmpty && medication.genericName != medication.brandName {
                    Text(medication.genericName)
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)

            // Dosage Instructions
            VStack(spacing: 8) {
                Text("How to take:")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.secondary)

                Text(medication.simplifiedInstructions)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()

            // Action Buttons
            VStack(spacing: 16) {
                // Add Button
                Button(action: onAdd) {
                    Text("Add to My Medications")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.blue)
                        .cornerRadius(16)
                }

                // Cancel Button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    MedicationDetailSheet(
        medication: Medication(
            brandName: "Aspirin",
            genericName: "Acetylsalicylic Acid",
            dosage: "Take 1 tablet daily",
            form: "Tablets",
            schedule: "Daily",
            duration: "Ongoing",
            upcCode: "123456789",
            simplifiedInstructions: "Take 1 tablet each day"
        ),
        onAdd: {},
        onCancel: {}
    )
}
