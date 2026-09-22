import Foundation
import SwiftUI
import UIKit
import AudioToolbox

@MainActor
final class AppStore: ObservableObject {
    enum Screen { case home, focus, reward, summary, settings }

    @Published var data: PersistedData
    @Published var screen: Screen = .home
    @Published var currentSession: FocusSession?
    @Published var now = Date()
    @Published var activeReward: StimulationKind = .visual
    @Published var showNudge = false

    private let storageKey = "BoredomBreaker.Data.v1"
    private var timer: Timer?
    private var lastNudgeSessionSecond: TimeInterval = -10_000

    init() {
        if let blob = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(PersistedData.self, from: blob) {
            data = decoded
        } else {
            data = PersistedData()
        }
    }

    var elapsed: TimeInterval {
        guard let session = currentSession else { return 0 }
        return max(0, now.timeIntervalSince(session.startedAt))
    }

    var formattedElapsed: String {
        let total = Int(elapsed)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    var medianEscapeSecond: TimeInterval? {
        let values = data.events.suffix(30).map(\.secondsIntoSession).sorted()
        guard values.count >= 3 else { return nil }
        let middle = values.count / 2
        return values.count.isMultiple(of: 2)
            ? (values[middle - 1] + values[middle]) / 2
            : values[middle]
    }

    var escapeSignatureText: String {
        guard let median = medianEscapeSecond else {
            return "Your escape signature will appear after a few focus sessions."
        }
        let low = max(1, Int(median / 60) - 2)
        let high = max(low + 1, Int(median / 60) + 2)
        return "Your distraction attempts tend to arrive around \(low)–\(high) minutes in."
    }

    func completeOnboarding(kinds: Set<StimulationKind>) {
        data.settings.selectedKinds = kinds.isEmpty ? Set(StimulationKind.allCases) : kinds
        data.hasOnboarded = true
        save()
    }

    func start(task: String) {
        let clean = task.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        currentSession = FocusSession(id: UUID(), task: clean, startedAt: Date(), endedAt: nil, focusedSeconds: 0, escapeCount: 0)
        now = Date()
        lastNudgeSessionSecond = -10_000
        showNudge = false
        screen = .focus
        startTimer()
        impact(.medium)
    }

    func requestReward() {
        guard var session = currentSession else { return }
        let options = data.settings.selectedKinds.isEmpty ? StimulationKind.allCases : Array(data.settings.selectedKinds)
        activeReward = options.randomElement() ?? .visual
        session.escapeCount += 1
        currentSession = session
        data.events.append(EscapeEvent(id: UUID(), sessionID: session.id, occurredAt: Date(), secondsIntoSession: elapsed, task: session.task, stimulation: activeReward))
        showNudge = false
        screen = .reward
        save()
        impact(.heavy)
    }

    func returnToFocus() {
        screen = .focus
        impact(.medium)
    }

    func finish() {
        guard var session = currentSession else { return }
        session.endedAt = Date()
        session.focusedSeconds = elapsed
        currentSession = session
        data.sessions.append(session)
        if data.sessions.count > 100 { data.sessions.removeFirst(data.sessions.count - 100) }
        save()
        stopTimer()
        screen = .summary
        successFeedback()
    }

    func closeSummary() {
        currentSession = nil
        screen = .home
    }

    func cancelSession() {
        stopTimer()
        currentSession = nil
        showNudge = false
        screen = .home
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.now = Date()
                self.checkForNudge()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForNudge() {
        guard screen == .focus,
              data.settings.proactiveNudgesEnabled,
              !showNudge,
              let median = medianEscapeSecond else { return }
        let target = max(60, median - 30)
        if elapsed >= target && elapsed - lastNudgeSessionSecond > 300 {
            lastNudgeSessionSecond = elapsed
            showNudge = true
            impact(.light)
        }
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard data.settings.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func successFeedback() {
        guard data.settings.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func tickSound() {
        guard data.settings.soundsEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
}
