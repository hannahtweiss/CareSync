//
//  WeekBarCalendarView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct WeekBarCalendarView: View {
    @Query(filter: #Predicate<Medication> { $0.isActive }, sort: \Medication.brandName)
    private var activeMedications: [Medication]

    @Environment(\.modelContext) private var modelContext

    @State private var selectedDate = Date()
    @State private var currentWeekOffset = 0  // Tracks which week we're viewing relative to current week
    @State private var displayMonth = Date()  // The month shown in the header
    @State private var showingMonthView = false  // Toggle between week and month views
    @State private var swipeDirection: SwipeDirection? = nil  // Track swipe animation
    @State private var selectedMedication: Medication? = nil
    @State private var selectedMedicationTime: Date? = nil
    @State private var showingActionSheet = false

    private let calendar = Calendar.current
    private let totalWeeks = 52  // Show 52 weeks worth of data (1 year)
    private let centerWeekIndex = 26  // Start in the middle

    enum SwipeDirection {
        case left, right
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week Bar at top
                VStack(spacing: 12) {
                    // Month and Year with navigation
                    HStack {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.Theme.primary)
                        }
                        .frame(width: 44, height: 44)

                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingMonthView.toggle()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(monthYearString)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)

                                    Image(systemName: showingMonthView ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color.Theme.primary)
                                }
                            }

                            // Today button
                            if !isViewingCurrentWeek {
                                Button(action: jumpToToday) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar.circle.fill")
                                            .font(.system(size: 14))
                                        Text("Today")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.Theme.primary)
                                    .cornerRadius(16)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }

                        Spacer()

                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.Theme.primary)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)

                    if !showingMonthView {
                        // Swipeable week view
                        TabView(selection: $currentWeekOffset) {
                            ForEach(-26...26, id: \.self) { weekOffset in
                                WeekView(
                                    weekOffset: weekOffset,
                                    selectedDate: $selectedDate,
                                    calendar: calendar,
                                    hasMedications: !activeMedications.isEmpty
                                )
                                .tag(weekOffset)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 110)
                        .id("weekView-\(currentWeekOffset)")
                        .onChange(of: currentWeekOffset) { oldValue, newValue in
                            updateDisplayMonth()
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                if showingMonthView {
                    // Vertical scrolling monthly calendar
                    VerticalMonthCalendarView(
                        selectedDate: $selectedDate,
                        displayMonth: $displayMonth,
                        showingMonthView: $showingMonthView,
                        currentWeekOffset: $currentWeekOffset,
                        calendar: calendar,
                        hasMedications: !activeMedications.isEmpty
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else {

                // Selected Day Medications
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                // "Today" label
                                if calendar.isDateInToday(selectedDate) {
                                    Text("Today")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }

                                // Full date
                                Text(selectedDayString)
                                    .font(.system(size: 24, weight: .bold))

                                if !activeMedications.isEmpty {
                                    Text("\(totalDosesToday) dose\(totalDosesToday == 1 ? "" : "s") today")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        if medicationsForSelectedDay.isEmpty {
                            VStack(spacing: 24) {
                                Spacer()
                                    .frame(height: 40)

                                // Illustration
                                ZStack {
                                    // Background pills
                                    Image(systemName: "pills.fill")
                                        .font(.system(size: 100))
                                        .foregroundColor(Color.Theme.primary.opacity(0.8))
                                        .rotationEffect(.degrees(15))

                                    // Plus symbols around
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color.Theme.accent)
                                        .offset(x: -60, y: -40)

                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color.yellow)
                                        .offset(x: 50, y: -50)

                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color.Theme.secondary)
                                        .offset(x: 60, y: 30)

                                    // Pill icon overlay
                                    Image(systemName: "pill.fill")
                                        .font(.system(size: 35))
                                        .foregroundColor(.yellow)
                                        .offset(x: -20, y: -30)
                                }
                                .frame(height: 180)
                                .padding(.vertical, 20)

                                VStack(spacing: 8) {
                                    Text("Here you'll see your schedule\nfor the day")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)

                                    Text("for this add a new medicine")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 32)
                        } else {
                            // Group medications by time of day
                            ForEach(groupedMedicationsByTimeOfDay, id: \.period) { group in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Time period header
                                    HStack(spacing: 8) {
                                        Image(systemName: group.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)

                                        Text(group.period)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, group.period == groupedMedicationsByTimeOfDay.first?.period ? 0 : 12)

                                    // Medications for this time period
                                    ForEach(group.items, id: \.id) { item in
                                        MedicationTimeCard(
                                            medication: item.medication,
                                            time: item.time,
                                            onTap: {
                                                selectedMedication = item.medication
                                                selectedMedicationTime = item.time
                                                showingActionSheet = true
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer()
                            .frame(height: 100)
                    }
                    .id(selectedDate)
                    .transition(.asymmetric(
                        insertion: .move(edge: swipeDirection == .left ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: swipeDirection == .left ? .leading : .trailing).combined(with: .opacity)
                    ))

                    .simultaneousGesture(
                        DragGesture(minimumDistance: 15, coordinateSpace: .local)
                            .onEnded { value in
                                let horizontalAmount = value.translation.width
                                let verticalAmount = value.translation.height
                                let horizontalVelocity = value.predictedEndLocation.x - value.location.x

                                // Fast horizontal swipe detection (velocity-based)
                                let isFastHorizontalSwipe = abs(horizontalVelocity) > 50 && abs(horizontalAmount) > 15

                                // Regular horizontal swipe (distance-based)
                                let isHorizontalSwipe = abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 30

                                if isFastHorizontalSwipe || isHorizontalSwipe {
                                    if horizontalAmount > 0 {
                                        // Swiped right - go to previous day
                                        swipeDirection = .right
                                        changeDateByDays(-1)
                                    } else {
                                        // Swiped left - go to next day
                                        swipeDirection = .left
                                        changeDateByDays(1)
                                    }
                                }
                            }
                    )
                }
                }
            }
        }
        .onAppear {
            displayMonth = selectedDate
        }
        .sheet(isPresented: $showingActionSheet) {
            if let medication = selectedMedication, let time = selectedMedicationTime {
                MedicationActionSheet(
                    medication: medication,
                    scheduledTime: time
                )
            }
        }
    }

    // MARK: - Helper Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        let displayYear = calendar.component(.year, from: displayMonth)
        let currentYear = calendar.component(.year, from: Date())

        if displayYear == currentYear {
            formatter.dateFormat = "MMMM"
        } else {
            formatter.dateFormat = "MMMM yyyy"
        }

        return formatter.string(from: displayMonth)
    }

    private var selectedDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }

    private var medicationsForSelectedDay: [(medication: Medication, times: [Date])] {
        activeMedications.map { medication in
            (medication: medication, times: medication.scheduledTimes.sorted())
        }
    }

    private var totalDosesToday: Int {
        medicationsForSelectedDay.reduce(0) { $0 + $1.times.count }
    }

    private var isViewingCurrentWeek: Bool {
        currentWeekOffset == 0
    }

    // MARK: - Time of Day Grouping

    struct MedicationTimeItem: Identifiable {
        let id = UUID()
        let medication: Medication
        let time: Date
    }

    struct TimeOfDayGroup: Identifiable {
        let id = UUID()
        let period: String
        let icon: String
        let items: [MedicationTimeItem]
    }

    private var groupedMedicationsByTimeOfDay: [TimeOfDayGroup] {
        // Flatten all medication times into individual items
        var allItems: [MedicationTimeItem] = []
        for medItem in medicationsForSelectedDay {
            for time in medItem.times {
                allItems.append(MedicationTimeItem(medication: medItem.medication, time: time))
            }
        }

        // Sort by time
        allItems.sort { $0.time < $1.time }

        // Group by time of day
        let grouped = Dictionary(grouping: allItems) { item in
            getTimeOfDay(for: item.time)
        }

        // Create TimeOfDayGroup objects and sort by time period
        let timePeriods: [(period: String, icon: String, order: Int)] = [
            ("Morning", "sunrise.fill", 0),
            ("Afternoon", "sun.max.fill", 1),
            ("Evening", "sunset.fill", 2),
            ("Night", "moon.stars.fill", 3)
        ]

        return timePeriods.compactMap { period in
            guard let items = grouped[period.period], !items.isEmpty else { return nil }
            return TimeOfDayGroup(period: period.period, icon: period.icon, items: items)
        }
    }

    private func getTimeOfDay(for date: Date) -> String {
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 5..<12:
            return "Morning"
        case 12..<17:
            return "Afternoon"
        case 17..<21:
            return "Evening"
        default:
            return "Night"
        }
    }

    // MARK: - Helper Methods

    private func changeDateByDays(_ days: Int) {
        if let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedDate = newDate
                displayMonth = newDate

                // Update week offset to match the new date
                let weeksFromNow = calendar.dateComponents([.weekOfYear], from: Date(), to: newDate).weekOfYear ?? 0
                currentWeekOffset = weeksFromNow
            }
        }
    }

    private func jumpToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentWeekOffset = 0
            selectedDate = Date()
            displayMonth = Date()
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayMonth) {
            displayMonth = newMonth

            // Move to the first week of the new month
            if let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newMonth)),
               let firstWeekStart = calendar.dateInterval(of: .weekOfMonth, for: firstDayOfMonth)?.start {

                let weeksFromNow = calendar.dateComponents([.weekOfYear], from: Date(), to: firstWeekStart).weekOfYear ?? 0
                currentWeekOffset = weeksFromNow

                // Select the first day of the month
                selectedDate = firstDayOfMonth
            }
        }
    }

    private func updateDisplayMonth() {
        // Update the displayed month based on the current week offset
        if let newDate = calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: Date()) {
            displayMonth = newDate
        }
    }
}

// MARK: - Week View

struct WeekView: View {
    let weekOffset: Int
    @Binding var selectedDate: Date
    let calendar: Calendar
    let hasMedications: Bool

    private var daysInWeek: [Date] {
        let today = Date()
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today) else {
            return []
        }

        let weekStartDate = calendar.startOfWeek(for: weekStart)
        var days: [Date] = []

        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) {
                days.append(date)
            }
        }

        return days
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(daysInWeek, id: \.self) { date in
                WeekDayCell(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date),
                    hasMedications: hasMedications
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Week Day Cell

struct WeekDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasMedications: Bool
    let action: () -> Void

    private let calendar = Calendar.current

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(dayOfWeek)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)

                Text(dayNumber)
                    .font(.system(size: 22, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .white : (isToday ? Color.Theme.primary : .primary))

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
            .frame(width: 70, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.Theme.primary : (isToday ? Color.Theme.primary.opacity(0.1) : Color(.systemGray6)))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vertical Month Calendar View

struct VerticalMonthCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var displayMonth: Date
    @Binding var showingMonthView: Bool
    @Binding var currentWeekOffset: Int
    let calendar: Calendar
    let hasMedications: Bool

    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    // Generate months from 6 months ago to 6 months ahead relative to selected date
    private var monthsToDisplay: [Date] {
        var months: [Date] = []

        for offset in -6...6 {
            if let month = calendar.date(byAdding: .month, value: offset, to: selectedDate) {
                months.append(month)
            }
        }

        return months
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 32) {
                    ForEach(monthsToDisplay, id: \.self) { month in
                        MonthGridView(
                            month: month,
                            selectedDate: $selectedDate,
                            showingMonthView: $showingMonthView,
                            currentWeekOffset: $currentWeekOffset,
                            displayMonth: $displayMonth,
                            calendar: calendar,
                            hasMedications: hasMedications
                        )
                        .id(month)
                    }
                }
                .padding()
            }
            .onAppear {
                // Scroll to the month containing the currently selected date
                if let monthToShow = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        proxy.scrollTo(monthToShow, anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - Month Grid View

struct MonthGridView: View {
    let month: Date
    @Binding var selectedDate: Date
    @Binding var showingMonthView: Bool
    @Binding var currentWeekOffset: Int
    @Binding var displayMonth: Date
    let calendar: Calendar
    let hasMedications: Bool

    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
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

    var body: some View {
        VStack(spacing: 12) {
            // Month header
            Text(monthYearString)
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(daysInMonth.indices, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        MonthDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasMedications: hasMedications
                        ) {
                            // Update selected date
                            selectedDate = date

                            // Update display month to match selected date
                            displayMonth = date

                            // Calculate the week offset for the selected date
                            let weeksFromNow = calendar.dateComponents([.weekOfYear], from: Date(), to: date).weekOfYear ?? 0

                            // Update week offset immediately so TabView can respond
                            currentWeekOffset = weeksFromNow

                            // Close month view with animation
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingMonthView = false
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }
}

// MARK: - Month Day Cell

struct MonthDayCell: View {
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
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : isToday ? Color.Theme.primary : .primary)

                if hasMedications {
                    Circle()
                        .fill(isSelected ? Color.white : Color.Theme.primary)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.Theme.primary : (isToday ? Color.Theme.primary.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Medication.self, configurations: config)

    // Add sample medications with scheduled times
    let calendar = Calendar.current
    let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    let noonTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
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
        timesPerDay: 3,
        simplifiedInstructions: "Take 1 capsule three times daily",
        scheduledTimes: [morningTime, noonTime, eveningTime]
    )

    container.mainContext.insert(medication1)
    container.mainContext.insert(medication2)

    return WeekBarCalendarView()
        .modelContainer(container)
}
