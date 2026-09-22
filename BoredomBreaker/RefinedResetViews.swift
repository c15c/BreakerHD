import SwiftUI
import UIKit

struct ResetExperienceView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        if store.activeResetVersion == .v1 {
            RewardContainerView(kind: store.activeReward)
        } else {
            RefinedResetContainerView(kind: store.activeRefinedReset)
        }
    }
}

struct RefinedResetContainerView: View {
    @EnvironmentObject private var store: AppStore
    let kind: RefinedResetKind
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("RESET · V2").font(.caption.weight(.black)).tracking(4).foregroundStyle(ink.opacity(0.45))
                Spacer()
            }
            Group {
                switch kind {
                case .resolve: ResolveResetView()
                case .cadence: CadenceResetView()
                case .perspective: PerspectiveResetView()
                case .observation: ObservationResetView()
                case .release: ReleaseResetView()
                case .aside: AsideResetView()
                }
            }.frame(maxHeight: .infinity)
            Button(returnLabel) { finish() }
                .buttonStyle(BigButtonStyle(color: ink, foreground: midnight))
        }
        .padding(24)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { _ in
                Task { @MainActor in finish() }
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    private var returnLabel: String {
        guard let task = store.currentSession?.task, !task.isEmpty else { return "RETURN TO IT" }
        let short = task.count > 24 ? String(task.prefix(22)) + "…" : task
        return "BACK TO \(short.uppercased())"
    }

    private func finish() {
        timer?.invalidate()
        store.returnToFocus()
    }
}

struct ResolveResetView: View {
    @EnvironmentObject private var store: AppStore
    @State private var resolved = false
    var body: some View {
        VStack(spacing: 36) {
            ZStack {
                ForEach(0..<9, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(i.isMultiple(of: 3) ? acid.opacity(0.8) : ink.opacity(0.24), lineWidth: 1.5)
                        .frame(width: CGFloat(64 + i * 22), height: CGFloat(64 + i * 22))
                        .offset(x: resolved ? 0 : CGFloat((i % 3) * 7 - 7), y: resolved ? 0 : CGFloat((i % 4) * 5 - 8))
                        .rotationEffect(.degrees(resolved ? 0 : Double(i * 3 - 11)))
                }
            }
            .frame(height: 300)
            .animation(.smooth(duration: 1.1), value: resolved)
            Text(resolved ? "ORDER RESTORED" : "TOUCH TO RESOLVE")
                .font(.caption.weight(.black)).tracking(3).foregroundStyle(ink.opacity(0.48))
        }
        .contentShape(Rectangle())
        .onTapGesture { resolved = true; store.impact(.medium) }
    }
}

struct CadenceResetView: View {
    @EnvironmentObject private var store: AppStore
    @State private var playing = false
    @State private var pulse = 0
    var body: some View {
        VStack(spacing: 34) {
            Circle()
                .stroke(ink.opacity(0.18), lineWidth: 1)
                .frame(width: 220, height: 220)
                .overlay(Circle().fill(acid.opacity(0.9)).frame(width: pulse.isMultiple(of: 2) ? 16 : 34, height: pulse.isMultiple(of: 2) ? 16 : 34))
                .animation(.easeOut(duration: 0.18), value: pulse)
            Text(playing ? "FEEL THE CADENCE" : "TOUCH ONCE")
                .font(.caption.weight(.black)).tracking(3).foregroundStyle(ink.opacity(0.48))
        }
        .contentShape(Rectangle())
        .onTapGesture { play() }
    }
    private func play() {
        guard !playing else { return }
        playing = true
        let beats: [(Double, UIImpactFeedbackGenerator.FeedbackStyle)] = [(0, .light), (0.32, .medium), (0.58, .light), (0.92, .heavy)]
        for (i, beat) in beats.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + beat.0) {
                pulse = i + 1; store.impact(beat.1)
            }
        }
    }
}

struct PerspectiveResetView: View {
    @State private var visible = false
    private let prompt = [
        "Picture this room from the ceiling.",
        "Imagine the task already finished.",
        "Notice how far away the nearest door is.",
        "For a moment, view the screen as an object."
    ].randomElement()!
    var body: some View {
        Text(prompt)
            .font(.system(size: 33, weight: .medium, design: .serif))
            .tracking(-0.4).multilineTextAlignment(.center).foregroundStyle(ink.opacity(0.9))
            .padding(24).opacity(visible ? 1 : 0).blur(radius: visible ? 0 : 8)
            .onAppear { withAnimation(.easeOut(duration: 1.2)) { visible = true } }
    }
}

struct ObservationResetView: View {
    @State private var revealed = false
    private let prompt = [
        "What was the last sound you noticed?",
        "Find the furthest visible object.",
        "Notice one thing casting a shadow.",
        "Find a colour you had ignored until now."
    ].randomElement()!
    var body: some View {
        VStack(spacing: 28) {
            Text(prompt).font(.system(size: 31, weight: .semibold, design: .rounded)).multilineTextAlignment(.center)
            Rectangle().fill(acid).frame(width: revealed ? 120 : 18, height: 2).animation(.easeInOut(duration: 1), value: revealed)
        }.onAppear { revealed = true }
    }
}

struct ReleaseResetView: View {
    @EnvironmentObject private var store: AppStore
    @State private var holding = false
    var body: some View {
        VStack(spacing: 34) {
            Circle()
                .fill(holding ? acid.opacity(0.16) : ink.opacity(0.06))
                .frame(width: holding ? 265 : 190, height: holding ? 265 : 190)
                .overlay(Circle().stroke(holding ? acid : ink.opacity(0.35), lineWidth: 1.5))
                .animation(.easeInOut(duration: 2.2), value: holding)
                .onLongPressGesture(minimumDuration: 1.8, pressing: { down in holding = down }, perform: { store.impact(.medium) })
            Text(holding ? "EXHALE" : "HOLD")
                .font(.caption.weight(.black)).tracking(4).foregroundStyle(ink.opacity(0.48))
        }
    }
}

struct AsideResetView: View {
    @State private var visible = false
    private let line = [
        "Your brain submitted a request to leave. Request noted.",
        "You may abandon the task after one more sentence. This offer renews.",
        "The urge to escape is not, technically, an instruction.",
        "Nothing new has happened elsewhere in the last eight seconds."
    ].randomElement()!
    var body: some View {
        VStack(spacing: 30) {
            Text("A BRIEF ADMINISTRATIVE NOTE").font(.caption2.weight(.black)).tracking(3).foregroundStyle(acid.opacity(0.7))
            Text(line).font(.system(size: 31, weight: .medium, design: .serif)).multilineTextAlignment(.center).lineSpacing(7)
        }.padding(20).opacity(visible ? 1 : 0).onAppear { withAnimation(.easeOut(duration: 0.7)) { visible = true } }
    }
}
