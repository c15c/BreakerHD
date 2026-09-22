import SwiftUI

private let ink = Color(red: 0.96, green: 0.94, blue: 0.89)
private let acid = Color(red: 0.78, green: 1.00, blue: 0.24)
private let violet = Color(red: 0.55, green: 0.39, blue: 1.00)
private let midnight = Color(red: 0.035, green: 0.04, blue: 0.07)

struct ContentView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            midnight.ignoresSafeArea()
            switch store.screen {
            case .home:
                if store.data.hasOnboarded { HomeView() } else { OnboardingView() }
            case .focus: FocusView()
            case .reward: RewardContainerView(kind: store.activeReward)
            case .summary: SummaryView()
            case .settings: SettingsView()
            }
        }
        .foregroundStyle(ink)
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var page = 0
    @State private var selected = Set(StimulationKind.allCases)

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(violet.opacity(0.22)).frame(width: 150, height: 150)
                Image(systemName: page == 0 ? "brain.head.profile.fill" : "sparkles")
                    .font(.system(size: 64, weight: .black)).foregroundStyle(acid)
            }
            if page == 0 {
                Text("DON’T FIGHT THE URGE.")
                    .font(.system(size: 36, weight: .black, design: .rounded)).multilineTextAlignment(.center)
                Text("Give your brain somewhere safe to go for ten seconds — then get back to the thing.")
                    .font(.title3).foregroundStyle(ink.opacity(0.72)).multilineTextAlignment(.center)
            } else {
                Text("WHAT WAKES UP YOUR BRAIN?")
                    .font(.system(size: 30, weight: .black, design: .rounded)).multilineTextAlignment(.center)
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    ForEach(StimulationKind.allCases) { kind in
                        Button {
                            if selected.contains(kind) { selected.remove(kind) } else { selected.insert(kind) }
                        } label: {
                            VStack(spacing: 9) {
                                Image(systemName: kind.icon).font(.title2)
                                Text(kind.title).font(.subheadline.weight(.bold))
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(selected.contains(kind) ? acid : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                            .foregroundStyle(selected.contains(kind) ? midnight : ink)
                        }
                    }
                }
            }
            Spacer()
            Button(page == 0 ? "SHOW ME" : "LET’S GO") {
                if page == 0 { withAnimation(.snappy) { page = 1 } }
                else { store.completeOnboarding(kinds: selected) }
            }
            .buttonStyle(BigButtonStyle(color: acid, foreground: midnight))
        }
        .padding(24)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var task = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("BREAKER").font(.caption.weight(.black)).tracking(4).foregroundStyle(acid)
                    Text("HD").font(.system(size: 36, weight: .black, design: .rounded))
                }
                Spacer()
                Button { store.screen = .settings } label: {
                    Image(systemName: "slider.horizontal.3").font(.title2).padding(12)
                        .background(Color.white.opacity(0.08), in: Circle())
                }.foregroundStyle(ink)
            }
            Spacer()
            Text("What are you\nworking on?")
                .font(.system(size: 42, weight: .black, design: .rounded)).tracking(-1)
            TextField("Finish the proposal", text: $task, axis: .vertical)
                .font(.title2.weight(.semibold)).padding(20)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
                .focused($focused).submitLabel(.go).onSubmit { store.start(task: task) }
            Button("COOL. GO.") { store.start(task: task) }
                .buttonStyle(BigButtonStyle(color: task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.12) : acid, foreground: midnight))
                .disabled(task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Text("No lists. No streaks. No guilt. Just company while you do the thing.")
                .font(.footnote.weight(.medium)).foregroundStyle(ink.opacity(0.5)).multilineTextAlignment(.center).frame(maxWidth: .infinity)
            Spacer()
        }
        .padding(24)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focused = true } }
    }
}

struct FocusView: View {
    @EnvironmentObject private var store: AppStore
    @State private var confirmFinish = false

    var body: some View {
        ZStack {
            RadialGradient(colors: [violet.opacity(0.2), midnight], center: .center, startRadius: 10, endRadius: 390).ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Text("FOCUSING").font(.caption.weight(.black)).tracking(5).foregroundStyle(acid)
                    Spacer()
                    Button("FINISH") { confirmFinish = true }.font(.caption.weight(.black)).foregroundStyle(ink.opacity(0.65))
                }
                Spacer()
                Text(store.currentSession?.task ?? "")
                    .font(.system(size: 30, weight: .bold, design: .rounded)).multilineTextAlignment(.center).lineLimit(3)
                Text(store.formattedElapsed)
                    .font(.system(size: 64, weight: .black, design: .monospaced)).foregroundStyle(acid)
                    .contentTransition(.numericText())
                Text("focused").font(.subheadline.weight(.bold)).foregroundStyle(ink.opacity(0.5))
                Spacer()
                Button { store.requestReward() } label: {
                    VStack(spacing: 8) {
                        Text("I’M LOSING IT").font(.system(size: 24, weight: .black, design: .rounded))
                        Text("Give me 10 seconds").font(.caption.weight(.bold)).opacity(0.65)
                    }.frame(maxWidth: .infinity).frame(height: 116)
                }
                .buttonStyle(.plain).foregroundStyle(midnight)
                .background(acid, in: RoundedRectangle(cornerRadius: 30))
                .shadow(color: acid.opacity(0.2), radius: 24, y: 8)
                Text("I’m still here.").font(.footnote.weight(.bold)).foregroundStyle(ink.opacity(0.45))
            }.padding(24)

            if store.showNudge {
                Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { store.showNudge = false }
                VStack(spacing: 16) {
                    Text("YOU’RE GETTING ITCHY.").font(.title2.weight(.black)).multilineTextAlignment(.center)
                    Text("Want a tiny reset before your brain makes a run for it?").foregroundStyle(ink.opacity(0.65)).multilineTextAlignment(.center)
                    Button("GIVE ME 10 SECONDS") { store.requestReward() }.buttonStyle(BigButtonStyle(color: acid, foreground: midnight))
                    Button("I’M GOOD") { store.showNudge = false }.font(.subheadline.weight(.bold)).foregroundStyle(ink.opacity(0.6))
                }.padding(24).background(Color(red: 0.09, green: 0.09, blue: 0.14), in: RoundedRectangle(cornerRadius: 28)).padding(28)
            }
        }
        .confirmationDialog("End this focus session?", isPresented: $confirmFinish) {
            Button("Finish session") { store.finish() }
            Button("Discard session", role: .destructive) { store.cancelSession() }
            Button("Keep focusing", role: .cancel) {}
        }
    }
}

struct RewardContainerView: View {
    @EnvironmentObject private var store: AppStore
    let kind: StimulationKind
    @State private var secondsLeft = 10
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("TINY RESET").font(.caption.weight(.black)).tracking(4).foregroundStyle(acid)
                Spacer()
                Text("\(secondsLeft)").font(.title3.monospacedDigit().weight(.black)).foregroundStyle(ink.opacity(0.55))
            }
            Group {
                switch kind {
                case .visual: VisualBurstView()
                case .choice: ChoiceBurstView()
                case .trivia: TriviaBurstView()
                case .reaction: ReactionBurstView()
                case .movement: MovementBurstView()
                case .anticipation: AnticipationBurstView()
                }
            }.frame(maxHeight: .infinity)
            Button("OKAY. BACK TO IT.") { finish() }
                .buttonStyle(BigButtonStyle(color: acid, foreground: midnight))
        }
        .padding(24)
        .onAppear { startCountdown() }
        .onDisappear { timer?.invalidate() }
    }

    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                secondsLeft -= 1
                if secondsLeft <= 0 { finish() }
            }
        }
    }

    private func finish() {
        timer?.invalidate()
        store.returnToFocus()
    }
}

struct VisualBurstView: View {
    @State private var spin = false
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    Capsule().fill(i.isMultiple(of: 2) ? acid : violet)
                        .frame(width: 22, height: 120).offset(y: -90)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
                Circle().fill(midnight).frame(width: 115, height: 115)
                Image(systemName: "eye.fill").font(.system(size: 46)).foregroundStyle(ink)
            }.rotationEffect(.degrees(spin ? 360 : 0)).animation(.linear(duration: 2).repeatForever(autoreverses: false), value: spin)
            Text("LET YOUR EYES CHASE IT").font(.title2.weight(.black))
        }.onAppear { spin = true }
    }
}

struct ChoiceBurstView: View {
    @EnvironmentObject private var store: AppStore
    @State private var picked: String?
    private let pair = [("🦈", "🐊"), ("🌋", "🌊"), ("👽", "🤖"), ("⚡️", "🔥")].randomElement()!
    var body: some View {
        VStack(spacing: 28) {
            Text("NO THINKING. PICK ONE.").font(.title2.weight(.black))
            HStack(spacing: 16) {
                choice(pair.0); choice(pair.1)
            }
            Text(picked == nil ? "GO WITH YOUR GUT" : "CORRECT. OBVIOUSLY.")
                .font(.caption.weight(.black)).tracking(2).foregroundStyle(picked == nil ? ink.opacity(0.45) : acid)
        }
    }
    private func choice(_ emoji: String) -> some View {
        Button { picked = emoji; store.impact(.heavy) } label: {
            Text(emoji).font(.system(size: 72)).frame(maxWidth: .infinity).frame(height: 160)
                .background(picked == emoji ? violet : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 26))
        }
    }
}

struct TriviaBurstView: View {
    @State private var revealed = false
    private let card = [
        ("Which animal has fingerprints nearly identical to ours?", "KOALAS 🐨"),
        ("How many hearts does an octopus have?", "THREE 🐙"),
        ("What arrived first: sharks or trees?", "SHARKS 🦈"),
        ("What color is a polar bear’s skin?", "BLACK 🐻‍❄️")
    ].randomElement()!
    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "questionmark.bubble.fill").font(.system(size: 64)).foregroundStyle(violet)
            Text(card.0).font(.system(size: 28, weight: .black, design: .rounded)).multilineTextAlignment(.center)
            Button(revealed ? card.1 : "REVEAL") { withAnimation(.bouncy) { revealed = true } }
                .font(.title2.weight(.black)).foregroundStyle(revealed ? acid : ink).padding(20)
        }
    }
}

struct ReactionBurstView: View {
    @EnvironmentObject private var store: AppStore
    @State private var state = 0
    @State private var reaction: TimeInterval?
    @State private var start = Date()
    var body: some View {
        VStack(spacing: 26) {
            Text(state == 0 ? "WAIT FOR ACID" : state == 1 ? "TAP!" : "\(Int((reaction ?? 0) * 1000)) ms")
                .font(.system(size: 34, weight: .black, design: .rounded))
            Button {
                guard state == 1 else { return }
                reaction = Date().timeIntervalSince(start); state = 2; store.impact(.heavy)
            } label: {
                Circle().fill(state == 1 ? acid : violet.opacity(0.45)).frame(width: 210, height: 210)
                    .overlay(Image(systemName: state == 2 ? "checkmark" : "hand.tap.fill").font(.system(size: 64, weight: .black)).foregroundStyle(state == 1 ? midnight : ink))
            }
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.4...3.8)) {
                guard state == 0 else { return }; start = Date(); state = 1; store.tickSound()
            }
        }
    }
}

struct MovementBurstView: View {
    @EnvironmentObject private var store: AppStore
    @State private var taps = 0
    var body: some View {
        VStack(spacing: 26) {
            Image(systemName: taps >= 5 ? "checkmark.circle.fill" : "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 100)).foregroundStyle(taps >= 5 ? acid : violet).symbolEffect(.bounce, value: taps)
            Text(taps >= 5 ? "NICE." : "TAP 5 TIMES, FAST")
                .font(.system(size: 30, weight: .black, design: .rounded))
            HStack(spacing: 8) {
                ForEach(0..<5) { i in Circle().fill(i < taps ? acid : Color.white.opacity(0.12)).frame(width: 24, height: 24) }
            }
        }.contentShape(Rectangle()).onTapGesture {
            if taps < 5 { taps += 1; store.impact(.light) }
        }
    }
}

struct AnticipationBurstView: View {
    @EnvironmentObject private var store: AppStore
    @State private var rolling = false
    @State private var result = "?"
    private let symbols = ["⚡️", "🧠", "🛸", "🦖", "🍋", "👀"]
    var body: some View {
        VStack(spacing: 28) {
            Text("WHAT WILL YOU GET?").font(.title2.weight(.black))
            Text(result).font(.system(size: 110)).frame(width: 200, height: 200)
                .background(violet.opacity(0.22), in: RoundedRectangle(cornerRadius: 36))
                .rotationEffect(.degrees(rolling ? 8 : 0))
            Button(result == "?" ? "REVEAL" : "MYSTERY SOLVED") {
                guard result == "?" else { return }
                rolling = true
                for i in 0..<8 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                        result = symbols.randomElement()!; store.impact(.light)
                        if i == 7 { rolling = false }
                    }
                }
            }.font(.title3.weight(.black)).foregroundStyle(acid)
        }
    }
}

struct SummaryView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 88)).foregroundStyle(acid)
            Text("YOU DID THE THING.").font(.system(size: 34, weight: .black, design: .rounded)).multilineTextAlignment(.center)
            Text(store.currentSession?.task ?? "").font(.title3.weight(.semibold)).multilineTextAlignment(.center).foregroundStyle(ink.opacity(0.7))
            HStack(spacing: 12) {
                stat(store.formattedElapsed, "FOCUSED")
                stat("\(store.currentSession?.escapeCount ?? 0)", "TINY RESETS")
            }
            Text(store.escapeSignatureText).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center).foregroundStyle(ink.opacity(0.55)).padding(.horizontal)
            Spacer()
            Button("DONE") { store.closeSummary() }.buttonStyle(BigButtonStyle(color: acid, foreground: midnight))
        }.padding(24)
    }
    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 7) { Text(value).font(.title.weight(.black)); Text(label).font(.caption2.weight(.black)).tracking(1).foregroundStyle(ink.opacity(0.45)) }
            .frame(maxWidth: .infinity).padding(.vertical, 24).background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        NavigationStack {
            Form {
                Section("Tiny resets") {
                    ForEach(StimulationKind.allCases) { kind in
                        Toggle(isOn: Binding(get: { store.data.settings.selectedKinds.contains(kind) }, set: { on in
                            if on { store.data.settings.selectedKinds.insert(kind) } else { store.data.settings.selectedKinds.remove(kind) }; store.save()
                        })) { Label(kind.title, systemImage: kind.icon) }.tint(acid)
                    }
                }
                Section("Experience") {
                    Toggle("Haptics", isOn: binding(\.hapticsEnabled)).tint(acid)
                    Toggle("Sounds", isOn: binding(\.soundsEnabled)).tint(acid)
                    Toggle("Proactive nudges", isOn: binding(\.proactiveNudgesEnabled)).tint(acid)
                }
                Section("Your escape signature") { Text(store.escapeSignatureText) }
                Section { Text("Everything stays on this phone. Breaker HD is a focus aid, not medical treatment.").font(.footnote).foregroundStyle(.secondary) }
            }
            .scrollContentBackground(.hidden).background(midnight)
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { store.screen = .home }.foregroundStyle(acid) } }
        }
    }
    private func binding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(get: { store.data.settings[keyPath: keyPath] }, set: { store.data.settings[keyPath: keyPath] = $0; store.save() })
    }
}

struct BigButtonStyle: ButtonStyle {
    let color: Color
    let foreground: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 18, weight: .black, design: .rounded)).tracking(1)
            .frame(maxWidth: .infinity).padding(.vertical, 19)
            .background(color.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 20))
            .foregroundStyle(foreground).scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
