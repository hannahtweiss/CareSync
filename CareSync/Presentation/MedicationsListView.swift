//
//  MedicationsListView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct MedicationsListView: View {
    @Query(sort: \Medication.brandName) private var allMedications: [Medication]
    @State private var selectedMedication: Medication?
    @State private var showingDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                if allMedications.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "pills.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)

                        Text("No Medications")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Add medications from the Calendar tab")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(allMedications, id: \.upcCode) { medication in
                            Button(action: {
                                selectedMedication = medication
                                showingDetail = true
                            }) {
                                HStack(alignment: .top, spacing: 12) {
                                    // Status indicator
                                    Circle()
                                        .fill(medication.isActive ? Color.green : Color.gray)
                                        .frame(width: 12, height: 12)
                                        .padding(.top, 6)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(medication.brandName)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)

                                        Text(medication.genericName)
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)

                                        Text(medication.dosage)
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)

                                        HStack {
                                            Text(medication.isActive ? "Active" : "Inactive")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(medication.isActive ? .green : .gray)

                                            if medication.timesPerDay > 1 {
                                                Text("•")
                                                    .foregroundColor(.secondary)
                                                Text("\(medication.timesPerDay)x/day")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("All Medications")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingDetail) {
                if let medication = selectedMedication {
                    MedicationDetailView(medication: medication)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Medication.self, configurations: config)

    // Add sample medications
    let medication1 = Medication(
        brandName: "Aspirin",
        genericName: "Acetylsalicylic Acid",
        dosage: "Take 1 tablet daily",
        form: "Tablets",
        schedule: "Daily",
        duration: "Ongoing",
        upcCode: "123456789",
        timesPerDay: 1,
        simplifiedInstructions: "Take 1 tablet each day",
        isActive: true
    )

    let medication2 = Medication(
        brandName: "Vitamin D",
        genericName: "Cholecalciferol",
        dosage: "Take 1 capsule daily",
        form: "Capsules",
        schedule: "Daily",
        duration: "Ongoing",
        upcCode: "987654321",
        timesPerDay: 2,
        simplifiedInstructions: "Take 1 capsule each day",
        isActive: false
    )

    container.mainContext.insert(medication1)
    container.mainContext.insert(medication2)

    return MedicationsListView()
        .modelContainer(container)
}
