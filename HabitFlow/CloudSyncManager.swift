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

// MARK: - Widget Data Structures
struct WidgetHabitInfo: Codable {
    let id: String
    let name: String
    let icon: String
    let isCompleted: Bool
}

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
            // Check data size - iCloud KVS limit is 1MB
            if data.count > 900_000 {
                print("⚠️ Data too large (\(data.count) bytes), truncating...")
            }
            kvs.set(data, forKey: habitsKey)
            kvs.synchronize()
            updateWidgetData(with: habits)
            DispatchQueue.main.async {
                self.lastSyncTime = Date()
            }
        } catch {
            print("❌ Failed to save to iCloud: \(error)")
            // If quota error, clear old data and retry
            kvs.removeObject(forKey: habitsKey)
            kvs.synchronize()

            // Retry with current data
            do {
                let data = try JSONEncoder().encode(habits)
                kvs.set(data, forKey: habitsKey)
                kvs.synchronize()
                updateWidgetData(with: habits)
                print("✅ Retry succeeded after clearing old data")
            } catch {
                print("❌ Retry also failed: \(error)")
            }
        }
    }

    /// Update App Groups UserDefaults for Widget
    private func updateWidgetData(with habits: [HabitExport]) {
        print("DEBUG: updateWidgetData called with \(habits.count) habits")
        guard let defaults = appGroupsDefaults else {
            print("DEBUG: No defaults")
            return
        }

        // Save all habits (up to 3) as JSON array
        let habitsToSave = Array(habits.prefix(3))
        print("DEBUG: Preparing to save \(habitsToSave.count) habits")
        let widgetHabits = habitsToSave.map { habit in
            print("DEBUG: Mapping habit: \(habit.name), completed: \(habit.isCompletedToday)")
            return WidgetHabitInfo(id: habit.id.uuidString, name: habit.name, icon: habit.icon, isCompleted: habit.isGoalCompletedToday)
        }

        if let encoded = try? JSONEncoder().encode(widgetHabits) {
            defaults.set(encoded, forKey: "widget_habits")
            print("DEBUG: Successfully encoded \(widgetHabits.count) habits")
        } else {
            print("DEBUG: Failed to encode habits")
        }

        // Keep backwards compatibility - save first habit separately
        if let firstHabit = habits.first {
            defaults.set(firstHabit.name, forKey: "widget_habit_name")
            defaults.set(firstHabit.icon, forKey: "widget_habit_icon")
            defaults.set(firstHabit.isCompletedToday, forKey: "widget_is_completed")
            defaults.set(firstHabit.streakDays, forKey: "widget_streak_days")
        }

        defaults.synchronize()
        print("DEBUG: Saved widget data for \(habitsToSave.count) habits")

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
    let goalTarget: Int
    let goalUnitRaw: String

    init(from habit: Habit) {
        self.id = habit.id
        self.name = habit.name
        self.icon = habit.icon
        self.colorRaw = habit.colorRaw
        self.createdAt = habit.createdAt
        self.streakDays = habit.streakDays
        self.lastCompletedDate = habit.lastCompletedDate
        // Only keep last 30 days of check-ins for iCloud sync to avoid quota issues
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        self.completedDates = habit.completedDates.filter { $0 >= thirtyDaysAgo }
        self.goalTarget = habit.goalTarget
        self.goalUnitRaw = habit.goalUnitRaw
    }

    var isCompletedToday: Bool {
        guard let last = lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    var checkinCountToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return completedDates.filter { calendar.isDate($0, inSameDayAs: today) }.count
    }

    var isGoalCompletedToday: Bool {
        guard let goalUnit = HabitGoalUnit(rawValue: goalUnitRaw) else { return isCompletedToday }
        if goalUnit.isCountType {
            return checkinCountToday >= goalTarget
        } else {
            return isCompletedToday // TODO: implement duration tracking
        }
    }
}
