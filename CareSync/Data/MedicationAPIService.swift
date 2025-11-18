//
//  MedicationAPIService.swift
//  CareSync
//
//  Created by Mikael Weiss on 10/17/25.
//

import Foundation

struct MedicationAPIService {
    private static let upcItemDBURL = "https://api.upcitemdb.com/prod/trial/lookup"
    private static let openFDAURL = "https://api.fda.gov/drug/label.json"
    private static let rxNormURL = "https://rxnav.nlm.nih.gov/REST"

    static func lookupMedication(barcode: String) async -> (Medication?, String?) {
        // Try UPCitemDB first (works well for OTC products like vitamins)
        let (medication, error) = await lookupFromUPCItemDB(barcode: barcode)

        if let medication = medication {
            print("✓ Found medication in UPCitemDB")
            return (medication, nil)
        }

        print("UPCitemDB lookup failed: \(error ?? "unknown error")")
        print("Trying openFDA as fallback for prescription medication...")

        // Fallback to openFDA (better for prescription medications with UPC)
        let (fdaMedication, fdaError) = await lookupFromOpenFDA(barcode: barcode)

        if let fdaMedication = fdaMedication {
            print("✓ Found medication in openFDA")
            return (fdaMedication, nil)
        }

        print("openFDA lookup failed: \(fdaError ?? "unknown error")")
        print("Trying RxNorm for pharmacy NDC barcodes...")

        // Final fallback to RxNorm (for pharmacy-dispensed medications with NDC codes)
        return await lookupFromRxNorm(barcode: barcode)
    }

    private static func lookupFromUPCItemDB(barcode: String) async -> (Medication?, String?) {
        let urlString = "\(upcItemDBURL)?upc=\(barcode)"

        guard let url = URL(string: urlString) else {
            print("Invalid URL for barcode: \(barcode)")
            return (nil, "Invalid barcode format")
        }

        do {
            print("Fetching medication for barcode: \(barcode)")
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid HTTP response")
                return (nil, "Network error occurred")
            }

            print("HTTP Status Code: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    return (nil, "Medication not found in database")
                } else {
                    return (nil, "Server error (code: \(httpResponse.statusCode))")
                }
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(UPCItemDBResponse.self, from: data)

            print("API Response - Total items: \(result.total)")

            guard let item = result.items.first else {
                print("No medication found for barcode: \(barcode)")
                return (nil, "No product found for this barcode")
            }

            print("Found item: \(item.title)")

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

            print("Successfully created medication: \(medication.brandName)")
            return (medication, nil)
        } catch {
            print("Error fetching medication: \(error)")
            return (nil, "Error: \(error.localizedDescription)")
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

    // MARK: - openFDA API Integration

    private static func lookupFromOpenFDA(barcode: String) async -> (Medication?, String?) {
        // openFDA search by UPC in the openfda.upc field
        let searchQuery = "openfda.upc:\(barcode)"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery
        let urlString = "\(openFDAURL)?search=\(encodedQuery)&limit=1"

        guard let url = URL(string: urlString) else {
            print("Invalid openFDA URL for barcode: \(barcode)")
            return (nil, "Invalid barcode format")
        }

        do {
            print("Fetching from openFDA for barcode: \(barcode)")
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid HTTP response from openFDA")
                return (nil, "Network error occurred")
            }

            print("openFDA HTTP Status Code: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    return (nil, "Medication not found in either database. This may be a pharmacy-dispensed medication without retail barcode data.")
                } else {
                    return (nil, "openFDA server error (code: \(httpResponse.statusCode))")
                }
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(OpenFDAResponse.self, from: data)

            guard let drugLabel = result.results.first else {
                print("No medication found in openFDA for barcode: \(barcode)")
                return (nil, "Medication not found in either database. This may be a pharmacy-dispensed medication without retail barcode data.")
            }

            print("Found medication in openFDA: \(drugLabel.openfda?.brand_name?.first ?? "Unknown")")

            // Extract medication information from FDA data
            let brandName = drugLabel.openfda?.brand_name?.first ?? "Unknown"
            let genericName = drugLabel.openfda?.generic_name?.first ?? extractGenericNameFromFDA(drugLabel)

            // Extract dosage and form from FDA data
            let dosageForm = drugLabel.openfda?.dosage_form?.first ?? "Not specified"
            let strength = drugLabel.openfda?.strength?.first

            // Build dosage string from available data
            let dosage = strength ?? "See label"
            let form = dosageForm.capitalized

            // Extract NDC code
            let ndcCode = drugLabel.openfda?.product_ndc?.first

            // Try to extract schedule from dosage_and_administration
            let schedule = extractScheduleFromFDA(drugLabel.dosage_and_administration?.first)

            let medication = Medication(
                brandName: brandName,
                genericName: genericName,
                dosage: dosage,
                form: form,
                schedule: schedule,
                duration: "As prescribed",
                upcCode: barcode,
                ndcCode: ndcCode,
                productDescription: drugLabel.description?.first ?? drugLabel.purpose?.first,
                imageURL: nil // FDA doesn't provide product images
            )

            print("Successfully created medication from openFDA: \(medication.brandName)")
            return (medication, nil)

        } catch let decodingError as DecodingError {
            print("openFDA decoding error: \(decodingError)")
            return (nil, "Medication not found in either database. This may be a pharmacy-dispensed medication without retail barcode data.")
        } catch {
            print("Error fetching from openFDA: \(error)")
            return (nil, "Medication not found in either database. This may be a pharmacy-dispensed medication without retail barcode data.")
        }
    }

    private static func extractGenericNameFromFDA(_ drugLabel: OpenFDADrugLabel) -> String {
        // Try various fields to find generic name
        if let genericName = drugLabel.openfda?.generic_name?.first {
            return genericName
        }

        if let substanceName = drugLabel.openfda?.substance_name?.first {
            return substanceName
        }

        return "Prescription Medication"
    }

    private static func extractScheduleFromFDA(_ dosageText: String?) -> String {
        guard let text = dosageText else {
            return "As prescribed"
        }

        let lowerText = text.lowercased()

        // Look for common dosing patterns
        if lowerText.contains("once daily") || lowerText.contains("once a day") {
            return "Once daily"
        } else if lowerText.contains("twice daily") || lowerText.contains("twice a day") {
            return "Twice daily"
        } else if lowerText.contains("three times daily") || lowerText.contains("three times a day") {
            return "Three times daily"
        } else if lowerText.contains("four times daily") || lowerText.contains("four times a day") {
            return "Four times daily"
        } else if lowerText.contains("every 4 hours") {
            return "Every 4 hours"
        } else if lowerText.contains("every 6 hours") {
            return "Every 6 hours"
        } else if lowerText.contains("every 8 hours") {
            return "Every 8 hours"
        } else if lowerText.contains("every 12 hours") {
            return "Every 12 hours"
        }

        return "As prescribed"
    }

    // MARK: - RxNorm API Integration (for NDC-based pharmacy barcodes)

    private static func lookupFromRxNorm(barcode: String) async -> (Medication?, String?) {
        // Check if this is an NDC-based barcode (starts with "3" and is 12 digits)
        guard barcode.hasPrefix("3") && barcode.count == 12 else {
            return (nil, "Medication not found. This barcode format is not supported by any available database.")
        }

        // Extract the 10-digit NDC from the barcode (remove leading "3" and trailing check digit)
        let startIndex = barcode.index(barcode.startIndex, offsetBy: 1)
        let endIndex = barcode.index(barcode.startIndex, offsetBy: 11)
        let ndcDigits = String(barcode[startIndex..<endIndex])

        print("Detected NDC-based barcode. Extracted NDC digits: \(ndcDigits)")

        // Try all possible NDC formats: 4-4-2, 5-3-2, 5-4-1, 6-3-2, 6-4-1
        let ndcFormats = [
            (4, 4, 2),
            (5, 3, 2),
            (5, 4, 1),
            (6, 3, 2),
            (6, 4, 1)
        ]

        for (seg1Len, seg2Len, seg3Len) in ndcFormats {
            let formattedNDC = formatNDC(digits: ndcDigits, seg1: seg1Len, seg2: seg2Len, seg3: seg3Len)
            print("Trying NDC format: \(formattedNDC)")

            let (medication, error) = await queryRxNormNDC(ndc: formattedNDC, originalBarcode: barcode)

            if let medication = medication {
                print("✓ Found medication in RxNorm with NDC: \(formattedNDC)")
                return (medication, nil)
            }

            print("RxNorm lookup failed for \(formattedNDC): \(error ?? "unknown error")")
        }

        return (nil, "Medication not found in any database. This may be a pharmacy-specific barcode or the medication is not in the public databases.")
    }

    private static func formatNDC(digits: String, seg1: Int, seg2: Int, seg3: Int) -> String {
        let seg1End = digits.index(digits.startIndex, offsetBy: seg1)
        let seg2End = digits.index(seg1End, offsetBy: seg2)

        let segment1 = String(digits[..<seg1End])
        let segment2 = String(digits[seg1End..<seg2End])
        let segment3 = String(digits[seg2End...])

        return "\(segment1)-\(segment2)-\(segment3)"
    }

    private static func queryRxNormNDC(ndc: String, originalBarcode: String) async -> (Medication?, String?) {
        let urlString = "\(rxNormURL)/ndcproperties.json?id=\(ndc)"

        guard let url = URL(string: urlString) else {
            return (nil, "Invalid NDC format")
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                return (nil, "Network error")
            }

            guard httpResponse.statusCode == 200 else {
                return (nil, "NDC not found (HTTP \(httpResponse.statusCode))")
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(RxNormNDCResponse.self, from: data)

            guard let ndcProperty = result.ndcPropertyList?.ndcProperty?.first else {
                return (nil, "No NDC properties found")
            }

            // Extract medication information from RxNorm data
            let brandName = ndcProperty.proprietaryName ?? "Unknown"
            let genericName = ndcProperty.nonProprietaryName ?? "Prescription Medication"
            let dosageForm = ndcProperty.dosageFormName ?? "Not specified"
            let labeler = ndcProperty.labelerName ?? "Unknown Manufacturer"

            // Extract strength from packaging info if available
            let strength = extractStrengthFromPackaging(ndcProperty.packaging)
            let dosage = strength ?? "See prescription label"

            let medication = Medication(
                brandName: brandName,
                genericName: genericName,
                dosage: dosage,
                form: dosageForm.capitalized,
                schedule: "As prescribed",
                duration: "As prescribed",
                upcCode: originalBarcode,
                ndcCode: ndc,
                productDescription: "Manufacturer: \(labeler)",
                imageURL: nil
            )

            return (medication, nil)

        } catch {
            return (nil, "RxNorm query error: \(error.localizedDescription)")
        }
    }

    private static func extractStrengthFromPackaging(_ packaging: [RxNormPackaging]?) -> String? {
        guard let packaging = packaging, let firstPackage = packaging.first else {
            return nil
        }

        // Try to find a property with strength information
        if let strengthProp = firstPackage.propertyConceptList?.propertyConcept?.first(where: { prop in
            prop.propName?.lowercased().contains("strength") == true ||
            prop.propName?.lowercased().contains("active") == true
        }) {
            return strengthProp.propValue
        }

        return nil
    }
}

// MARK: - RxNorm API Response Models

struct RxNormNDCResponse: Codable {
    let ndcPropertyList: RxNormNDCPropertyList?
}

struct RxNormNDCPropertyList: Codable {
    let ndcProperty: [RxNormNDCProperty]?
}

struct RxNormNDCProperty: Codable {
    let ndcItem: String?
    let rxcui: String?
    let splSetIdItem: String?
    let packaging: [RxNormPackaging]?
    let proprietaryName: String?
    let nonProprietaryName: String?
    let dosageFormName: String?
    let labelerName: String?
    let startMarketingDate: String?
    let endMarketingDate: String?
}

struct RxNormPackaging: Codable {
    let ndcItem: String?
    let description: String?
    let propertyConceptList: RxNormPropertyConceptList?
}

struct RxNormPropertyConceptList: Codable {
    let propertyConcept: [RxNormPropertyConcept]?
}

struct RxNormPropertyConcept: Codable {
    let propCategory: String?
    let propName: String?
    let propValue: String?
}

// MARK: - openFDA API Response Models

struct OpenFDAResponse: Codable {
    let results: [OpenFDADrugLabel]
}

struct OpenFDADrugLabel: Codable {
    let openfda: OpenFDAMetadata?
    let purpose: [String]?
    let description: [String]?
    let dosage_and_administration: [String]?
    let active_ingredient: [String]?
    let inactive_ingredient: [String]?
}

struct OpenFDAMetadata: Codable {
    let brand_name: [String]?
    let generic_name: [String]?
    let manufacturer_name: [String]?
    let product_ndc: [String]?
    let product_type: [String]?
    let route: [String]?
    let substance_name: [String]?
    let dosage_form: [String]?
    let strength: [String]?
    let upc: [String]?
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
