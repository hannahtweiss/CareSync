//
//  Medication.swift
//  CareSync
//
//  Created by Mikael Weiss on 10/11/25.
//

import Foundation
import SwiftData

@Model
final class Medication {
    var brandName: String
    var genericName: String
    var dosage: String
    var form: String
    var schedule: String
    var duration: String
    var ndcCode: String?
    var upcCode: String?
    var productDescription: String?
    var imageURL: String?
    var timestamp: Date
    var warnings: String?  // Important warnings from prescription label

    // Parsed scheduling information
    var timesPerDay: Int
    var simplifiedInstructions: String
    var isActive: Bool
    var scheduledTimes: [Date]  // Times when medication should be taken each day

    init(
        brandName: String,
        genericName: String,
        dosage: String,
        form: String,
        schedule: String,
        duration: String,
        upcCode: String? = nil,
        ndcCode: String? = nil,
        productDescription: String? = nil,
        imageURL: String? = nil,
        timestamp: Date = Date(),
        warnings: String? = nil,
        timesPerDay: Int = 1,
        simplifiedInstructions: String = "",
        isActive: Bool = true,
        scheduledTimes: [Date] = []
    ) {
        self.brandName = brandName
        self.genericName = genericName
        self.dosage = dosage
        self.form = form
        self.schedule = schedule
        self.duration = duration
        self.upcCode = upcCode
        self.ndcCode = ndcCode
        self.productDescription = productDescription
        self.imageURL = imageURL
        self.timestamp = timestamp
        self.warnings = warnings
        self.timesPerDay = timesPerDay
        self.simplifiedInstructions = simplifiedInstructions
        self.isActive = isActive
        self.scheduledTimes = scheduledTimes.isEmpty ? Medication.generateDefaultTimes(count: timesPerDay) : scheduledTimes
    }

    // Generate default scheduled times based on timesPerDay
    private static func generateDefaultTimes(count: Int) -> [Date] {
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
            let hoursApart = 24 / count
            for i in 0..<count {
                let hour = 8 + (i * hoursApart)
                times.append(calendar.date(bySettingHour: hour % 24, minute: 0, second: 0, of: Date()) ?? Date())
            }
        }

        return times
    }
}
