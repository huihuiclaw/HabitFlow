import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let habit: Habit

    @State private var showingDeleteAlert = false
    @State private var completedDates: [Date] = []

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                headerCard

                // Stats
                statsSection

                // Calendar View
                calendarSection

                // All Dates List
                datesListSection
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L10n.detailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert(L10n.deleteHabit, isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button(L10n.delete, role: .destructive) {
                deleteHabit()
            }
        } message: {
            Text(L10n.deleteConfirm.replacingOccurrences(of: "%@", with: habit.name))
        }
        .onAppear {
            completedDates = habit.completedDates
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(habit.color.color.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: habit.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(habit.color.color)
            }

            Text(habit.name)
                .font(.title2.bold())

            HStack(spacing: 6) {
                Image(systemName: habit.checkinCountToday > 0 ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(habit.checkinCountToday > 0 ? Color(hex: "34C759") : .secondary)
                Text("今日打卡 \(habit.checkinCountToday) 次")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 16) {
            statItem(value: "\(habit.checkinCountToday)", label: "今日打卡", icon: "hand.tap.fill", color: Color(hex: "34C759"))
            statItem(value: formatTotalStats(), label: "累计", icon: "chart.bar.fill", color: habit.color.color)
            statItem(value: streakDescription, label: L10n.bestStreak, icon: "flame.fill", color: Color(hex: "FF9500"))
        }
    }

    private var streakDescription: String {
        guard !completedDates.isEmpty else { return "0" }
        let sorted = completedDates.sorted(by: >)
        var maxStreak = 1
        var current = 1

        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i], to: sorted[i-1]).day ?? 0
            if diff == 1 {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 1
            }
        }
        return "\(maxStreak)"
    }

    private func formatTotalStats() -> String {
        let total = completedDates.count
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

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Calendar Section (Last 30 Days)
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.last30Days)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                // Weekday headers
                HStack(spacing: 4) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar grid
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(last30Days, id: \.self) { date in
                        let isCompleted = isDateCompleted(date)
                        let isToday = calendar.isDateInToday(date)

                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isCompleted ? habit.color.color : Color(uiColor: .tertiarySystemGroupedBackground))
                                .frame(width: 36, height: 36)

                            if isToday && !isCompleted {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(habit.color.color, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }

                            Text("\(calendar.component(.day, from: date))")
                                .font(.caption)
                                .foregroundStyle(isCompleted ? .white : .secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var last30Days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }

    private func isDateCompleted(_ date: Date) -> Bool {
        completedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    // MARK: - Dates List Section
    private var datesListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.allCheckins)
                .font(.caption)
                .foregroundStyle(.secondary)

            if completedDates.isEmpty {
                Text(L10n.noCheckinsYet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(24)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedDates, id: \.self) { date in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(habit.color.color)
                            Text(formattedDate(date))
                                .font(.subheadline)
                            Spacer()
                            Text(relativeDate(date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if date != sortedDates.last {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Delete Button
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text(L10n.deleteHabit)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 24)
        }
    }

    private var sortedDates: [Date] {
        completedDates.sorted(by: >)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Actions
    private func deleteHabit() {
        modelContext.delete(habit)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit(name: "Morning Run", icon: "figure.run", color: .orange))
    }
}
