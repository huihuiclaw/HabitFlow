import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    @State private var showPicker = false
    @State private var celebrating = false
    @State private var selectedHabit: Habit?
    @State private var showDetail = false

    private var currentHabit: Habit? {
        habits.first
    }

    private var isCompletedToday: Bool {
        currentHabit?.isCompletedToday ?? false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    if let habit = currentHabit {
                        activeHabitView(habit)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("HabitFlow")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if currentHabit != nil {
                        Button {
                            showPicker = true
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title2)
                                .foregroundStyle(Color(hex: "34C759"))
                        }
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                HabitPickerView()
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

    // MARK: - Active Habit View
    private func activeHabitView(_ habit: Habit) -> some View {
        VStack(spacing: 24) {
            // Date header
            VStack(spacing: 4) {
                Text(dateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(isCompletedToday ? "✓ Completed" : "In Progress")
                    .font(.caption)
                    .foregroundStyle(isCompletedToday ? Color(hex: "34C759") : .secondary)
            }

            Spacer()

            // Main habit card
            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isCompletedToday
                                ? Color(hex: "34C759").opacity(0.2)
                                : habit.color.color.opacity(0.15)
                        )
                        .frame(width: 120, height: 120)

                    if isCompletedToday {
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
                    Image(systemName: isCompletedToday ? "flame.fill" : "flame")
                        .foregroundStyle(isCompletedToday ? Color(hex: "FF9500") : .secondary)

                    Text("\(habit.streakDays) day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Action hint
                if !isCompletedToday {
                    Text("Tap to complete ✓")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }

                // Long press hint
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption2)
                    Text("Long press for details")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .onTapGesture {
                if !isCompletedToday {
                    completeHabit(habit)
                }
            }
            .onLongPressGesture {
                selectedHabit = habit
                showDetail = true
            }

            Spacer()

            // Change habit button
            if isCompletedToday {
                VStack(spacing: 12) {
                    Button {
                        showPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Habit")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color(hex: "34C759"))
                        .clipShape(Capsule())
                    }

                    Text("or keep current and build streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay(celebrationParticles)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color(hex: "34C759").gradient)

            VStack(spacing: 8) {
                Text("One Habit, One Day")
                    .font(.title2.bold())

                Text("Focus on a single habit\nand build it day by day")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showPicker = true
            } label: {
                Label("Add Today's Habit", systemImage: "plus")
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
        // Initial sync trigger
        CloudSyncManager.shared.triggerSync()
    }
}

// MARK: - Habit Picker View
struct HabitPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

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
            .navigationTitle("Today's Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveHabit() }
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
                Text(name.isEmpty ? "Habit Name" : name)
                    .font(.headline)
                    .foregroundStyle(name.isEmpty ? .secondary : .primary)

                Text("Focus today")
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
            Text("What habit do you want to build?")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("e.g., Morning run, Drink water...", text: $name)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
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
            Text("Color")
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
        // Clear existing habits
        let descriptor = FetchDescriptor<Habit>()
        if let existingHabits = try? modelContext.fetch(descriptor) {
            for h in existingHabits {
                modelContext.delete(h)
            }
        }

        // Add new habit
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            color: selectedColor
        )
        modelContext.insert(habit)

        // Sync to iCloud
        CloudSyncManager.shared.saveHabits([HabitExport(from: habit)])

        dismiss()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Habit.self, inMemory: true)
}