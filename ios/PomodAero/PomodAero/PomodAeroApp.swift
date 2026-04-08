//
//  PomodAeroApp.swift
//  PomodAero
//
//  App entry. Instantiates the shared IdentityStore and injects it into the
//  environment for all views to observe.
//

import SwiftUI

@main
struct PomodAeroApp: App {
    @State private var identity = IdentityStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(identity)
        }
    }
}
