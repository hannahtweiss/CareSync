//
//  ContentView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI

struct ContentView: View {
    @State private var showingScanner = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Calendar Tab
            ZStack(alignment: .bottomTrailing) {
                WeekBarCalendarView()

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
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(0)

            // All Medications Tab
            MedicationsListView()
                .tabItem {
                    Label("Medications", systemImage: "pills.fill")
                }
                .tag(1)

            // History Tab
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)

            // Reports Tab
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
                .tag(3)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .sheet(isPresented: $showingScanner) {
            ScanCode()
        }
    }
}

#Preview {
    ContentView()
}
