//
//  ContentView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI

struct ContentView: View {
    @State private var showingScanner = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main calendar view
            WeeklyCalendarView()

            // Floating action button to add new medication
            Button(action: {
                showingScanner = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                    Text("Add Medication")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(30)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(24)
        }
        .sheet(isPresented: $showingScanner) {
            ScanCode()
        }
    }
}

#Preview {
    ContentView()
}
