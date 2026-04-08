//
//  IdentityStore.swift
//  PomodAero
//
//  Anonymous device identity. UUID is generated once on first launch and persisted
//  forever in UserDefaults. Nickname is set by the user on first launch, can be
//  changed later (V0.2+).
//

import Foundation
import SwiftUI

@Observable
final class IdentityStore {
    // Keys into UserDefaults
    private enum Keys {
        static let uuid = "pomodaero.device.uuid"
        static let nickname = "pomodaero.device.nickname"
    }

    private let defaults: UserDefaults

    // Observable state
    private(set) var deviceUUID: String
    var nickname: String?
    /// True once the user has entered a nickname (first-run onboarding gate).
    var isOnboarded: Bool { (nickname?.isEmpty == false) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load or mint a UUID. This must happen exactly once per install.
        if let existing = defaults.string(forKey: Keys.uuid) {
            self.deviceUUID = existing
        } else {
            let fresh = UUID().uuidString
            defaults.set(fresh, forKey: Keys.uuid)
            self.deviceUUID = fresh
        }

        self.nickname = defaults.string(forKey: Keys.nickname)
    }

    /// Save a new nickname locally and push it to the server. Throws API errors.
    @MainActor
    func setNickname(_ new: String, api: APIClient = .shared) async throws {
        let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Push first — if the server rejects it, don't persist locally.
        _ = try await api.ensureUser(uuid: deviceUUID, nickname: trimmed)

        defaults.set(trimmed, forKey: Keys.nickname)
        self.nickname = trimmed
    }
}
