//
//  OpenAIService.swift
//  CareSync
//
//  Created by Claude on 11/17/25.
//

import Foundation

struct OpenAIService {
    // MARK: - Configuration
    // TODO: Replace with your OpenAI API key
    // Get free API key at: https://platform.openai.com/api-keys
    private static let apiKey = "YOUR_OPENAI_API_KEY_HERE"
    private static let apiURL = "https://api.openai.com/v1/chat/completions"

    // MARK: - AI-Powered Label Parsing

    /// Uses GPT-3.5-turbo to extract medication information from prescription label text
    static func parsePrescriptionLabelWithAI(text: String) async -> (name: String, directions: String, warnings: String)? {
        print("🤖 Sending text to OpenAI for parsing...")

        let prompt = """
        You are a medical prescription label parser. Extract ONLY the following information from this prescription label text:

        1. MEDICATION NAME (just the drug name, including dosage if present)
        2. DIRECTIONS (how to take the medication)
        3. WARNINGS (any important warnings or side effects mentioned)

        Return the information in this EXACT JSON format:
        {
            "name": "medication name here",
            "directions": "directions here",
            "warnings": "warnings here or 'None listed' if no warnings"
        }

        Prescription label text:
        \(text)
        """

        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that extracts medication information from prescription labels. Always respond with valid JSON."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 200
        ]

        guard let url = URL(string: apiURL) else {
            print("❌ Invalid OpenAI API URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                return nil
            }

            print("📡 OpenAI API Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ OpenAI API Error: \(errorString)")
                }
                return nil
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(OpenAIResponse.self, from: data)

            guard let content = result.choices.first?.message.content else {
                print("❌ No content in OpenAI response")
                return nil
            }

            print("✅ OpenAI Response:\n\(content)")

            // Parse the JSON response from GPT
            if let jsonData = content.data(using: .utf8),
               let parsed = try? JSONDecoder().decode(ParsedMedication.self, from: jsonData) {
                print("✅ Successfully parsed medication info:")
                print("   Name: \(parsed.name)")
                print("   Directions: \(parsed.directions)")
                print("   Warnings: \(parsed.warnings)")
                return (parsed.name, parsed.directions, parsed.warnings)
            } else {
                print("❌ Failed to parse JSON from GPT response")
                return nil
            }

        } catch {
            print("❌ OpenAI API Error: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Response Models

struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}

struct ParsedMedication: Codable {
    let name: String
    let directions: String
    let warnings: String
}
