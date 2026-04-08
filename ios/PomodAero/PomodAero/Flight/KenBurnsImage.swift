//
//  KenBurnsImage.swift
//  PomodAero
//
//  AsyncImage with a slow Ken-Burns effect (pan + zoom) to give the still image
//  a "motion" feel — the cheapest possible approximation of watching the world
//  drift by from an airplane window.
//
//  Uses a simple linear animation that loops forever. When V0.2 swaps to MP4,
//  this view becomes a thin AVPlayer wrapper — the caller's API stays the same.
//

import SwiftUI

/// Source for the porthole's content. Either a local asset (instant, in-bundle)
/// or a remote URL (loaded async with a graceful fallback).
enum KenBurnsSource: Equatable {
    case asset(String)
    case remote(URL)
}

struct KenBurnsImage: View {
    let source: KenBurnsSource?
    var duration: Double = 24
    var maxScale: CGFloat = 1.18

    @State private var animating = false
    @State private var reveal = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                content(in: geo.size)
                    .id(sourceIdentity)
                    .transition(.opacity)

                LinearGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.08),
                        Color.black.opacity(0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .opacity(reveal ? 1 : 0.82)
            .animation(.easeInOut(duration: 1.1), value: sourceIdentity)
            .onAppear {
                reveal = true
            }
            .onChange(of: sourceIdentity) { _, _ in
                reveal = true
            }
        }
    }

    @ViewBuilder
    private func content(in size: CGSize) -> some View {
        switch source {
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .modifier(KenBurnsMotion(animating: animating, size: size, maxScale: maxScale))
                .onAppear { startAnimating() }
        case .remote(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .modifier(KenBurnsMotion(animating: animating, size: size, maxScale: maxScale))
                        .onAppear { startAnimating() }
                case .failure:
                    starryFallback
                default:
                    // Loading state — keep the porthole feeling "closed" instead of showing a spinner.
                    starryFallback
                }
            }
        case .none:
            // No source yet (idle phase, no idle hub configured): "closed" porthole look.
            starryFallback
        }
    }

    private func startAnimating() {
        guard !animating else { return }
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            animating = true
        }
    }

    private var sourceIdentity: String {
        switch source {
        case .asset(let name):
            return "asset:\(name)"
        case .remote(let url):
            return "remote:\(url.absoluteString)"
        case .none:
            return "none"
        }
    }

    /// Starry-night gradient used whenever there's no real image to show:
    /// remote loading, network failure, or no source. Keeps the porthole feeling
    /// "outside-of-the-plane" rather than "loading error".
    private var starryFallback: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.04, blue: 0.12),
                Color(red: 0.06, green: 0.10, blue: 0.24),
                Color(red: 0.10, green: 0.16, blue: 0.34)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// Slow ping-pong pan + zoom — extracted so .asset and .remote variants share it.
private struct KenBurnsMotion: ViewModifier {
    let animating: Bool
    let size: CGSize
    let maxScale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(animating ? maxScale : 1.0)
            .offset(
                x: animating ? size.width * 0.04 : -size.width * 0.04,
                y: animating ? -size.height * 0.03 : size.height * 0.03
            )
    }
}
