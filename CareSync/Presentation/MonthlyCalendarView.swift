//
//  MonthlyCalendarView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct MonthlyCalendarView: View {
    @Query(filter: #Predicate<Medication> { $0.isActive }, sort: \Medication.brandName)
    private var activeMedications: [Medication]

    @State private var selectedDate = Date()
    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month Header with Navigation
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding()
                    }

                    Spacer()

                    Text(monthYearString)
                        .font(.system(size: 24, weight: .bold))

                    Spacer()

                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Days of Week Header
                HStack(spacing: 0) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)

                // Calendar Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date),
                                hasMedications: hasActiveMedications(on: date)
                            ) {
                                selectedDate = date
                            }
                        } else {
                            Color.clear
                                .frame(height: 50)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)

                Divider()

                // Selected Day Medications
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(selectedDayString)
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal)
                            .padding(.top, 16)

                        if medicationsForSelectedDay.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "pills.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)

                                Text("No medications scheduled")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(medicationsForSelectedDay, id: \.medication.upcCode) { item in
                                MedicationTimeCard(
                                    medication: item.medication,
                                    times: item.times
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Helper Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var selectedDayString: String {
        let formatter = DateFormatter()
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: selectedDate)
        }
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        let monthLastDay = calendar.date(byAdding: DateComponents(day: -1), to: monthInterval.end)!
        guard let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthLastDay) else {
            return []
        }

        var dates: [Date?] = []
        var currentDate = monthFirstWeek.start

        while currentDate <= monthLastWeek.end {
            if calendar.isDate(currentDate, equalTo: monthInterval.start, toGranularity: .month) {
                dates.append(currentDate)
            } else {
                dates.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }

    private var medicationsForSelectedDay: [(medication: Medication, times: [Date])] {
        activeMedications.map { medication in
            (medication: medication, times: medication.scheduledTimes.sorted())
        }
    }

    // MARK: - Helper Methods

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func hasActiveMedications(on date: Date) -> Bool {
        !activeMedications.isEmpty
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasMedications: Bool
    let action: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : isToday ? .blue : .primary)

                if hasMedications {
                    Circle()
                        .fill(isSelected ? Color.white : Color.blue)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Medication Time Card

struct MedicationTimeCard: View {
    let medication: Medication
    let times: [Date]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.brandName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text(medication.dosage)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Scheduled times
            VStack(alignment: .leading, spacing: 8) {
                ForEach(times, id: \.self) { time in
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)

                        Text(formatTime(time))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()

                        // Checkmark button (placeholder for future functionality)
                        Image(systemName: "circle")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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

    // Add sample medications with scheduled times
    let calendar = Calendar.current
    let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    let eveningTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!

    let medication1 = Medication(
        brandName: "Aspirin",
        genericName: "Acetylsalicylic Acid",
        dosage: "Take 1 tablet daily",
        form: "Tablets",
        schedule: "Daily",
        duration: "Ongoing",
        upcCode: "123456789",
        timesPerDay: 2,
        simplifiedInstructions: "Take 1 tablet twice daily",
        scheduledTimes: [morningTime, eveningTime]
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
        simplifiedInstructions: "Take 1 capsule each morning",
        scheduledTimes: [morningTime]
    )

    container.mainContext.insert(medication1)
    container.mainContext.insert(medication2)

    return MonthlyCalendarView()
        .modelContainer(container)
}
