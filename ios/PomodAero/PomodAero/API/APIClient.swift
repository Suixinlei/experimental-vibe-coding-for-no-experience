//
//  APIClient.swift
//  PomodAero
//
//  Thin URLSession-based API client. Async/await, Codable, no third-party deps.
//  When V0.1 grows past ~6 endpoints, consider swapping for swift-openapi-generator
//  codegen against the backend's /openapi/json. See TD-004 in docs/exec-plans/tech-debt-tracker.md.
//

import Foundation

// MARK: - Error type

enum APIError: Error, LocalizedError {
    case invalidURL
    case transport(URLError)
    case decoding(DecodingError)
    case server(status: Int, message: String?)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .transport(let e): return "Network: \(e.localizedDescription)"
        case .decoding(let e): return "Decoding: \(e.localizedDescription)"
        case .server(let status, let message):
            return "Server \(status)\(message.map { ": \($0)" } ?? "")"
        case .unknown(let e): return e.localizedDescription
        }
    }
}

// MARK: - Client

// Explicitly nonisolated: this Xcode 26 project uses -default-isolation=MainActor,
// but APIClient has no mutable state — binding it to MainActor would force every
// HTTP call to hop actors and make `.shared` unusable as a default argument.
nonisolated final class APIClient: Sendable {
    // For V0.1 we target a backend running on the same LAN as the device.
    // This should become a build-config-provided URL once we have env-specific configs.
    static let shared = APIClient(baseURL: URL(string: "http://192.168.30.20:3000")!)

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Endpoints

    func ensureUser(uuid: String, nickname: String) async throws -> APIUser {
        try await post(
            path: "/users/ensure",
            body: UserEnsureBody(uuid: uuid, nickname: nickname),
            responseType: APIUser.self
        )
    }

    func randomFlight() async throws -> Flight {
        try await get(path: "/flights/random", responseType: Flight.self)
    }

    func createSession(_ body: SessionCreateBody) async throws -> APISession {
        try await post(path: "/sessions", body: body, responseType: APISession.self)
    }

    func leaderboard(period: LeaderboardPeriod, limit: Int = 50) async throws -> [LeaderboardEntry] {
        try await get(
            path: "/leaderboard",
            query: ["period": period.rawValue, "limit": String(limit)],
            responseType: [LeaderboardEntry].self
        )
    }

    // MARK: - Transport

    private func get<Response: Decodable>(
        path: String,
        query: [String: String] = [:],
        responseType: Response.Type
    ) async throws -> Response {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        if !query.isEmpty {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await perform(request: request)
    }

    private func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        responseType: Response.Type
    ) async throws -> Response {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await perform(request: request)
    }

    private func perform<Response: Decodable>(request: URLRequest) async throws -> Response {
        let (data, urlResponse): (Data, URLResponse)
        do {
            (data, urlResponse) = try await session.data(for: request)
        } catch let e as URLError {
            throw APIError.transport(e)
        } catch {
            throw APIError.unknown(error)
        }

        guard let http = urlResponse as? HTTPURLResponse else {
            throw APIError.server(status: -1, message: "not an HTTP response")
        }

        guard (200..<300).contains(http.statusCode) else {
            // Server error envelope is { "message": "..." } for our custom errors,
            // but Elysia validation errors have a richer shape — we only surface .message.
            let message = (try? decoder.decode(APIErrorBody.self, from: data))?.message
            throw APIError.server(status: http.statusCode, message: message)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch let e as DecodingError {
            throw APIError.decoding(e)
        } catch {
            throw APIError.unknown(error)
        }
    }
}

// MARK: - ISO-8601 helper used by view models when building SessionCreateBody

enum ISO8601 {
    /// `2026-04-08T12:25:00Z` style. Backend expects `format: date-time`.
    static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }
}
