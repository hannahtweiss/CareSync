//
//  MedicationDetailView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct MedicationDetailView: View {
    let medication: Medication
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Medication Name
                    VStack(spacing: 12) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text(medication.brandName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        if !medication.genericName.isEmpty && medication.genericName != medication.brandName {
                            Text(medication.genericName)
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Status badge
                        HStack {
                            Circle()
                                .fill(medication.isActive ? Color.green : Color.gray)
                                .frame(width: 12, height: 12)
                            Text(medication.isActive ? "Active" : "Inactive")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(medication.isActive ? .green : .gray)
                        }
                    }
                    .padding()

                    // Details Section
                    VStack(spacing: 16) {
                        DetailRow(title: "Form", value: medication.form)
                        DetailRow(title: "Dosage", value: medication.dosage)
                        DetailRow(title: "Schedule", value: medication.schedule)
                        DetailRow(title: "Duration", value: medication.duration)

                        if medication.timesPerDay > 1 {
                            DetailRow(title: "Times Per Day", value: "\(medication.timesPerDay)")
                        }

                        if !medication.simplifiedInstructions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Instructions")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.secondary)

                                Text(medication.simplifiedInstructions)
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }

                        if let productDescription = medication.productDescription, !productDescription.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.secondary)

                                Text(productDescription)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }

                        // Codes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Product Codes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("UPC: \(medication.upcCode)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)

                                if let ndcCode = medication.ndcCode {
                                    Text("NDC: \(ndcCode)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    // Toggle Active Status Button
                    Button(action: {
                        medication.isActive.toggle()
                        try? modelContext.save()
                    }) {
                        Text(medication.isActive ? "Mark as Inactive" : "Mark as Active")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(medication.isActive ? .red : .green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Medication Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Medication.self, configurations: config)

    let medication = Medication(
        brandName: "Aspirin",
        genericName: "Acetylsalicylic Acid",
        dosage: "Take 1 tablet daily",
        form: "Tablets",
        schedule: "Daily",
        duration: "Ongoing",
        upcCode: "123456789",
        ndcCode: "12345-678-90",
        productDescription: "Pain reliever and fever reducer",
        timesPerDay: 2,
        simplifiedInstructions: "Take 1 tablet each day with food",
        isActive: true
    )

    container.mainContext.insert(medication)

    return MedicationDetailView(medication: medication)
        .modelContainer(container)
}
