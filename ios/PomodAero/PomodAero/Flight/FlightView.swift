//
//  FlightView.swift
//  PomodAero
//
//  The main screen: airplane porthole window with live scenery behind it,
//  countdown timer below, and a single action button that cycles through
//  "起飞 → 提前降落 → 查看排名 → 再来一次".
//

import SwiftUI

struct FlightView: View {
    @Environment(IdentityStore.self) private var identity
    @State private var viewModel: FlightViewModel?
    @State private var ambientAnimating = false
    @State private var chromeFloating = false
    @State private var takeoffToken = 0
    @State private var landingToken = 0

    var onShowLeaderboard: () -> Void = {}

    /// Local asset shown inside the porthole BEFORE a flight is started.
    /// Visual narrative: still at the HGH gate → take off → destination.
    /// In Assets.xcassets/HubAirport.imageset/.
    private static let idleHubAssetName = "HubAirport"

    var body: some View {
        ZStack {
            CabinAmbientBackground(animating: ambientAnimating)
                .ignoresSafeArea()

            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView()
                    .tint(.white)
                    .task {
                        let vm = FlightViewModel(identity: identity)
                        viewModel = vm
                    }
            }
        }
        .task {
            guard !ambientAnimating else { return }
            ambientAnimating = true
            chromeFloating = true
        }
    }

    @ViewBuilder
    private func content(viewModel: FlightViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)

            // Porthole
            porthole(viewModel: viewModel)
                .aspectRatio(0.78, contentMode: .fit)
                .padding(.horizontal, 40)
                .shadow(color: .black.opacity(0.5), radius: 30, y: 12)

            // Flight label + countdown
            header(viewModel: viewModel)

            Spacer()

            // Primary action
            actionButton(viewModel: viewModel)
                .padding(.horizontal, 40)

            // Secondary action: leaderboard link
            Button {
                onShowLeaderboard()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                    Text("排行榜")
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)
        }
        .offset(y: chromeFloating ? -2 : 2)
        .animation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true), value: chromeFloating)
        .animation(.spring(response: 0.72, dampingFraction: 0.84), value: phaseID(viewModel))
        // Drive the countdown from SwiftUI's timeline.
        .task(id: phaseID(viewModel)) {
            switch viewModel.phase {
            case .boarding:
                takeoffToken += 1
            case .landed:
                landingToken += 1
            default:
                break
            }
        }
        .task {
            await viewModel.ensureIdleFlightsLoaded()
        }
    }

    // MARK: - Porthole

    @ViewBuilder
    private func porthole(viewModel: FlightViewModel) -> some View {
        ZStack {
            // Inner scenery masked by the porthole shape.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                KenBurnsImage(source: backgroundSource(for: viewModel, at: context.date))
                    .onChange(of: context.date) { _, newDate in
                        Task { await viewModel.tick(now: newDate) }
                    }
            }
            .clipShape(PortholeShape())

            PortholeAtmosphere(animating: ambientAnimating)
                .clipShape(PortholeShape())
                .allowsHitTesting(false)

            FlightPhaseOverlay(phaseID: phaseID(viewModel), animating: ambientAnimating)
                .clipShape(PortholeShape())
                .allowsHitTesting(false)

            PortholeFlightTransition(kind: .takeoff, token: takeoffToken)
                .clipShape(PortholeShape())
                .allowsHitTesting(false)

            PortholeFlightTransition(kind: .landing, token: landingToken)
                .clipShape(PortholeShape())
                .allowsHitTesting(false)

            // Decorative metal ring around the window.
            PortholeShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.55),
                            .white.opacity(0.08),
                            .white.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 8
                )
                .shadow(color: .white.opacity(0.3), radius: 2)

            // Outer dark bezel simulating cabin wall cutout.
            PortholeShape()
                .stroke(Color.black.opacity(0.6), lineWidth: 24)
                .blur(radius: 8)
                .blendMode(.multiply)
        }
        .scaleEffect(portholeScale(for: viewModel))
        .rotationEffect(.degrees(portholeTilt(for: viewModel)))
        .animation(.spring(response: 0.9, dampingFraction: 0.82), value: phaseID(viewModel))
    }

    private func backgroundSource(for viewModel: FlightViewModel, at date: Date) -> KenBurnsSource? {
        switch viewModel.phase {
        case .boarding(let f), .inFlight(let f, _), .landed(let f, _):
            // During flight: rotate through the destination's photos (loaded remotely).
            if let url = viewModel.currentImageURL ?? f.imageURLs.first {
                return .remote(url)
            }
            return nil
        case .idle, .loadingFlight, .error:
            if let url = viewModel.idleImageURL(at: date) {
                return .remote(url)
            }
            return .asset(Self.idleHubAssetName)
        }
    }

    // MARK: - Header (flight code + countdown)

    @ViewBuilder
    private func header(viewModel: FlightViewModel) -> some View {
        VStack(spacing: 6) {
            switch viewModel.phase {
            case .idle:
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 8) {
                        Text("HGH → \(viewModel.idleDestination(at: context.date).uppercased())")
                            .font(.system(.title3, design: .rounded).weight(.medium))
                            .foregroundStyle(.white.opacity(0.78))
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.55), value: viewModel.idleDestination(at: context.date))

                        Capsule()
                            .fill(.white.opacity(0.18))
                            .frame(width: 62, height: 4)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.55))
                                    .frame(width: 22, height: 4)
                                    .offset(x: chromeFloating ? 38 : 0)
                                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: chromeFloating)
                            }
                    }
                }
                Text("25:00")
                    .font(.system(size: 54, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("目的地与舷窗每 5 秒同步轮播")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.48))

            case .loadingFlight:
                phaseBadge(
                    title: "地勤协同中",
                    systemImage: "dot.radiowaves.left.and.right",
                    tint: Color(red: 0.56, green: 0.78, blue: 1.0)
                )
                ProgressView()
                    .tint(.white)
                Text("正在分配登机口...")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))

            case .boarding(let f):
                phaseBadge(
                    title: "登机推进",
                    systemImage: "airplane.departure",
                    tint: Color(red: 1.0, green: 0.77, blue: 0.56)
                )
                Text("HGH → \(f.destination.uppercased())")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(f.code) · 登机中")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))

            case .inFlight(let f, _):
                phaseBadge(
                    title: "巡航进行中",
                    systemImage: "sparkles",
                    tint: Color(red: 0.62, green: 0.88, blue: 0.76)
                )
                Text("HGH → \(f.destination.uppercased())")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text(viewModel.countdownLabel)
                    .font(.system(size: 54, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("\(f.code) · 飞行中")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))

            case .landed(let f, let session):
                phaseBadge(
                    title: "平稳着陆",
                    systemImage: "checkmark.circle.fill",
                    tint: Color(red: 0.71, green: 0.93, blue: 0.67)
                )
                Text("降落 \(f.destination.uppercased())")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                Text("累计 \(session.focusMinutes) 分钟")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))

            case .error(let msg):
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Action button

    @ViewBuilder
    private func actionButton(viewModel: FlightViewModel) -> some View {
        switch viewModel.phase {
        case .idle, .error:
            Button {
                Task { await viewModel.startFlight() }
            } label: {
                bigLabel("起飞", emphasize: true)
            }
        case .loadingFlight, .boarding:
            Button {} label: {
                bigLabel("准备中...")
            }
            .disabled(true)
        case .inFlight:
            Button(role: .destructive) {
                viewModel.abort()
            } label: {
                bigLabel("中止飞行")
            }
        case .landed:
            HStack(spacing: 12) {
                Button {
                    viewModel.dismissLanded()
                } label: {
                    bigLabel("再来一次")
                }
                Button {
                    onShowLeaderboard()
                } label: {
                    bigLabel("查看排名")
                        .foregroundStyle(.black)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func bigLabel(_ text: String, emphasize: Bool = false) -> some View {
        Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(emphasize ? .white.opacity(0.2) : .white.opacity(0.15))
            )
            .foregroundStyle(.white)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(emphasize ? 0.25 : 0.08), lineWidth: 1)
            }
            .shadow(color: emphasize ? .white.opacity(0.12) : .clear, radius: 18, y: 6)
            .scaleEffect(emphasize && ambientAnimating ? 1.025 : 0.985)
            .animation(
                emphasize
                    ? .easeInOut(duration: 1.45).repeatForever(autoreverses: true)
                    : .default,
                value: ambientAnimating
            )
    }

    @ViewBuilder
    private func phaseBadge(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white.opacity(0.95))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.2))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(tint.opacity(0.45), lineWidth: 1)
                }
        )
        .shadow(color: tint.opacity(0.18), radius: 14, y: 4)
    }

    private func portholeScale(for viewModel: FlightViewModel) -> CGFloat {
        switch viewModel.phase {
        case .idle:
            return 1.0
        case .loadingFlight:
            return 0.985
        case .boarding:
            return 1.03
        case .inFlight:
            return 1.015
        case .landed:
            return 1.01
        case .error:
            return 0.99
        }
    }

    private func portholeTilt(for viewModel: FlightViewModel) -> Double {
        switch viewModel.phase {
        case .boarding:
            return 0.8
        case .inFlight:
            return -0.35
        default:
            return 0
        }
    }

    /// Stable id so .task(id:) fires at phase transitions.
    private func phaseID(_ vm: FlightViewModel) -> String {
        switch vm.phase {
        case .idle: return "idle"
        case .loadingFlight: return "loading"
        case .boarding: return "boarding"
        case .inFlight: return "inflight"
        case .landed: return "landed"
        case .error: return "error"
        }
    }
}

private struct CabinAmbientBackground: View {
    let animating: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.13, blue: 0.18),
                    Color(red: 0.05, green: 0.07, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color(red: 0.95, green: 0.76, blue: 0.53).opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 18)
                .offset(x: animating ? -120 : -30, y: animating ? -260 : -170)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animating)

            Circle()
                .fill(Color(red: 0.36, green: 0.58, blue: 0.95).opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 22)
                .offset(x: animating ? 140 : 60, y: animating ? -10 : 80)
                .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true), value: animating)

            Circle()
                .fill(Color(red: 0.98, green: 0.49, blue: 0.36).opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 22)
                .offset(x: animating ? 110 : 30, y: animating ? 260 : 180)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animating)
        }
    }
}

private struct PortholeAtmosphere: View {
    let animating: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(.white.opacity(0.09))
                .frame(width: 170, height: 84)
                .blur(radius: 20)
                .offset(x: animating ? -56 : -12, y: animating ? -104 : -72)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animating)

            Ellipse()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.62).opacity(0.1))
                .frame(width: 130, height: 130)
                .blur(radius: 26)
                .offset(x: animating ? 44 : 84, y: animating ? 74 : 36)
                .animation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true), value: animating)
        }
        .blendMode(.screen)
    }
}

private struct FlightPhaseOverlay: View {
    let phaseID: String
    let animating: Bool

    var body: some View {
        ZStack {
            switch phaseID {
            case "boarding":
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.12),
                        Color.orange.opacity(0.18)
                    ],
                    startPoint: animating ? .topLeading : .bottomTrailing,
                    endPoint: animating ? .bottomTrailing : .topLeading
                )
                .blur(radius: 8)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animating)

            case "inflight":
                RadialGradient(
                    colors: [
                        Color.cyan.opacity(0.16),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 30,
                    endRadius: 220
                )

            case "landed":
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.16),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )

            default:
                EmptyView()
            }
        }
    }
}

private struct PortholeFlightTransition: View {
    enum Kind {
        case takeoff
        case landing
    }

    let kind: Kind
    let token: Int

    @State private var progress = 0.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if token > 0 && progress < 1 {
                    flash(in: geo.size)
                    streak(in: geo.size)
                    airplane(in: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                runAnimation()
            }
            .onChange(of: token) { _, _ in
                runAnimation()
            }
        }
    }

    @ViewBuilder
    private func streak(in size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(kind == .takeoff ? 0.18 : 0.22),
                        Color(red: 1.0, green: 0.83, blue: 0.62).opacity(kind == .takeoff ? 0.28 : 0.14),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size.width * 1.2, height: size.height * 0.28)
            .rotationEffect(.degrees(kind == .takeoff ? -28 : 26))
            .blur(radius: 18)
            .offset(streakOffset(in: size))
            .opacity(kind == .takeoff ? (1 - progress) * 0.95 : progress < 0.18 ? progress / 0.18 : (1 - progress) * 0.9)
    }

    @ViewBuilder
    private func airplane(in size: CGSize) -> some View {
        Image(systemName: kind == .takeoff ? "airplane" : "airplane.circle.fill")
            .font(.system(size: kind == .takeoff ? 62 : 56, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        .white,
                        Color(red: 0.96, green: 0.86, blue: 0.68)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .rotationEffect(.degrees(kind == .takeoff ? -24 + progress * 10 : 10 - progress * 34))
            .scaleEffect(kind == .takeoff ? 0.92 + progress * 0.5 : 1.25 - progress * 0.36)
            .shadow(color: .white.opacity(0.28), radius: 22, y: 8)
            .offset(planeOffset(in: size))
            .opacity(kind == .takeoff ? 1 - progress * 0.82 : progress < 0.14 ? progress / 0.14 : 1 - max(0, progress - 0.66) / 0.34)
    }

    @ViewBuilder
    private func flash(in size: CGSize) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(kind == .takeoff ? 0.34 : 0.22),
                        .white.opacity(0.08),
                        .clear
                    ],
                    center: .center,
                    startRadius: 8,
                    endRadius: size.width * 0.44
                )
            )
            .frame(width: size.width * 0.76, height: size.width * 0.76)
            .offset(planeOffset(in: size))
            .scaleEffect(kind == .takeoff ? 0.7 + progress * 0.9 : 0.92 + progress * 0.45)
            .opacity(kind == .takeoff ? (1 - progress) * 0.7 : progress < 0.2 ? progress / 0.2 : (1 - progress) * 0.45)
            .blur(radius: 10)
    }

    private func planeOffset(in size: CGSize) -> CGSize {
        switch kind {
        case .takeoff:
            let start = CGSize(width: -size.width * 0.48, height: size.height * 0.3)
            let end = CGSize(width: size.width * 0.34, height: -size.height * 0.28)
            return interpolate(from: start, to: end, progress: progress)
        case .landing:
            let start = CGSize(width: size.width * 0.38, height: -size.height * 0.24)
            let end = CGSize(width: -size.width * 0.1, height: size.height * 0.26)
            return interpolate(from: start, to: end, progress: progress)
        }
    }

    private func streakOffset(in size: CGSize) -> CGSize {
        switch kind {
        case .takeoff:
            let start = CGSize(width: -size.width * 0.52, height: size.height * 0.24)
            let end = CGSize(width: size.width * 0.18, height: -size.height * 0.18)
            return interpolate(from: start, to: end, progress: progress)
        case .landing:
            let start = CGSize(width: size.width * 0.3, height: -size.height * 0.14)
            let end = CGSize(width: -size.width * 0.26, height: size.height * 0.22)
            return interpolate(from: start, to: end, progress: progress)
        }
    }

    private func interpolate(from: CGSize, to: CGSize, progress: Double) -> CGSize {
        CGSize(
            width: from.width + (to.width - from.width) * progress,
            height: from.height + (to.height - from.height) * progress
        )
    }

    private func runAnimation() {
        progress = 0
        withAnimation(kind == .takeoff
            ? .easeOut(duration: 1.25)
            : .timingCurve(0.22, 0.9, 0.28, 1.0, duration: 1.4)
        ) {
            progress = 1
        }
    }
}

#Preview {
    FlightView()
        .environment(IdentityStore())
}
