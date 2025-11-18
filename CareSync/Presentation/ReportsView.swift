//
//  ReportsView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct ReportsView: View {
    @Query private var allMedications: [Medication]

    var body: some View {
        NavigationStack {
            ZStack {
                if allMedications.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)

                        Text("No Reports Available")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Add medications to see reports and insights")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Summary Cards
                            SummaryCard(
                                title: "Total Medications",
                                value: "\(allMedications.count)",
                                icon: "pills.fill",
                                color: .blue
                            )

                            SummaryCard(
                                title: "Active Medications",
                                value: "\(activeMedicationsCount)",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )

                            SummaryCard(
                                title: "Daily Doses",
                                value: "\(totalDailyDoses)",
                                icon: "calendar.circle.fill",
                                color: .orange
                            )

                            // Medications by Form
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Medications by Form")
                                    .font(.system(size: 24, weight: .bold))
                                    .padding(.horizontal)

                                ForEach(medicationsByForm, id: \.key) { form in
                                    HStack {
                                        Text(form.key)
                                            .font(.system(size: 18))
                                            .foregroundColor(.primary)

                                        Spacer()

                                        Text("\(form.value)")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var activeMedicationsCount: Int {
        allMedications.filter { $0.isActive }.count
    }

    private var totalDailyDoses: Int {
        allMedications.filter { $0.isActive }.reduce(0) { $0 + $1.timesPerDay }
    }

    private var medicationsByForm: [(key: String, value: Int)] {
        let grouped = Dictionary(grouping: allMedications) { $0.form }
        let counts = grouped.mapValues { $0.count }
        return counts.sorted { $0.value > $1.value }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
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
        timesPerDay: 2,
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
        timesPerDay: 1,
        simplifiedInstructions: "Take 1 capsule each day",
        isActive: true
    )

    let medication3 = Medication(
        brandName: "Ibuprofen",
        genericName: "Ibuprofen",
        dosage: "Take 2 tablets as needed",
        form: "Tablets",
        schedule: "As needed",
        duration: "Ongoing",
        upcCode: "111222333",
        timesPerDay: 1,
        simplifiedInstructions: "Take 2 tablets as needed",
        isActive: false
    )

    container.mainContext.insert(medication1)
    container.mainContext.insert(medication2)
    container.mainContext.insert(medication3)

    return ReportsView()
        .modelContainer(container)
}
