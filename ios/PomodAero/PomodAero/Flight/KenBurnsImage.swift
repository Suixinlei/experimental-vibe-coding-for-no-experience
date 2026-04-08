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

struct KenBurnsImage: View {
    let url: URL?
    var duration: Double = 24
    var maxScale: CGFloat = 1.18

    @State private var animating = false

    var body: some View {
        GeometryReader { geo in
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .scaleEffect(animating ? maxScale : 1.0)
                            .offset(
                                x: animating ? geo.size.width * 0.04 : -geo.size.width * 0.04,
                                y: animating ? -geo.size.height * 0.03 : geo.size.height * 0.03
                            )
                            .onAppear {
                                // Start the slow ping-pong animation once the image is ready.
                                withAnimation(
                                    .easeInOut(duration: duration).repeatForever(autoreverses: true)
                                ) {
                                    animating = true
                                }
                            }
                    case .failure:
                        starryFallback
                    default:
                        // Loading state — keep the porthole feeling "closed" instead of showing a spinner.
                        starryFallback
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            } else {
                // No URL yet (idle phase): "closed" porthole look.
                starryFallback
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        }
    }

    /// Starry-night gradient used whenever there's no real image to show:
    /// idle phase, loading, or network failure. Keeps the porthole feeling
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
