//
//  PortholeShape.swift
//  PomodAero
//
//  The airplane window silhouette: rounded rectangle with slightly "squashed" corners
//  (more oval than iOS's native continuous corners). Used as both a content mask and
//  a decorative metal ring.
//

import SwiftUI

struct PortholeShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Real 737 windows are about 9.6" x 12" — ~1 : 1.25 ratio, corners roughly 1/3 of width.
        let cornerRadius = min(rect.width, rect.height) * 0.42
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect)
    }
}
