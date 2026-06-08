import SwiftUI
import SwiftData

enum HabitDisplayStyle: String, CaseIterable {
    case card = "card"
    case list = "list"

    var displayName: String {
        switch self {
        case .card: return "卡片样式"
        case .list: return "列表样式"
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    @State private var showPicker = false
    @State private var celebrating = false
    @State private var selectedHabit: Habit?
    @State private var showDetail = false
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var currentPage = 0
    @State private var showSettings = false
    @AppStorage("habitDisplayStyle") private var displayStyle: String = HabitDisplayStyle.card.rawValue

    private let maxHabits = 5

    private var isCompletedToday: Bool {
        guard currentPage < habits.count else { return false }
        return habits[currentPage].isGoalCompletedToday
    }

    private var currentDisplayStyle: HabitDisplayStyle {
        HabitDisplayStyle(rawValue: displayStyle) ?? .card
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                if habits.isEmpty {
                    emptyStateView
                } else {
                    switch currentDisplayStyle {
                    case .card:
                        cardContentView
                    case .list:
                        listContentView
                    }
                }
            }
            .navigationTitle(L10n.homeTitle)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if habits.count < maxHabits {
                        Button {
                            showPicker = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundStyle(Color(hex: "34C759"))
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                HabitPickerView()
            }
            .sheet(isPresented: $showCelebration) {
                celebrationSheet
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showDetail) {
                if let habit = selectedHabit {
                    HabitDetailView(habit: habit)
                }
            }
            .onAppear {
                syncWithCloud()
            }
        }
    }

    // MARK: - Card Content View
    private var cardContentView: some View {
        VStack(spacing: 24) {
            // Date header
            VStack(spacing: 4) {
                Text(dateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(isCompletedToday ? L10n.completed : L10n.inProgress)
                    .font(.caption)
                    .foregroundStyle(isCompletedToday ? Color(hex: "34C759") : .secondary)
            }
            .padding(.top, 16)

            Spacer()

            // Habit cards with horizontal paging
            TabView(selection: $currentPage) {
                ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                    HabitCardView(
                        habit: habit,
                        habits: habits,
                        currentPage: currentPage,
                        celebrating: $celebrating,
                        onIncrement: { incrementCheckin(habit) },
                        onDecrement: { decrementCheckin(habit) },
                        onCheckin: { showCelebrationDialog(habit) }
                    )
                    .tag(index)
                    .padding(.horizontal, 16)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, minHeight: 400)

            // Page indicator
            if habits.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<habits.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color(hex: "34C759") : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            Spacer()

            // Check-in records button
            VStack(spacing: 12) {
                Button {
                    selectedHabit = habits[currentPage]
                    showDetail = true
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                        Text(L10n.checkinRecords)
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color(hex: "34C759"))
                    .clipShape(Capsule())
                }
            }
            .padding(.bottom, 32)
        }
        .padding()
    }

    // MARK: - List Content View
    private var listContentView: some View {
        HabitListView(
            habits: habits,
            onCheckin: { habit in showCelebrationDialog(habit) },
            selectedHabit: $selectedHabit,
            showDetail: $showDetail
        )
    }

    // MARK: - Actions
    private func showCelebrationDialog(_ habit: Habit) {
        let messages = L10n.celebrationMessages
        celebrationMessage = messages.randomElement() ?? messages[0]
        completeHabit(habit)
        showCelebration = true
    }

    private func incrementCheckin(_ habit: Habit) {
        habit.lastCompletedDate = Date()
        var dates = habit.completedDates
        dates.append(Date())
        habit.completedDates = dates
        let exportHabits = habits.map { HabitExport(from: $0) }
        CloudSyncManager.shared.saveHabits(exportHabits)
    }

    private func decrementCheckin(_ habit: Habit) {
        guard habit.checkinCountToday > 0 else { return }
        var dates = habit.completedDates
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let lastIndex = dates.lastIndex(where: { calendar.isDate($0, inSameDayAs: today) }) {
            dates.remove(at: lastIndex)
            habit.completedDates = dates
            let exportHabits = habits.map { HabitExport(from: $0) }
            CloudSyncManager.shared.saveHabits(exportHabits)
        }
    }

    private func completeHabit(_ habit: Habit) {
        celebrating = true
        let wasGoalCompleted = habit.isGoalCompletedToday
        if !wasGoalCompleted {
            habit.streakDays += 1
        }
        habit.lastCompletedDate = Date()
        var dates = habit.completedDates
        dates.append(Date())
        habit.completedDates = dates
        let exportHabits = habits.map { HabitExport(from: $0) }
        CloudSyncManager.shared.saveHabits(exportHabits)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            celebrating = false
        }
    }

    private func syncWithCloud() {
        CloudSyncManager.shared.triggerSync()
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color(hex: "34C759").gradient)

            VStack(spacing: 8) {
                Text(L10n.emptyTitle)
                    .font(.title2.bold())

                Text(L10n.emptySubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showPicker = true
            } label: {
                Label(L10n.emptyAddHabit, systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "34C759"))
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - Celebration Sheet
    private var celebrationSheet: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color(hex: "34C759").gradient)

            Text(L10n.celebrationTitle)
                .font(.title.bold())

            Text(celebrationMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                showCelebration = false
            } label: {
                Text(L10n.done)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "34C759"))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Habit Picker View
struct HabitPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor: HabitColor = .green
    @State private var selectedGoalTarget = 1
    @State private var selectedGoalUnit: HabitGoalUnit = .piece

    private let icons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "drop.fill", "sun.max.fill", "moon.fill",
        "figure.walk", "dumbbell.fill", "book.fill", "pencil",
        "cup.and.saucer.fill", "bed.double.fill", "alarm.fill",
        "music.note", "paintbrush.fill", "camera.fill"
    ]

    private let countOptions = [1, 2, 3, 5, 8]
    private let durationOptions = [1, 3, 5, 10, 15]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    previewCard

                    // Name
                    nameSection

                    // Icon
                    iconSection

                    // Color
                    colorSection

                    // Goal Unit
                    goalSection
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(L10n.pickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) { saveHabit() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var previewCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(selectedColor.color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: selectedIcon)
                    .font(.title)
                    .foregroundStyle(selectedColor.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name.isEmpty ? L10n.habitName : name)
                    .font(.headline)
                    .foregroundStyle(name.isEmpty ? .secondary : .primary)

                Text(goalDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var goalDescription: String {
        let unitDisplay = selectedGoalUnit == .piece ? "次" : (selectedGoalUnit == .group ? "组" : (selectedGoalUnit == .minute ? "分钟" : "秒"))
        return "\(selectedGoalTarget)\(unitDisplay)/天"
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.whatHabitQuestion)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(L10n.habitNamePlaceholder, text: $name)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.iconLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 9), spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedIcon == icon ? selectedColor.color.opacity(0.2) : Color.clear)
                                .frame(width: 40, height: 40)

                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundStyle(selectedIcon == icon ? selectedColor.color : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.colorLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(HabitColor.allCases, id: \.self) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 40, height: 40)

                            if selectedColor == color {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Goal")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                // Unit picker (个/组/分钟/秒)
                HStack(spacing: 12) {
                    ForEach(HabitGoalUnit.allCases, id: \.self) { unit in
                        Button {
                            selectedGoalUnit = unit
                        } label: {
                            Text(unit == .piece ? "次" : (unit == .group ? "组" : (unit == .minute ? "分钟" : "秒")))
                                .font(.subheadline)
                                .foregroundStyle(selectedGoalUnit == unit ? .white : .secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedGoalUnit == unit ? selectedColor.color : Color.clear)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(selectedGoalUnit == unit ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }

                // Target options based on unit type
                HStack(spacing: 12) {
                    ForEach(selectedGoalUnit.isCountType ? countOptions : durationOptions, id: \.self) { option in
                        Button {
                            selectedGoalTarget = option
                        } label: {
                            Text("\(option)")
                                .font(.subheadline)
                                .foregroundStyle(selectedGoalTarget == option ? .white : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedGoalTarget == option ? selectedColor.color : Color.clear)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(selectedGoalTarget == option ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func saveHabit() {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            color: selectedColor,
            goalTarget: selectedGoalTarget,
            goalUnit: selectedGoalUnit
        )
        modelContext.insert(habit)

        // Sync all habits to iCloud
        let exportHabits = habits.map { HabitExport(from: $0) }
        CloudSyncManager.shared.saveHabits(exportHabits)

        dismiss()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Habit.self, inMemory: true)
}