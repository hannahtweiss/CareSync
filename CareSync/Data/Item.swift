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
    var upcCode: String
    var productDescription: String?
    var imageURL: String?
    var timestamp: Date

    init(
        brandName: String,
        genericName: String,
        dosage: String,
        form: String,
        schedule: String,
        duration: String,
        upcCode: String,
        ndcCode: String? = nil,
        productDescription: String? = nil,
        imageURL: String? = nil,
        timestamp: Date = Date()
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
    }
}
