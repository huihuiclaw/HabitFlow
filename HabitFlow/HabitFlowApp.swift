import SwiftUI
import SwiftData

@main
struct HabitFlowApp: App {
    init() {
        // Initialize CloudSyncManager singleton
        _ = CloudSyncManager.shared
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: Habit.self)
    }
}