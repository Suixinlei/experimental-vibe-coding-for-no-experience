//
//  LeaderboardView.swift
//  PomodAero
//
//  Leaderboard UI: a segmented picker (Today / All-time) and a scrollable list.
//  Pull-to-refresh reloads the selected period.
//

import SwiftUI

@Observable
@MainActor
final class LeaderboardViewModel {
    private(set) var entries: [LeaderboardEntry] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var period: LeaderboardPeriod = .today {
        didSet { Task { await load() } }
    }

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            entries = try await api.leaderboard(period: period, limit: 50)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "加载失败"
        }
    }
}

struct LeaderboardView: View {
    @Environment(IdentityStore.self) private var identity
    @State private var viewModel = LeaderboardViewModel()
    var onClose: () -> Void = {}

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("排行榜")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    // Spacer to balance the close button.
                    Color.clear.frame(width: 44, height: 44)
                }

                // Period picker
                Picker("Period", selection: $viewModel.period) {
                    ForEach(LeaderboardPeriod.allCases) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .colorScheme(.dark)

                // List
                if viewModel.isLoading && viewModel.entries.isEmpty {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage, viewModel.entries.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Text(errorMessage)
                            .foregroundStyle(.red.opacity(0.9))
                        Button("重试") { Task { await viewModel.load() } }
                            .foregroundStyle(.white)
                    }
                    Spacer()
                } else if viewModel.entries.isEmpty {
                    Spacer()
                    Text("还没有人完成航班")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.entries) { entry in
                                row(for: entry)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private func row(for entry: LeaderboardEntry) -> some View {
        let isMe = entry.userUUID == identity.deviceUUID
        HStack(spacing: 16) {
            Text("\(entry.rank)")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(rankColor(entry.rank))
                .frame(width: 36, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.nickname)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(entry.sessionCount) 次飞行")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Text("\(entry.totalMinutes) 分")
                .font(.system(.title3, design: .rounded).weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isMe ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
        )
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.82, blue: 0.25)
        case 2: return Color(red: 0.82, green: 0.82, blue: 0.88)
        case 3: return Color(red: 0.80, green: 0.53, blue: 0.25)
        default: return .white.opacity(0.5)
        }
    }
}

#Preview {
    LeaderboardView()
        .environment(IdentityStore())
}
