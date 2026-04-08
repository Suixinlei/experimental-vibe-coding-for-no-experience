//
//  FlightViewModel.swift
//  PomodAero
//
//  State machine for a single focus flight:
//
//    idle → loadingFlight → boarding → inFlight → landed → idle
//                                          ↓
//                                      aborted
//
//  Why a single VM covers the whole flow (not per-screen VMs):
//  The flight is ONE continuous user journey. Splitting it would force us to pass
//  state across views or create a coordinator. @Observable + a state enum is simpler
//  and matches how SwiftUI wants you to model this.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class FlightViewModel {
    private static let fallbackIdleDestinations = [
        "Bangkok",
        "Tokyo",
        "Singapore",
        "Paris",
        "Reykjavik",
        "New York",
        "Sydney",
        "Dubai",
        "Seoul",
        "Santorini",
        "Florence",
        "Rome",
    ]
    private static let idleRotationSeconds = 5

    // MARK: - State machine

    enum Phase: Equatable {
        case idle
        case loadingFlight
        case boarding(Flight)          // flight selected, porthole opening animation running
        case inFlight(Flight, startedAt: Date)
        case landed(Flight, session: APISession)
        case error(String)
    }

    private(set) var phase: Phase = .idle

    /// Remaining seconds in the current flight. Updated every 1s by `tick()`.
    private(set) var remainingSeconds: Int

    /// The currently displayed background image URL. Rotates every few seconds during flight.
    private(set) var currentImageURL: URL?
    private(set) var idleDestinations: [String]
    private(set) var idleFlights: [Flight]

    // MARK: - Config

    /// V0.1: fixed 25-minute focus. Change here once the product allows configurable lengths.
    static let totalFocusMinutes: Int = 25
    static let totalFocusSeconds: Int = totalFocusMinutes * 60

    /// Rotate background image every this-many seconds during flight.
    private let imageRotationSeconds: Int = 90

    // MARK: - Dependencies

    private let api: APIClient
    private let identity: IdentityStore

    init(api: APIClient = .shared, identity: IdentityStore) {
        self.api = api
        self.identity = identity
        self.remainingSeconds = FlightViewModel.totalFocusSeconds
        self.idleDestinations = Self.fallbackIdleDestinations
        self.idleFlights = []
    }

    // MARK: - Intents

    func startFlight() async {
        phase = .loadingFlight
        do {
            let flight = try await api.randomFlight()
            currentImageURL = flight.imageURLs.first
            phase = .boarding(flight)

            // Give the porthole a moment to "open" before the countdown begins.
            try? await Task.sleep(for: .milliseconds(800))

            // Guard: user may have bailed during the sleep.
            if case .boarding(let f) = phase, f == flight {
                phase = .inFlight(flight, startedAt: Date())
                remainingSeconds = Self.totalFocusSeconds
            }
        } catch {
            phase = .error((error as? LocalizedError)?.errorDescription ?? "航班没能起飞")
        }
    }

    /// Called by the parent view every 1s via TimelineView.
    func tick(now: Date) async {
        guard case .inFlight(let flight, let startedAt) = phase else { return }

        let elapsed = Int(now.timeIntervalSince(startedAt))
        let remaining = max(0, Self.totalFocusSeconds - elapsed)
        self.remainingSeconds = remaining

        // Rotate background images roughly every imageRotationSeconds.
        if !flight.imageURLs.isEmpty {
            let idx = (elapsed / imageRotationSeconds) % flight.imageURLs.count
            let next = flight.imageURLs[idx]
            if next != currentImageURL {
                currentImageURL = next
            }
        }

        if remaining <= 0 {
            await landed(flight: flight, startedAt: startedAt)
        }
    }

    func abort() {
        phase = .idle
        remainingSeconds = Self.totalFocusSeconds
    }

    func dismissLanded() {
        phase = .idle
        remainingSeconds = Self.totalFocusSeconds
    }

    func ensureIdleFlightsLoaded() async {
        while idleFlights.isEmpty && !Task.isCancelled {
            await refreshIdleDestinations()
            if idleFlights.isEmpty {
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    func refreshIdleDestinations() async {
        do {
            let flights = try await api.allFlights()
            idleFlights = flights
            let destinations = flights.map(\.destination)
            let uniqueDestinations = destinations.reduce(into: [String]()) { acc, destination in
                if !acc.contains(destination) {
                    acc.append(destination)
                }
            }
            if !uniqueDestinations.isEmpty {
                idleDestinations = uniqueDestinations
            }
        } catch {
            // Keep the fallback list; idle copy should never block the main flow.
        }
    }

    // MARK: - Private

    private func landed(flight: Flight, startedAt: Date) async {
        let completedAt = Date()
        let body = SessionCreateBody(
            userUUID: identity.deviceUUID,
            flightCode: flight.code,
            destination: flight.destination,
            startedAt: ISO8601.string(from: startedAt),
            completedAt: ISO8601.string(from: completedAt),
            focusMinutes: Self.totalFocusMinutes
        )
        do {
            let session = try await api.createSession(body)
            phase = .landed(flight, session: session)
        } catch {
            phase = .error("上报失败: \((error as? LocalizedError)?.errorDescription ?? "未知错误")")
        }
    }

    // MARK: - Derived

    var countdownLabel: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    func idleDestination(at date: Date) -> String {
        if let flight = idleFlight(at: date) {
            return flight.destination
        }
        guard !idleDestinations.isEmpty else { return "???" }
        let index = Int(date.timeIntervalSinceReferenceDate / Double(Self.idleRotationSeconds)) % idleDestinations.count
        return idleDestinations[index]
    }

    func idleImageURL(at date: Date) -> URL? {
        guard let flight = idleFlight(at: date), !flight.imageURLs.isEmpty else { return nil }
        let bucket = Int(date.timeIntervalSinceReferenceDate / Double(Self.idleRotationSeconds))
        return flight.imageURLs[bucket % flight.imageURLs.count]
    }

    private func idleFlight(at date: Date) -> Flight? {
        guard !idleFlights.isEmpty else { return nil }
        let bucket = Int(date.timeIntervalSinceReferenceDate / Double(Self.idleRotationSeconds))
        return idleFlights[bucket % idleFlights.count]
    }
}
