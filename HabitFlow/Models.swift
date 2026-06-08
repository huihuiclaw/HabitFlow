import SwiftUI
import SwiftData

// MARK: - Goal Unit
enum HabitGoalUnit: String, Codable, CaseIterable {
    // Count units
    case piece = "piece"     // 次
    case group = "group"     // 组
    // Duration units
    case minute = "minute"   // 分钟
    case second = "second"   // 秒

    var isCountType: Bool {
        self == .piece || self == .group
    }

    var isDurationType: Bool {
        self == .minute || self == .second
    }
}

// MARK: - Habit Model (SwiftData)
@Model
class Habit {
    var id: UUID
    var name: String
    var icon: String
    var colorRaw: String
    var createdAt: Date
    var streakDays: Int
    var lastCompletedDate: Date?
    var completedDatesData: Data?
    var goalTarget: Int
    var goalUnitRaw: String

    init(id: UUID = UUID(), name: String, icon: String = "star.fill", color: HabitColor = .green, createdAt: Date = Date(), streakDays: Int = 0, lastCompletedDate: Date? = nil, goalTarget: Int = 1, goalUnit: HabitGoalUnit = .piece) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorRaw = color.rawValue
        self.createdAt = createdAt
        self.streakDays = streakDays
        self.lastCompletedDate = lastCompletedDate
        self.completedDatesData = nil
        self.goalTarget = goalTarget
        self.goalUnitRaw = goalUnit.rawValue
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRaw) ?? .green }
        set { colorRaw = newValue.rawValue }
    }

    var goalUnit: HabitGoalUnit {
        get { HabitGoalUnit(rawValue: goalUnitRaw) ?? .piece }
        set { goalUnitRaw = newValue.rawValue }
    }

    /// Get actual target value considering unit
    var effectiveGoalTarget: Int {
        return goalTarget
    }

    var goalUnitDisplay: String {
        switch goalUnit {
        case .piece: return "次"
        case .group: return "组"
        case .minute: return "分钟"
        case .second: return "秒"
        }
    }

    var completedDates: [Date] {
        get {
            guard let data = completedDatesData else { return [] }
            return (try? JSONDecoder().decode([Date].self, from: data)) ?? []
        }
        set {
            completedDatesData = try? JSONEncoder().encode(newValue)
        }
    }

    var isCompletedToday: Bool {
        guard let last = lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    var checkinCountToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return completedDates.filter { calendar.isDate($0, inSameDayAs: today) }.count
    }

    var isGoalCompletedToday: Bool {
        if goalUnit.isCountType {
            return checkinCountToday >= effectiveGoalTarget
        } else {
            return false // TODO: implement duration tracking
        }
    }
}

// MARK: - Habit Color
enum HabitColor: String, Codable, CaseIterable {
    case green, blue, orange, purple, pink

    var color: Color {
        switch self {
        case .green: return Color(hex: "34C759")
        case .blue: return Color(hex: "007AFF")
        case .orange: return Color(hex: "FF9500")
        case .purple: return Color(hex: "AF52DE")
        case .pink: return Color(hex: "FF2D55")
        }
    }

    var name: String {
        rawValue.capitalized
    }
}

// MARK: - Color Extension
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
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - Celebration Modifier
struct CelebrationModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        scale = 1.15
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            scale = 1.0
                        }
                    }
                }
            }
    }
}

extension View {
    func celebrate(trigger: Bool) -> some View {
        modifier(CelebrationModifier(trigger: trigger))
    }
}

// MARK: - Particle Effect
struct ParticleView: View {
    @State private var particles: [(id: Int, x: CGFloat, y: CGFloat, opacity: Double)] = []

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(Color(hex: "FFD60A"))
                    .frame(width: 8, height: 8)
                    .opacity(particle.opacity)
                    .offset(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            createParticles()
        }
    }

    private func createParticles() {
        for i in 0..<12 {
            let angle = Double(i) * 30 * .pi / 180
            let distance: CGFloat = 60
            particles.append((
                id: i,
                x: cos(angle) * distance,
                y: sin(angle) * distance,
                opacity: 1.0
            ))

            withAnimation(.easeOut(duration: 0.5).delay(Double(i) * 0.02)) {
                if i < particles.count {
                    particles[i].opacity = 0
                    particles[i].x = cos(angle) * distance * 1.5
                    particles[i].y = sin(angle) * distance * 1.5
                }
            }
        }
    }
}
