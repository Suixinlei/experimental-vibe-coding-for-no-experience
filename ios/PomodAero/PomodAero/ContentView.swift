//
//  ContentView.swift
//  PomodAero
//
//  Root container. Branches between first-run nickname setup and the main Flight UI.
//  Leaderboard is presented as a sheet.
//

import SwiftUI

struct ContentView: View {
    @Environment(IdentityStore.self) private var identity
    @State private var showLeaderboard = false

    var body: some View {
        Group {
            if identity.isOnboarded {
                FlightView(onShowLeaderboard: { showLeaderboard = true })
            } else {
                NicknameSetupView()
            }
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView(onClose: { showLeaderboard = false })
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(IdentityStore())
}
