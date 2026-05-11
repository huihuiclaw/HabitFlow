import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: HabitStore

    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor: HabitColor = .green

    private let icons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "drop.fill", "sun.max.fill", "moon.fill",
        "figure.walk", "figure.run", "dumbbell.fill", "yoga.fill",
        "book.fill", "pencil", "brain.head.profile", "eye.fill",
        "cup.and.saucer.fill", "fork.knife", "bed.double.fill", "alarm.fill",
        "pill.fill", "drop.transfusion.fill", "lungs.fill", "heart.text.square.fill",
        "music.note", "paintbrush.fill", "camera.fill", "gamecontroller.fill"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Preview
                    previewSection

                    // Name Input
                    nameSection

                    // Icon Picker
                    iconSection

                    // Color Picker
                    colorSection

                    Spacer()
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

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

                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                            .foregroundStyle(.secondary)
                        Text("0 day streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(selectedColor.color, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(20)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habit Name")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("e.g., Morning run, Drink water...", text: $name)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Icon Section
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedIcon == icon ? selectedColor.color.opacity(0.2) : Color.clear)
                                .frame(width: 44, height: 44)

                            Image(systemName: icon)
                                .font(.system(size: 20))
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

    // MARK: - Color Section
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                                .frame(width: 44, height: 44)

                            if selectedColor == color {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
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

    // MARK: - Save
    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        store.addHabit(name: trimmedName, icon: selectedIcon, color: selectedColor)
        dismiss()
    }
}

#Preview {
    AddHabitView(store: HabitStore())
}