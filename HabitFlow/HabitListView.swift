import SwiftUI
import SwiftData

struct HabitListView: View {
    let habits: [Habit]
    let onCheckin: (Habit) -> Void
    @Binding var selectedHabit: Habit?
    @Binding var showDetail: Bool

    var body: some View {
        List {
            ForEach(habits) { habit in
                HabitListRowView(habit: habit, onCheckin: {
                    onCheckin(habit)
                })
                .onTapGesture {
                    selectedHabit = habit
                    showDetail = true
                }
            }
        }
        .listStyle(.plain)
    }
}

struct HabitListRowView: View {
    let habit: Habit
    let onCheckin: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(habit.color.color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: habit.icon)
                    .font(.title2)
                    .foregroundStyle(habit.color.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)

                Text("今日打卡")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(habit.checkinCountToday)")
                    .font(.caption.bold())
                    .foregroundStyle(habit.checkinCountToday > 0 ? .white : Color(hex: "34C759"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(habit.checkinCountToday > 0 ? Color(hex: "34C759") : Color(hex: "34C759").opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            // Check-in button
            Button {
                onCheckin()
            } label: {
                Text(habit.isGoalCompletedToday ? "已打卡" : "打卡")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(habit.isGoalCompletedToday ? Color.gray : Color(hex: "34C759"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}