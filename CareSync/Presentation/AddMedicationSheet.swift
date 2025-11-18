//
//  AddMedicationSheet.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI

struct AddMedicationSheet: View {
    let medication: Medication
    let onAdd: (Medication) -> Void
    let onCancel: () -> Void

    @State private var selectedForm: MedicationForm = .capsule
    @State private var medicationName: String = ""
    @State private var dosage: Int = 1
    @State private var frequency: FrequencyType = .everyday
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7] // 1=Sunday, 7=Saturday
    @State private var notificationsEnabled: Bool = true
    @State private var duration: String = "Ongoing"
    @State private var timesPerDay: Int = 1
    @State private var notificationTimes: [Date] = []
    @State private var selectedColor: MedicationColor = .white

    enum MedicationForm: String, CaseIterable {
        case pill = "Pills"
        case capsule = "Capsules"
        case gummy = "Gummies"
        case liquid = "Liquid"
        case powder = "Powder"
        case inhaler = "Inhaler"
        case injection = "Injection"
        case cream = "Cream"

        var icon: String {
            switch self {
            case .pill: return "pills.fill"
            case .capsule: return "capsule.righthalf.filled"
            case .gummy: return "button.roundedtop.horizontal.fill"
            case .liquid: return "drop.fill"
            case .powder: return "hockey.puck.fill"
            case .inhaler: return "inhaler.fill"
            case .injection: return "syringe.fill"
            case .cream: return "homepodmini.fill"
            }
        }
    }

    enum FrequencyType: String, CaseIterable {
        case everyday = "Everyday"
        case specificDays = "Specific Days"
        case asNeeded = "As Needed"
    }

    enum MedicationColor: String, CaseIterable {
        case white = "White"
        case yellow = "Yellow"
        case pink = "Pink"
        case blue = "Blue"
        case green = "Green"
        case orange = "Orange"
        case red = "Red"
        case purple = "Purple"
        case brown = "Brown"
        case gray = "Gray"

        var colorValue: Color {
            switch self {
            case .white: return Color.white
            case .yellow: return Color.yellow
            case .pink: return Color.pink
            case .blue: return Color.blue
            case .green: return Color.green
            case .orange: return Color.orange
            case .red: return Color.red
            case .purple: return Color.purple
            case .brown: return Color.brown
            case .gray: return Color.gray
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Medication Form Selector
                    VStack(spacing: 16) {
                        Text(selectedForm.rawValue)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        // Form Icon Display
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.3))
                                .frame(width: 120, height: 120)

                            Image(systemName: selectedForm.icon)
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 20)

                        // Form Type Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(MedicationForm.allCases, id: \.self) { form in
                                FormTypeButton(
                                    form: form,
                                    isSelected: selectedForm == form,
                                    action: { selectedForm = form }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    // Pills Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pills name")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundColor(.gray)
                            TextField("Medication name", text: $medicationName)
                                .font(.system(size: 18))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Dosage
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dosage")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack {
                            Button(action: {
                                if dosage > 1 { dosage -= 1 }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text("\(dosage)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(minWidth: 60)

                            Spacer()

                            Button(action: {
                                dosage += 1
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Frequency
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequency")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        Picker("Frequency", selection: $frequency) {
                            ForEach(FrequencyType.allCases, id: \.self) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    // Days of Week (if specific days selected)
                    if frequency == .specificDays || frequency == .everyday {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Days")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            HStack(spacing: 12) {
                                ForEach(1...7, id: \.self) { day in
                                    DayButton(
                                        dayName: dayName(for: day),
                                        isSelected: frequency == .everyday || selectedDays.contains(day),
                                        isDisabled: frequency == .everyday,
                                        action: {
                                            if frequency == .specificDays {
                                                if selectedDays.contains(day) {
                                                    selectedDays.remove(day)
                                                } else {
                                                    selectedDays.insert(day)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Times Per Day
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Times per day")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            ForEach(1...4, id: \.self) { times in
                                Button(action: {
                                    timesPerDay = times
                                }) {
                                    Text("\(times)")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(timesPerDay == times ? .black : .gray)
                                        .frame(width: 60, height: 60)
                                        .background(timesPerDay == times ? Color.yellow : Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Colors Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Colors")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(MedicationColor.allCases, id: \.self) { color in
                                ColorButton(
                                    color: color,
                                    isSelected: selectedColor == color,
                                    action: { selectedColor = color }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Notification Toggle
                    HStack {
                        Text("Notification")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        Toggle("", isOn: $notificationsEnabled)
                            .labelsHidden()
                            .tint(.green)
                            .scaleEffect(1.2)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // Notification Times (shown when notifications enabled)
                    if notificationsEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "alarm.fill")
                                    .foregroundColor(.yellow)
                                Text("Alarm Times")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal)

                            VStack(spacing: 12) {
                                ForEach(0..<timesPerDay, id: \.self) { index in
                                    HStack {
                                        Text("Time \(index + 1)")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .frame(width: 70, alignment: .leading)

                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: {
                                                    if index < notificationTimes.count {
                                                        return notificationTimes[index]
                                                    }
                                                    return Date()
                                                },
                                                set: { newValue in
                                                    if index < notificationTimes.count {
                                                        notificationTimes[index] = newValue
                                                    }
                                                }
                                            ),
                                            displayedComponents: .hourAndMinute
                                        )
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .transition(.opacity)
                    }

                    Spacer(minLength: 40)

                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            saveMedication()
                        }) {
                            Text("Add Medication")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.blue)
                                .cornerRadius(16)
                        }

                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Add Pills")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Initialize with scanned medication data
            medicationName = medication.brandName
            selectedForm = mapFormType(medication.form)
            if let dosageNum = extractDosageNumber(from: medication.dosage) {
                dosage = dosageNum
            }
            timesPerDay = medication.timesPerDay

            // Initialize notification times
            if medication.scheduledTimes.isEmpty {
                notificationTimes = generateDefaultNotificationTimes(count: timesPerDay)
            } else {
                notificationTimes = medication.scheduledTimes
            }
        }
        .onChange(of: timesPerDay) { oldValue, newValue in
            // Update notification times when times per day changes
            if notificationTimes.count < newValue {
                // Add more times
                while notificationTimes.count < newValue {
                    let lastTime = notificationTimes.last ?? Date()
                    let newTime = Calendar.current.date(byAdding: .hour, value: 4, to: lastTime) ?? Date()
                    notificationTimes.append(newTime)
                }
            } else if notificationTimes.count > newValue {
                // Remove excess times
                notificationTimes = Array(notificationTimes.prefix(newValue))
            }
        }
    }

    // MARK: - Helper Methods

    private func saveMedication() {
        // Update medication with user inputs
        medication.brandName = medicationName
        medication.form = selectedForm.rawValue
        medication.dosage = "\(dosage)"
        medication.timesPerDay = timesPerDay
        medication.isActive = notificationsEnabled
        medication.duration = duration
        medication.color = selectedColor.rawValue

        // Save notification times
        if notificationsEnabled {
            medication.scheduledTimes = notificationTimes
        } else {
            medication.scheduledTimes = []
        }

        // Generate schedule based on frequency and days
        if frequency == .everyday {
            medication.schedule = "Take \(dosage) \(selectedForm.rawValue.lowercased()) \(timesPerDay) time\(timesPerDay > 1 ? "s" : "") daily"
        } else if frequency == .specificDays {
            let dayNames = selectedDays.sorted().map { dayName(for: $0) }.joined(separator: ", ")
            medication.schedule = "Take \(dosage) \(selectedForm.rawValue.lowercased()) \(timesPerDay) time\(timesPerDay > 1 ? "s" : "") on \(dayNames)"
        } else {
            medication.schedule = "Take \(dosage) \(selectedForm.rawValue.lowercased()) as needed"
        }

        medication.simplifiedInstructions = medication.schedule

        onAdd(medication)
    }

    private func mapFormType(_ form: String) -> MedicationForm {
        let lowercased = form.lowercased()
        if lowercased.contains("capsule") { return .capsule }
        if lowercased.contains("gummy") || lowercased.contains("gummies") { return .gummy }
        if lowercased.contains("tablet") { return .pill }
        if lowercased.contains("pill") { return .pill }
        if lowercased.contains("liquid") { return .liquid }
        if lowercased.contains("powder") { return .powder }
        if lowercased.contains("inhaler") { return .inhaler }
        if lowercased.contains("injection") { return .injection }
        if lowercased.contains("cream") { return .cream }
        return .capsule
    }

    private func extractDosageNumber(from dosage: String) -> Int? {
        let components = dosage.components(separatedBy: CharacterSet.decimalDigits.inverted)
        for component in components {
            if let number = Int(component) {
                return number
            }
        }
        return nil
    }

    private func dayName(for day: Int) -> String {
        switch day {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return ""
        }
    }

    private func generateDefaultNotificationTimes(count: Int) -> [Date] {
        let calendar = Calendar.current
        var times: [Date] = []

        switch count {
        case 1:
            // Once daily at 9:00 AM
            times.append(calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
        case 2:
            // Twice daily at 9:00 AM and 9:00 PM
            times.append(calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date())
        case 3:
            // Three times daily at 8:00 AM, 2:00 PM, 8:00 PM
            times.append(calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date())
        case 4:
            // Four times daily at 8:00 AM, 12:00 PM, 4:00 PM, 8:00 PM
            times.append(calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date())
            times.append(calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date())
        default:
            // For more than 4 times, space them evenly throughout the day
            let hoursApart = 24 / max(count, 1)
            for i in 0..<count {
                let hour = 8 + (i * hoursApart)
                times.append(calendar.date(bySettingHour: hour % 24, minute: 0, second: 0, of: Date()) ?? Date())
            }
        }

        return times
    }
}

// MARK: - Form Type Button
struct FormTypeButton: View {
    let form: AddMedicationSheet.MedicationForm
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: form.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .gray)
                    .frame(width: 60, height: 60)
                    .background(isSelected ? Color.yellow : Color(.systemGray6))
                    .cornerRadius(12)

                Text(form.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
    }
}

// MARK: - Day Button
struct DayButton: View {
    let dayName: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(dayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .gray)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(red: 0.2, green: 0.3, blue: 0.3) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - Color Button
struct ColorButton: View {
    let color: AddMedicationSheet.MedicationColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.colorValue)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(color == .white ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                    )

                if isSelected {
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 56, height: 56)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white).frame(width: 18, height: 18))
                        .offset(x: 18, y: -18)
                }
            }
        }
    }
}

#Preview {
    AddMedicationSheet(
        medication: Medication(
            brandName: "Loratadine",
            genericName: "Loratadine",
            dosage: "10mg",
            form: "Capsules",
            schedule: "Take 1 daily",
            duration: "Ongoing",
            timesPerDay: 1,
            simplifiedInstructions: "Take 1 capsule daily"
        ),
        onAdd: { _ in },
        onCancel: {}
    )
}
