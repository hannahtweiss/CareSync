//
//  ContentView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI

struct ContentView: View {
    @State private var showingScanner = false
    @State private var showingManualEntry = false
    @State private var showingAddOptions = false
    @State private var scanMode: ScanCode.ScanMode = .barcode
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Calendar Tab
            ZStack(alignment: .bottomTrailing) {
                WeekBarCalendarView()

                // Floating action button to add new medication
                Button(action: {
                    showingAddOptions = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(Color.Theme.primary)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(28)
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
        .confirmationDialog("Add Medication", isPresented: $showingAddOptions, titleVisibility: .visible) {
            Button("Scan Barcode") {
                scanMode = .barcode
                showingScanner = true
            }

            Button("Scan Label") {
                scanMode = .label
                showingScanner = true
            }

            Button("Manual Entry") {
                showingManualEntry = true
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how you'd like to add your medication")
        }
        .sheet(isPresented: $showingScanner) {
            ScanCode(initialScanMode: scanMode)
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualMedicationEntry()
        }
    }
}

#Preview {
    ContentView()
}
