//
//  WeeklyCalendarView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct WeeklyCalendarView: View {
    @Query(filter: #Predicate<Medication> { $0.isActive }, sort: \Medication.brandName)
    private var activeMedications: [Medication]

    @State private var expandedDay: Int? = nil

    private let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        NavigationStack {
            ZStack {
                if activeMedications.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "pills.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)

                        Text("No Medications Yet")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Tap the + button to scan and add your first medication")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // Weekly calendar with day cubbies
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                                DayCubbyView(
                                    dayName: day,
                                    medications: activeMedications,
                                    isExpanded: expandedDay == index
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        expandedDay = expandedDay == index ? nil : index
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Medications")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct DayCubbyView: View {
    let dayName: String
    let medications: [Medication]
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cubby header (the "lid")
            Button(action: onTap) {
                HStack {
                    // Day name
                    Text(dayName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    // Medication count badge
                    Text("\(medications.count)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 36, minHeight: 36)
                        .background(Color.Theme.primary)
                        .clipShape(Circle())

                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.Theme.primary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12, corners: isExpanded ? [.topLeft, .topRight] : .allCorners)
            }
            .buttonStyle(PlainButtonStyle())

            // Cubby content (medications)
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(medications, id: \.upcCode) { medication in
                        MedicationRowView(medication: medication)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 2)
                )
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MedicationRowView: View {
    let medication: Medication

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Medication icon with color
            ZStack {
                Circle()
                    .fill(medication.displayColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: medication.formIcon)
                    .font(.system(size: 24))
                    .foregroundColor(medication.displayColor)
            }

            // Medication info
            VStack(alignment: .leading, spacing: 6) {
                Text(medication.brandName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text(medication.simplifiedInstructions)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)

                if medication.timesPerDay > 1 {
                    Text("\(medication.timesPerDay) times today")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.Theme.primary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Helper extension for selective corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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
        timesPerDay: 1,
        simplifiedInstructions: "Take 1 capsule each day"
    )

    container.mainContext.insert(medication1)
    container.mainContext.insert(medication2)

    return WeeklyCalendarView()
        .modelContainer(container)
}
