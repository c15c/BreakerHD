import Foundation

enum StimulationKind: String, Codable, CaseIterable, Identifiable {
    case visual, choice, trivia, reaction, movement, anticipation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visual: return "Visual"
        case .choice: return "Quick choices"
        case .trivia: return "Trivia"
        case .reaction: return "Reaction"
        case .movement: return "Movement"
        case .anticipation: return "Anticipation"
        }
    }

    var icon: String {
        switch self {
        case .visual: return "sparkles"
        case .choice: return "arrow.triangle.branch"
        case .trivia: return "lightbulb.fill"
        case .reaction: return "bolt.fill"
        case .movement: return "iphone.gen3.radiowaves.left.and.right"
        case .anticipation: return "dice.fill"
        }
    }
}

struct EscapeEvent: Codable, Identifiable {
    let id: UUID
    let sessionID: UUID
    let occurredAt: Date
    let secondsIntoSession: TimeInterval
    let task: String
    let stimulation: StimulationKind
}

struct FocusSession: Codable, Identifiable {
    let id: UUID
    let task: String
    let startedAt: Date
    var endedAt: Date?
    var focusedSeconds: TimeInterval
    var escapeCount: Int
}

struct AppSettings: Codable {
    var selectedKinds: Set<StimulationKind> = Set(StimulationKind.allCases)
    var hapticsEnabled = true
    var soundsEnabled = true
    var proactiveNudgesEnabled = true
}

struct PersistedData: Codable {
    var settings = AppSettings()
    var sessions: [FocusSession] = []
    var events: [EscapeEvent] = []
    var hasOnboarded = false
}
