//
//  APIModels.swift
//  PomodAero
//
//  Codable mirrors of the backend Elysia `t.Object()` schemas.
//  Keep field names identical to backend snake_case — use CodingKeys to translate
//  to Swift camelCase at the struct level.
//
//  All types here are `nonisolated` because the project default is
//  -default-isolation=MainActor, which would otherwise make their Codable
//  conformance MainActor-bound and unusable from APIClient (also nonisolated).
//

import Foundation

// MARK: - Flight

nonisolated struct Flight: Codable, Sendable, Equatable {
    let code: String
    let destination: String
    let country: String
    let durationHours: Int
    let imageURLs: [URL]

    enum CodingKeys: String, CodingKey {
        case code, destination, country
        case durationHours = "duration_h"
        case imageURLs = "image_urls"
    }
}

// MARK: - User

nonisolated struct APIUser: Codable, Sendable, Equatable {
    let uuid: String
    let nickname: String
    let createdAt: String
    let lastSeenAt: String

    enum CodingKeys: String, CodingKey {
        case uuid, nickname
        case createdAt = "created_at"
        case lastSeenAt = "last_seen_at"
    }
}

nonisolated struct UserEnsureBody: Codable, Sendable {
    let uuid: String
    let nickname: String
}

// MARK: - Session

nonisolated struct SessionCreateBody: Codable, Sendable {
    let userUUID: String
    let flightCode: String
    let destination: String
    let startedAt: String  // ISO-8601 UTC
    let completedAt: String
    let focusMinutes: Int

    enum CodingKeys: String, CodingKey {
        case userUUID = "user_uuid"
        case flightCode = "flight_code"
        case destination
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case focusMinutes = "focus_minutes"
    }
}

nonisolated struct APISession: Codable, Sendable, Equatable {
    let id: Int
    let userUUID: String
    let flightCode: String
    let destination: String
    let startedAt: String
    let completedAt: String
    let focusMinutes: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userUUID = "user_uuid"
        case flightCode = "flight_code"
        case destination
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case focusMinutes = "focus_minutes"
    }
}

// MARK: - Leaderboard

nonisolated enum LeaderboardPeriod: String, Codable, Sendable, CaseIterable, Identifiable {
    case today
    case all
    var id: String { rawValue }
    var label: String {
        switch self {
        case .today: return "Today"
        case .all: return "All-time"
        }
    }
}

nonisolated struct LeaderboardEntry: Codable, Sendable, Equatable, Identifiable {
    let rank: Int
    let userUUID: String
    let nickname: String
    let totalMinutes: Int
    let sessionCount: Int

    // Identifiable for SwiftUI lists
    var id: String { userUUID }

    enum CodingKeys: String, CodingKey {
        case rank
        case userUUID = "user_uuid"
        case nickname
        case totalMinutes = "total_minutes"
        case sessionCount = "session_count"
    }
}

// MARK: - API error envelope

nonisolated struct APIErrorBody: Codable, Sendable {
    let message: String
}
