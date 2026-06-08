import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("habitDisplayStyle") private var displayStyle: String = HabitDisplayStyle.card.rawValue

    var body: some View {
        NavigationStack {
            List {
                // App Info Section
                Section {
                    HStack {
                        Image(systemName: "app.fill")
                            .font(.title)
                            .foregroundStyle(Color(hex: "34C759"))
                            .frame(width: 50, height: 50)
                            .background(Color(hex: "34C759").opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("打卡精灵")
                                .font(.headline)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Display Section
                Section("Display") {
                    Picker("Card Style", selection: $displayStyle) {
                        ForEach(HabitDisplayStyle.allCases, id: \.rawValue) { style in
                            Text(style.displayName).tag(style.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Data Section
                Section("Data") {
                    NavigationLink {
                        Text("iCloud Sync Settings")
                    } label: {
                        Label("iCloud Sync", systemImage: "icloud")
                    }

                    Button {
                        // Clear all data action
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }

                // About Section
                Section("About") {
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }

                    NavigationLink {
                        Text("Privacy Policy")
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        Text("Terms of Service")
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                // Debug Section
                #if DEBUG
                Section("Debug") {
                    Button {
                        CloudSyncManager.shared.triggerSync()
                    } label: {
                        Label("Force iCloud Sync", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button {
                        let kvs = NSUbiquitousKeyValueStore.default
                        kvs.removeObject(forKey: "habits_data")
                        kvs.synchronize()
                    } label: {
                        Label("Clear iCloud Data", systemImage: "icloud.slash")
                            .foregroundStyle(.orange)
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}