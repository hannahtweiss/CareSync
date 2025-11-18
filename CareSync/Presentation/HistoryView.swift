//
//  HistoryView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Medication.timestamp, order: .reverse) private var medications: [Medication]

    var body: some View {
        NavigationStack {
            ZStack {
                if medications.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)

                        Text("No History Yet")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Your medication history will appear here")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(groupedByDate, id: \.key) { dateGroup in
                            Section(header: Text(dateGroup.key)) {
                                ForEach(dateGroup.value, id: \.upcCode) { medication in
                                    HStack(spacing: 12) {
                                        Image(systemName: "pills.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(medication.isActive ? .blue : .gray)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(medication.brandName)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.primary)

                                            Text(medication.simplifiedInstructions)
                                                .font(.system(size: 16))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Text(formatTime(medication.timestamp))
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // Group medications by date
    private var groupedByDate: [(key: String, value: [Medication])] {
        let grouped = Dictionary(grouping: medications) { medication in
            formatDate(medication.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Medication.self, configurations: config)

    // Add sample medications with different timestamps
    let now = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!

    let medication1 = Medication(
        brandName: "Aspirin",
        genericName: "Acetylsalicylic Acid",
        dosage: "Take 1 tablet daily",
        form: "Tablets",
        schedule: "Daily",
        duration: "Ongoing",
        upcCode: "123456789",
        timestamp: now,
        timesPerDay: 1,
        simplifiedInstructions: "Take 1 tablet each day"
    )

    let medication2 = Medication(
        brandName: "Vitamin D",
        genericName: "Cholecalciferol",
        dosage: "Take 1 capsule daily",
        form: "Capsules",
        schedule: "Daily",
        duration: "Ongoing",
        upcCode: "987654321",
        timestamp: yesterday,
        timesPerDay: 1,
        simplifiedInstructions: "Take 1 capsule each day"
    )

    let medication3 = Medication(
        brandName: "Ibuprofen",
        genericName: "Ibuprofen",
        dosage: "Take 2 tablets as needed",
        form: "Tablets",
        schedule: "As needed",
        duration: "Ongoing",
        upcCode: "111222333",
        timestamp: lastWeek,
        timesPerDay: 1,
        simplifiedInstructions: "Take 2 tablets as needed"
    )

    container.mainContext.insert(medication1)
    container.mainContext.insert(medication2)
    container.mainContext.insert(medication3)

    return HistoryView()
        .modelContainer(container)
}
