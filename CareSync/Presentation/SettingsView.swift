//
//  SettingsView.swift
//  CareSync
//
//  Created by Claude Code
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Enable Reminders", isOn: $notificationsEnabled)

                    if notificationsEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Support") {
                    Button(action: {
                        // TODO: Open help documentation
                    }) {
                        HStack {
                            Text("Help & Documentation")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        // TODO: Open feedback form
                    }) {
                        HStack {
                            Text("Send Feedback")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Data") {
                    Button(action: {
                        // TODO: Export data
                    }) {
                        HStack {
                            Text("Export Data")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                        }
                    }

                    Button(role: .destructive, action: {
                        // TODO: Clear all data with confirmation
                    }) {
                        Text("Clear All Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
