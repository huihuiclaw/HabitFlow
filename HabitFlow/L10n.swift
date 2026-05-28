import SwiftUI

// MARK: - String Localization
extension String {
    func localized() -> String {
        NSLocalizedString(self, comment: "")
    }

    func localized(_ args: CVarArg...) -> String {
        let format = NSLocalizedString(self, comment: "")
        return args.isEmpty ? format : String(format: format, arguments: args)
    }
}

// MARK: - Convenience Localized Text
struct L10n {
    // General
    static var appName: String { "app_name".localized() }
    static var cancel: String { "cancel".localized() }
    static var save: String { "save".localized() }
    static var delete: String { "delete".localized() }
    static var done: String { "done".localized() }

    // Home
    static var homeTitle: String { "home.title".localized() }
    static var completed: String { "home.completed".localized() }
    static var inProgress: String { "home.in_progress".localized() }
    static var dayStreak: String { "home.day_streak".localized() }
    static var tapToComplete: String { "home.tap_to_complete".localized() }
    static var longPressDetails: String { "home.long_press_details".localized() }
    static var addNewHabit: String { "home.add_new_habit".localized() }
    static var orKeepCurrent: String { "home.or_keep_current".localized() }

    // Empty State
    static var emptyTitle: String { "empty.title".localized() }
    static var emptySubtitle: String { "empty.subtitle".localized() }
    static var emptyAddHabit: String { "empty.add_habit".localized() }

    // Habit Picker
    static var pickerTitle: String { "picker.title".localized() }
    static var habitNamePlaceholder: String { "picker.habit_name_placeholder".localized() }
    static var whatHabitQuestion: String { "picker.what_habit_question".localized() }
    static var iconLabel: String { "picker.icon_label".localized() }
    static var colorLabel: String { "picker.color_label".localized() }
    static var focusToday: String { "picker.focus_today".localized() }
    static var habitName: String { "picker.habit_name".localized() }

    // Habit Detail
    static var detailTitle: String { "detail.title".localized() }
    static var checkinRecords: String { "detail.checkin_records".localized() }
    static var checkinButton: String { "checkin.button".localized() }
    static var celebrationTitle: String { "celebration.title".localized() }
    static var celebrationMessages: [String] {
        [
            "celebration.message.1".localized(),
            "celebration.message.2".localized(),
            "celebration.message.3".localized(),
            "celebration.message.4".localized(),
            "celebration.message.5".localized(),
            "celebration.message.6".localized()
        ]
    }
    static var currentStreak: String { "detail.current_streak".localized() }
    static var totalCheckins: String { "detail.total_checkins".localized() }
    static var bestStreak: String { "detail.best_streak".localized() }
    static var last30Days: String { "detail.last_30_days".localized() }
    static var allCheckins: String { "detail.all_checkins".localized() }
    static var noCheckinsYet: String { "detail.no_checkins_yet".localized() }
    static var deleteHabit: String { "detail.delete_habit".localized() }
    static var deleteConfirm: String { "detail.delete_confirm".localized() }

    // Days
    static var dayToday: String { "day.today".localized() }
    static var dayYesterday: String { "day.yesterday".localized() }
}
