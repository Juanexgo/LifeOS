import SwiftUI

/// Semantic palette. Views NEVER reference raw colors — they reference roles.
/// Dark-mode-first: dark values are the design intent, light is derived.
///
/// All colors automatically adapt between light/dark via `Color(uiColor:)`
/// with a dynamic `UIColor`. When we add the asset catalog later we can swap
/// implementations without changing call sites.
public enum Palette {
    public static let surface         = dynamic(dark: 0x0A0A0F, light: 0xF7F7FA)
    public static let surfaceRaised   = dynamic(dark: 0x141420, light: 0xFFFFFF)
    public static let surfaceSunken   = dynamic(dark: 0x06060B, light: 0xEFEFF4)

    public static let textPrimary     = dynamic(dark: 0xF5F5F7, light: 0x1C1C1E)
    public static let textSecondary   = dynamic(dark: 0xA8A8B3, light: 0x6B6B73)
    public static let textTertiary    = dynamic(dark: 0x6B6B78, light: 0x9A9AA2)

    public static let accent          = dynamic(dark: 0x6B8CFF, light: 0x355CFF) // signature blue
    public static let accentSecondary = dynamic(dark: 0xB066FF, light: 0x8A2BE2) // assistant violet

    public static let success         = dynamic(dark: 0x30D158, light: 0x28A745)
    public static let warn            = dynamic(dark: 0xFFB340, light: 0xE5A038)
    public static let danger          = dynamic(dark: 0xFF453A, light: 0xD9342B)

    public static let separator       = dynamic(dark: 0x2A2A35, light: 0xE4E4EA)
    public static let separatorStrong = dynamic(dark: 0x3A3A48, light: 0xCFCFD8)
}

// MARK: - Dynamic color helper

private func dynamic(dark: UInt32, light: UInt32) -> Color {
    Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: dark)
            : UIColor(hex: light)
    })
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >>  8) & 0xFF) / 255.0
        let b = CGFloat(hex         & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
