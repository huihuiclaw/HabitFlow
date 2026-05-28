import WidgetKit
import SwiftUI

struct HabitEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let habitIcon: String
    let isCompleted: Bool
    let streakDays: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habitName: "Reading", habitIcon: "book.fill", isCompleted: false, streakDays: 7)
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
        print("DEBUG Widget: name = \(defaults?.string(forKey: "widget_habit_name") ?? "nil")")

        let name = defaults?.string(forKey: "widget_habit_name") ?? "No Habit"
        let icon = defaults?.string(forKey: "widget_habit_icon") ?? "star.fill"
        let completed = defaults?.bool(forKey: "widget_is_completed") ?? false
        let streak = defaults?.integer(forKey: "widget_streak_days") ?? 0
        return HabitEntry(date: Date(), habitName: name, habitIcon: icon, isCompleted: completed, streakDays: streak)
    }
}

struct SmallWidgetView: View {
    var entry: HabitEntry

    var body: some View {
        ZStack {
            if entry.isCompleted {
                LinearGradient(gradient: Gradient(colors: [Color(hex: "34C759"), Color(hex: "30D158")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                    Text("✓ Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            } else {
                Color(uiColor: .systemGray5)
                VStack(spacing: 8) {
                    Image(systemName: entry.habitIcon)
                        .font(.system(size: 36))
                    
                        .foregroundStyle(.gray)
                    Text("Tap to check in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.fill, for: .widget)
    }
}

struct MediumWidgetView: View {
    var entry: HabitEntry

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(entry.isCompleted ? Color(hex: "34C759").opacity(0.2) : Color.gray.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: entry.isCompleted ? "checkmark" : entry.habitIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(entry.isCompleted ? Color(hex: "34C759") : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.habitName)
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(entry.isCompleted ? Color(hex: "FF9500") : .gray)
                    Text("\(entry.streakDays) day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(entry.isCompleted ? "✓ Completed today" : "⏳ Not completed yet")
                    .font(.caption)
                    .foregroundStyle(entry.isCompleted ? Color(hex: "34C759") : .secondary)
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
