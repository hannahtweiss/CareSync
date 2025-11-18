//
//  MedicationActionSheet.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct MedicationActionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let medication: Medication
    let scheduledTime: Date

    @State private var showingReschedule = false
    @State private var showingEditSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top toolbar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Button(action: deleteMedication) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }

                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)

                // Medication icon
                ZStack {
                    Circle()
                        .fill(medication.displayColor.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: medication.formIcon)
                        .font(.system(size: 40))
                        .foregroundColor(medication.displayColor)
                }
                .padding(.bottom, 24)

                // Medication name
                Text(medication.brandName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 32)

                // Schedule info
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(width: 24)

                        Text("Scheduled for \(formatTime(scheduledTime)), \(formatDate(scheduledTime))")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "pills")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(width: 24)

                        Text("\(medication.dosage), take 1 pill(s) with food")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)

                Spacer()

                // Action buttons
                HStack(spacing: 32) {
                    // Skip button
                    VStack(spacing: 8) {
                        Button(action: skipMedication) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 64, height: 64)

                                Image(systemName: "xmark")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.Theme.secondary)
                    }

                    // Take button (primary action)
                    VStack(spacing: 8) {
                        Button(action: takeMedication) {
                            ZStack {
                                Circle()
                                    .fill(Color.Theme.secondary)
                                    .frame(width: 64, height: 64)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text("Take")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.Theme.secondary)
                    }

                    // Reschedule button
                    VStack(spacing: 8) {
                        Button(action: { showingReschedule = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 64, height: 64)

                                Image(systemName: "clock")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("Reschedule")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.Theme.secondary)
                    }
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingReschedule) {
            RescheduleSheet(medication: medication, originalTime: scheduledTime) {
                dismiss()
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddMedicationSheet(
                medication: medication,
                onAdd: { _ in
                    try? modelContext.save()
                    showingEditSheet = false
                },
                onCancel: {
                    showingEditSheet = false
                }
            )
        }
    }

    // MARK: - Helper Methods

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        }
    }

    private func skipMedication() {
        // TODO: Add logic to track skipped medications
        dismiss()
    }

    private func takeMedication() {
        // TODO: Add logic to mark medication as taken
        dismiss()
    }

    private func deleteMedication() {
        modelContext.delete(medication)
        dismiss()
    }
}

// MARK: - Reschedule Sheet

struct RescheduleSheet: View {
    @Environment(\.dismiss) private var dismiss

    let medication: Medication
    let originalTime: Date
    let onComplete: () -> Void

    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var showingConfirmation = false

    enum RescheduleScope {
        case justThisTime
        case allTimes
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                Text("Reschedule Medication")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 32)

                Text("When would you like to take \(medication.brandName)?")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Date picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Date")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(Color.Theme.primary)
                }
                .padding(.horizontal, 24)

                // Time picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
                .padding(.horizontal, 24)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    Button(action: { showingConfirmation = true }) {
                        Text("Save")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.Theme.primary)
                            .cornerRadius(14)
                    }

                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .confirmationDialog("Apply changes to", isPresented: $showingConfirmation, titleVisibility: .visible) {
                Button("Just this time") {
                    rescheduleMedication(scope: .justThisTime)
                }

                Button("All future medications") {
                    rescheduleMedication(scope: .allTimes)
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Would you like to reschedule just this dose or all future doses of \(medication.brandName)?")
            }
        }
    }

    private func rescheduleMedication(scope: RescheduleScope) {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        if scope == .justThisTime {
            // Reschedule just this one occurrence
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)

            var newDateComponents = DateComponents()
            newDateComponents.year = dateComponents.year
            newDateComponents.month = dateComponents.month
            newDateComponents.day = dateComponents.day
            newDateComponents.hour = timeComponents.hour
            newDateComponents.minute = timeComponents.minute

            if let newTime = calendar.date(from: newDateComponents) {
                // Update just this specific scheduled time
                if let index = medication.scheduledTimes.firstIndex(of: originalTime) {
                    medication.scheduledTimes[index] = newTime
                }
            }
        } else {
            // Reschedule all occurrences (all daily doses)
            // Update all scheduled times to the new time of day
            medication.scheduledTimes = medication.scheduledTimes.map { oldTime in
                var components = calendar.dateComponents([.year, .month, .day], from: oldTime)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                return calendar.date(from: components) ?? oldTime
            }
        }

        dismiss()
        onComplete()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Medication.self, configurations: config)

    let sampleMedication = Medication(
        brandName: "Tylenol",
        genericName: "Acetaminophen",
        dosage: "325 mg",
        form: "Tablets",
        schedule: "Take 1 pill with food",
        duration: "As needed",
        timesPerDay: 1,
        simplifiedInstructions: "Take 1 pill with food",
        color: "Red"
    )

    return MedicationActionSheet(
        medication: sampleMedication,
        scheduledTime: Date()
    )
    .modelContainer(container)
}
