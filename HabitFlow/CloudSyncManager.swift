import Foundation
import WidgetKit

// MARK: - CloudSyncManager
/// Singleton manager for iCloud key-value store synchronization
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    private let kvs = NSUbiquitousKeyValueStore.default
    private let habitsKey = "habits_data"
    private var syncTimer: Timer?

    /// App Groups UserDefaults for Widget sharing
    private let appGroupsDefaults = UserDefaults(suiteName: "group.com.longneckdeer.habitflow")

    @Published var lastSyncTime: Date?

    private init() {
        setupNotifications()
        startPeriodicSync()
    }

    deinit {
        syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvs
        )
        kvs.synchronize()
    }

    @objc private func handleExternalChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }

        switch changeReason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            // Server change received - will be handled via KVS observer
            DispatchQueue.main.async {
                self.lastSyncTime = Date()
            }
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            print("⚠️ iCloud KVS quota exceeded")
        case NSUbiquitousKeyValueStoreAccountChange:
            print("📱 iCloud account changed")
        default:
            break
        }
    }

    // MARK: - Periodic Sync
    private func startPeriodicSync() {
        // Sync every 5 minutes
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.triggerSync()
        }
    }

    // MARK: - Sync Actions
    func triggerSync() {
        kvs.synchronize()
        DispatchQueue.main.async {
            self.lastSyncTime = Date()
        }
    }

    /// Save habits to iCloud KVS (call after every modification)
    func saveHabits(_ habits: [HabitExport]) {
        do {
            let data = try JSONEncoder().encode(habits)
            kvs.set(data, forKey: habitsKey)
            kvs.synchronize()
            updateWidgetData(with: habits)
            DispatchQueue.main.async {
                self.lastSyncTime = Date()
            }
        } catch {
            print("❌ Failed to encode habits for iCloud: \(error)")
        }
    }

    /// Update App Groups UserDefaults for Widget
    private func updateWidgetData(with habits: [HabitExport]) {
        print("DEBUG: updateWidgetData called with \(habits.count) habits")
        guard let defaults = appGroupsDefaults, let firstHabit = habits.first else {
            print("DEBUG: No habits or no defaults")
            return
        }
        defaults.set(firstHabit.name, forKey: "widget_habit_name")
        defaults.set(firstHabit.icon, forKey: "widget_habit_icon")
        defaults.set(firstHabit.isCompletedToday, forKey: "widget_is_completed")
        defaults.set(firstHabit.streakDays, forKey: "widget_streak_days")
        defaults.synchronize()

        print("DEBUG: Saved widget data - name: \(firstHabit.name)")

        // 刷新 widget
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Load habits from iCloud KVS
    func loadHabits() -> [HabitExport]? {
        guard let data = kvs.data(forKey: habitsKey) else {
            return nil
        }
        return try? JSONDecoder().decode([HabitExport].self, from: data)
    }

    /// Check if iCloud data exists
    var hasCloudData: Bool {
        kvs.data(forKey: habitsKey) != nil
    }
}

// MARK: - Habit Export (for JSON encoding)
struct HabitExport: Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorRaw: String
    let createdAt: Date
    let streakDays: Int
    let lastCompletedDate: Date?
    let completedDates: [Date]

    init(from habit: Habit) {
        self.id = habit.id
        self.name = habit.name
        self.icon = habit.icon
        self.colorRaw = habit.colorRaw
        self.createdAt = habit.createdAt
        self.streakDays = habit.streakDays
        self.lastCompletedDate = habit.lastCompletedDate
        self.completedDates = habit.completedDates
    }

    var isCompletedToday: Bool {
        guard let last = lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(last)
    }
}
