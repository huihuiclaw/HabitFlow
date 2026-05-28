import SwiftUI
import SwiftData

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

    private let maxHabits = 5

    private var isCompletedToday: Bool {
        guard currentPage < habits.count else { return false }
        return habits[currentPage].isCompletedToday
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                if habits.isEmpty {
                    emptyStateView
                } else {
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
                                habitCardView(habit)
                                    .tag(index)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut(duration: 0.4), value: currentPage)

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
            }
            .sheet(isPresented: $showPicker) {
                HabitPickerView()
            }
            .sheet(isPresented: $showCelebration) {
                celebrationSheet
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

    // MARK: - Habit Card View
    private func habitCardView(_ habit: Habit) -> some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        isCompletedToday && habit.id == habits[currentPage].id
                            ? Color(hex: "34C759").opacity(0.2)
                            : habit.color.color.opacity(0.15)
                    )
                    .frame(width: 120, height: 120)

                if isCompletedToday && habit.id == habits[currentPage].id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(Color(hex: "34C759"))
                } else {
                    Image(systemName: habit.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(habit.color.color)
                }
            }
            .scaleEffect(celebrating ? 1.15 : 1.0)

            // Name
            Text(habit.name)
                .font(.title.bold())
                .foregroundStyle(.primary)

            // Streak
            HStack(spacing: 6) {
                Image(systemName: isCompletedToday && habit.id == habits[currentPage].id ? "flame.fill" : "flame")
                    .foregroundStyle(isCompletedToday && habit.id == habits[currentPage].id ? Color(hex: "FF9500") : .secondary)

                Text("\(habit.streakDays) \(L10n.dayStreak)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Check-in button
            if !isCompletedToday || habit.id != habits[currentPage].id {
                Button {
                    if !isCompletedToday && habit.id == habits[currentPage].id {
                        showCelebrationDialog(habit)
                    }
                } label: {
                    Text(isCompletedToday ? L10n.completed : L10n.checkinButton)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 56)
                        .background(isCompletedToday ? Color.gray : Color(hex: "34C759"))
                        .clipShape(Capsule())
                }
                .disabled(isCompletedToday && habit.id == habits[currentPage].id)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    private func showCelebrationDialog(_ habit: Habit) {
        let messages = L10n.celebrationMessages
        celebrationMessage = messages.randomElement() ?? messages[0]
        completeHabit(habit)
        showCelebration = true
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

    // MARK: - Celebration Particles
    @ViewBuilder
    private var celebrationParticles: some View {
        if celebrating {
            ParticleView()
                .allowsHitTesting(false)
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

    private func completeHabit(_ habit: Habit) {
        guard !isCompletedToday else { return }

        celebrating = true

        habit.lastCompletedDate = Date()
        habit.streakDays += 1

        // Add to completed dates
        var dates = habit.completedDates
        dates.append(Date())
        habit.completedDates = dates

        // Sync to iCloud
        CloudSyncManager.shared.saveHabits([HabitExport(from: habit)])

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            celebrating = false
        }
    }

    private func syncWithCloud() {
        CloudSyncManager.shared.triggerSync()
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

    private let icons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "drop.fill", "sun.max.fill", "moon.fill",
        "figure.walk", "dumbbell.fill", "book.fill", "pencil",
        "cup.and.saucer.fill", "bed.double.fill", "alarm.fill",
        "music.note", "paintbrush.fill", "camera.fill"
    ]

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

                Text(L10n.focusToday)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

    private func saveHabit() {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            color: selectedColor
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