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
                            .foregroundColor(Color.Theme.primary)
                            .padding()
                    }

                    Spacer()

                    Text(monthYearString)
                        .font(.system(size: 24, weight: .bold))

                    Spacer()

                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.Theme.primary)
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
                            // Flatten medication times into individual cards
                            ForEach(flattenedMedicationTimes) { timeItem in
                                MedicationTimeCard(
                                    medication: timeItem.medication,
                                    time: timeItem.time
                                )
                                .padding(.horizontal)
                            }
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

    struct MedicationTimeItem: Identifiable {
        let id = UUID()
        let medication: Medication
        let time: Date
    }

    private var flattenedMedicationTimes: [MedicationTimeItem] {
        var items: [MedicationTimeItem] = []
        for medItem in medicationsForSelectedDay {
            for time in medItem.times {
                items.append(MedicationTimeItem(medication: medItem.medication, time: time))
            }
        }
        return items.sorted { $0.time < $1.time }
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
                    .foregroundColor(isSelected ? .white : isToday ? Color.Theme.primary : .primary)

                if hasMedications {
                    Circle()
                        .fill(isSelected ? Color.white : Color.Theme.primary)
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
                    .fill(isSelected ? Color.Theme.primary : (isToday ? Color.Theme.primary.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Medication Time Card

struct MedicationTimeCard: View {
    let medication: Medication
    let time: Date
    @State private var isTaken: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 14) {
                // Medication icon with checkmark
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(medication.displayColor.opacity(0.2))
                            .frame(width: 52, height: 52)

                        Image(systemName: medication.formIcon)
                            .font(.system(size: 26))
                            .foregroundColor(medication.displayColor)
                    }

                    // Checkmark indicator
                    if isTaken {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 4, y: 4)
                    }
                }

                // Medication info
                VStack(alignment: .leading, spacing: 3) {
                    Text(medication.brandName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(medication.dosage)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Time
                Text(formatTime(time))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isTaken.toggle()
            }
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
