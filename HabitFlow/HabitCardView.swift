import SwiftUI
import SwiftData

struct HabitCardView: View {
    let habit: Habit
    let habits: [Habit]
    let currentPage: Int
    @Binding var celebrating: Bool
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onCheckin: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Icon with checkmark badge
            ZStack {
                Circle()
                    .fill(habit.color.color.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: habit.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(habit.color.color)

                if habit.isGoalCompletedToday && habit.id == habits[currentPage].id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: "34C759"))
                        .offset(x: 40, y: 40)
                }
            }
            .scaleEffect(celebrating ? 1.15 : 1.0)

            // Name
            Text(habit.name)
                .font(.title.bold())
                .foregroundStyle(.primary)

            // Today's check-in count
            HStack(spacing: 6) {
                Image(systemName: habit.checkinCountToday > 0 ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(habit.checkinCountToday > 0 ? Color(hex: "34C759") : .secondary)

                Text("今日打卡 \(habit.checkinCountToday) 次")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Total stats
            Text("累计 \(formatTotalStats(habit))")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Quick adjust buttons
            HStack(spacing: 20) {
                Button {
                    onDecrement()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(habit.checkinCountToday > 0 ? Color(hex: "FF9500") : .gray.opacity(0.3))
                }
                .disabled(habit.checkinCountToday <= 0)

                Text("\(habit.checkinCountToday)")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                    .frame(minWidth: 40)

                Button {
                    onIncrement()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color(hex: "34C759"))
                }
            }

            // Check-in button
            Button {
                onCheckin()
            } label: {
                Text(L10n.checkinButton)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 56)
                    .background(Color(hex: "34C759"))
                    .clipShape(Capsule())
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    private func formatTotalStats(_ habit: Habit) -> String {
        let total = habit.completedDates.count
        if habit.goalUnit.isCountType {
            switch habit.goalUnit {
            case .piece:
                return "\(total) 次"
            case .group:
                return "\(total) 组"
            default:
                return "\(total) 次"
            }
        } else {
            return "\(total) 次"
        }
    }
}