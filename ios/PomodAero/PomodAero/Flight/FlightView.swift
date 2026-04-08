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

    var onShowLeaderboard: () -> Void = {}

    /// Local asset shown inside the porthole BEFORE a flight is started.
    /// Visual narrative: still at the HGH gate → take off → destination.
    /// In Assets.xcassets/HubAirport.imageset/.
    private static let idleHubAssetName = "HubAirport"

    var body: some View {
        ZStack {
            // Cabin wall — a warm, soft beige gradient evokes plane interior lighting.
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.13, blue: 0.18),
                    Color(red: 0.05, green: 0.07, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView()
                    .tint(.white)
                    .task {
                        let vm = FlightViewModel(identity: identity)
                        viewModel = vm
                        await vm.refreshIdleDestinations()
                    }
            }
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
        // Drive the countdown from SwiftUI's timeline.
        .task(id: phaseID(viewModel)) {
            // Only tick while inFlight; TimelineView below handles per-second updates.
        }
    }

    // MARK: - Porthole

    @ViewBuilder
    private func porthole(viewModel: FlightViewModel) -> some View {
        ZStack {
            // Inner scenery masked by the porthole shape.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                KenBurnsImage(source: backgroundSource(for: viewModel))
                    .onChange(of: context.date) { _, newDate in
                        Task { await viewModel.tick(now: newDate) }
                    }
            }
            .clipShape(PortholeShape())

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
    }

    private func backgroundSource(for viewModel: FlightViewModel) -> KenBurnsSource? {
        switch viewModel.phase {
        case .boarding(let f), .inFlight(let f, _), .landed(let f, _):
            // During flight: rotate through the destination's photos (loaded remotely).
            if let url = viewModel.currentImageURL ?? f.imageURLs.first {
                return .remote(url)
            }
            return nil
        case .idle, .loadingFlight, .error:
            // Pre-flight: show the airport hub from the app bundle (instant, no network).
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
                    Text("HGH → \(viewModel.idleDestination(at: context.date).uppercased())")
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Text("25:00")
                    .font(.system(size: 54, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

            case .loadingFlight:
                ProgressView()
                    .tint(.white)
                Text("正在分配登机口...")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))

            case .boarding(let f):
                Text("HGH → \(f.destination.uppercased())")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(f.code) · 登机中")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))

            case .inFlight(let f, _):
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
                bigLabel("起飞")
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

    private func bigLabel(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.15))
            )
            .foregroundStyle(.white)
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

#Preview {
    FlightView()
        .environment(IdentityStore())
}
