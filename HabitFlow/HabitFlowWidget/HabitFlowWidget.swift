import WidgetKit
import SwiftUI

struct HabitInfo: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let isCompleted: Bool
}

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [HabitInfo]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habits: [
            HabitInfo(id: "1", name: "Reading", icon: "book.fill", isCompleted: true),
            HabitInfo(id: "2", name: "Running", icon: "figure.run", isCompleted: false),
            HabitInfo(id: "3", name: "Water", icon: "drop.fill", isCompleted: false)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> HabitEntry {
        let defaults = UserDefaults(suiteName: "group.com.longneckdeer.habitflow")

        var habits: [HabitInfo] = []

        if let data = defaults?.data(forKey: "widget_habits"),
           let decoded = try? JSONDecoder().decode([HabitInfo].self, from: data) {
            print("DEBUG Widget: Found \(decoded.count) habits in widget_habits")
            habits = Array(decoded.prefix(3))
        } else {
            print("DEBUG Widget: No widget_habits data found, checking fallback")
            // Fallback single habit for backwards compatibility
            let name = defaults?.string(forKey: "widget_habit_name") ?? String(localized: "widget.no_habit")
            let icon = defaults?.string(forKey: "widget_habit_icon") ?? "star.fill"
            let completed = defaults?.bool(forKey: "widget_is_completed") ?? false
            print("DEBUG Widget: Fallback - name=\(name), completed=\(completed)")
            habits = [HabitInfo(id: "0", name: name, icon: icon, isCompleted: completed)]
        }

        return HabitEntry(date: Date(), habits: habits)
    }
}

struct SmallWidgetView: View {
    var entry: HabitEntry

    private var completedCount: Int {
        entry.habits.filter { $0.isCompleted }.count
    }

    private var totalCount: Int {
        entry.habits.count
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(String(localized: "widget.app_name"))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption.bold())
                    .foregroundStyle(completedCount == totalCount ? Color(hex: "34C759") : .secondary)
            }

            // Habits list
            VStack(spacing: 6) {
                ForEach(entry.habits.prefix(3)) { habit in
                    HStack(spacing: 8) {
                        Image(systemName: habit.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(habit.isCompleted ? Color(hex: "34C759") : .gray)
                            .frame(width: 20)

                        Text(habit.name)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer()

                        if habit.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "34C759"))
                        } else {
                            Image(systemName: "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                    }
                }
            }

            Spacer()

            // Footer status
            Text(completedCount == totalCount ? String(localized: "widget.all_completed") : String(localized: "widget.tap_to_checkin"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .containerBackground(.fill, for: .widget)
    }
}

struct MediumWidgetView: View {
    var entry: HabitEntry

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "34C759").opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: "checkmark")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: "34C759"))
            }

            VStack(alignment: .leading, spacing: 4) {
                if let firstHabit = entry.habits.first {
                    Text(firstHabit.name)
                        .font(.headline)
                    Text(firstHabit.isCompleted ? String(localized: "widget.completed") : String(localized: "widget.no_habit"))
                        .font(.caption)
                        .foregroundStyle(firstHabit.isCompleted ? Color(hex: "34C759") : .secondary)
                }
            }

            Spacer()
        }
        .padding(20)
        .containerBackground(.fill, for: .widget)
    }
}

struct HabitFlowWidget: Widget {
    let kind: String = "HabitFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HabitFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Track your daily habit progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HabitFlowWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: HabitEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@main
struct HabitFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitFlowWidget()
    }
}