// swift-tools-version: 6.0
// Render the LifeOS app icon at every required size.
//
// Run:
//   cd Tools
//   swift IconRenderer.swift
//
// Outputs PNGs into ../App/Resources/Assets.xcassets/AppIcon.appiconset/
// then updates the Contents.json to reference them.
//
// Design: deep-navy → violet radial gradient with a soft inner glow and
// a single sparkles glyph (matching the in-app Assistant tint). Apple-style
// minimal — the kind of icon that reads at any size.

import Foundation
import SwiftUI
import AppKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - Icon view

struct AppIcon: View {
    var body: some View {
        ZStack {
            // Background — navy with violet radial accent
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.10, green: 0.08, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color(red: 0.69, green: 0.40, blue: 1.00, opacity: 0.55), .clear],
                center: UnitPoint(x: 0.3, y: 0.3),
                startRadius: 50,
                endRadius: 700
            )

            RadialGradient(
                colors: [Color(red: 0.42, green: 0.55, blue: 1.00, opacity: 0.35), .clear],
                center: UnitPoint(x: 0.8, y: 0.85),
                startRadius: 30,
                endRadius: 500
            )

            // Sparkles glyph centered, soft inner shadow
            Image(systemName: "sparkles")
                .font(.system(size: 540, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color(red: 0.80, green: 0.72, blue: 1.00, opacity: 0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.69, green: 0.40, blue: 1.00, opacity: 0.6),
                        radius: 40, x: 0, y: 0)
        }
        .frame(width: 1024, height: 1024)
    }
}

// MARK: - Render

@MainActor
func renderPNG(view: some View, size: CGFloat, scale: CGFloat = 1.0) -> Data? {
    let renderer = ImageRenderer(content:
        view.frame(width: size, height: size)
    )
    renderer.scale = scale

    guard let nsImage = renderer.nsImage,
          let tiff = nsImage.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff)
    else { return nil }

    return rep.representation(using: .png, properties: [:])
}

// MARK: - Run

@MainActor
func run() throws {
    let outputDir = URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("App/Resources/Assets.xcassets/AppIcon.appiconset")

    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

    // The marketing 1024 is required by App Store Connect.
    if let png = renderPNG(view: AppIcon(), size: 1024) {
        let url = outputDir.appendingPathComponent("AppIcon-1024.png")
        try png.write(to: url)
        print("✓ Wrote \(url.lastPathComponent)")
    } else {
        print("✗ Failed to render 1024 icon")
    }

    // Single-size universal Contents.json — iOS 18+ auto-derives smaller
    // variants from the 1024.
    let contents = """
    {
      "images" : [
        {
          "filename" : "AppIcon-1024.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try contents.write(
        to: outputDir.appendingPathComponent("Contents.json"),
        atomically: true,
        encoding: .utf8
    )
    print("✓ Updated Contents.json")
    print("\nDone. Run `tuist generate` to pick up changes in Xcode.")
}

try await MainActor.run { try run() }
