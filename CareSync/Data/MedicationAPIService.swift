//
//  MedicationAPIService.swift
//  CareSync
//
//  Created by Mikael Weiss on 10/17/25.
//

import Foundation

struct MedicationAPIService {
    private static let baseURL = "https://api.upcitemdb.com/prod/trial/lookup"

    static func lookupMedication(barcode: String) async -> Medication? {
        let urlString = "\(baseURL)?upc=\(barcode)"

        guard let url = URL(string: urlString) else {
            print("Invalid URL for barcode: \(barcode)")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Invalid response status code")
                return nil
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(UPCItemDBResponse.self, from: data)

            guard let item = result.items.first else {
                print("No medication found for barcode: \(barcode)")
                return nil
            }

            // Extract medication information from the product data
            let brandName = item.brand ?? "Unknown"
            let title = item.title
            let description = item.description ?? ""

            // Extract dosage and form from title (e.g., "Vitamin C 500 mg. 500 Tablets")
            let (dosage, form) = extractDosageAndForm(from: title)

            // Determine generic name from title or description
            let genericName = extractGenericName(from: title, description: description)

            let medication = Medication(
                brandName: brandName,
                genericName: genericName,
                dosage: dosage,
                form: form,
                schedule: "As directed", // Not available from UPCitemdb
                duration: "Not specified", // Not available from UPCitemdb
                upcCode: barcode,
                ndcCode: nil, // Not available from UPCitemdb
                productDescription: item.description,
                imageURL: item.images?.first
            )

            return medication
        } catch {
            print("Error fetching medication: \(error)")
            return nil
        }
    }

    private static func extractDosageAndForm(from title: String) -> (dosage: String, form: String) {
        // Extract dosage like "500 mg", "1000 IU", "25 mcg"
        let dosagePattern = #"(\d+\.?\d*)\s*(mg|mcg|g|iu|IU)"#
        if let dosageRegex = try? NSRegularExpression(pattern: dosagePattern, options: .caseInsensitive),
           let match = dosageRegex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
           let dosageRange = Range(match.range, in: title) {
            let dosage = String(title[dosageRange])

            // Extract form like "Tablets", "Capsules", "Chewable"
            let formPatterns = ["tablet", "capsule", "softgel", "gummy", "gummies", "chewable", "liquid", "powder"]
            let lowerTitle = title.lowercased()

            for pattern in formPatterns {
                if lowerTitle.contains(pattern) {
                    return (dosage, pattern.capitalized + "s")
                }
            }

            return (dosage, "Not specified")
        }

        return ("Not specified", "Not specified")
    }

    private static func extractGenericName(from title: String, description: String) -> String {
        // Common medication/supplement names to look for
        let commonNames = [
            "vitamin c", "vitamin d", "vitamin b", "multivitamin",
            "calcium", "iron", "zinc", "magnesium",
            "fish oil", "omega", "glucosamine", "chondroitin",
            "probiotic", "melatonin", "acetaminophen", "ibuprofen",
            "aspirin", "naproxen"
        ]

        let lowerTitle = title.lowercased()
        let lowerDesc = description.lowercased()

        for name in commonNames {
            if lowerTitle.contains(name) || lowerDesc.contains(name) {
                return name.capitalized
            }
        }

        // If no common name found, try to extract first meaningful word from title
        let words = title.split(separator: " ")
        if words.count >= 2 {
            // Skip brand name (first word) and return second word
            return String(words[1])
        }

        return "Dietary Supplement"
    }
}

// MARK: - UPCItemDB API Response Models
struct UPCItemDBResponse: Codable {
    let code: String
    let total: Int
    let offset: Int
    let items: [UPCItem]
}

struct UPCItem: Codable {
    let ean: String
    let title: String
    let description: String?
    let upc: String
    let brand: String?
    let model: String?
    let color: String?
    let size: String?
    let dimension: String?
    let weight: String?
    let category: String?
    let currency: String?
    let images: [String]?
}
