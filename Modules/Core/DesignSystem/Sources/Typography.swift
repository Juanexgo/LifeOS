import SwiftUI

/// Type roles. Views reference roles, never raw font sizes — Dynamic Type
/// respect comes for free because every role is built on `.system` with a
/// text style argument.
public enum Type {
    public static let titleHero    = Font.system(.largeTitle, design: .rounded, weight: .bold)
    public static let titleScreen  = Font.system(.title,      design: .rounded, weight: .semibold)
    public static let titleSection = Font.system(.title2,     design: .rounded, weight: .semibold)
    public static let titleCard    = Font.system(.title3,     design: .rounded, weight: .semibold)

    public static let bodyEmph     = Font.system(.body,       design: .default, weight: .semibold)
    public static let body         = Font.system(.body,       design: .default, weight: .regular)
    public static let bodySoft     = Font.system(.callout,    design: .default, weight: .regular)

    public static let labelStrong  = Font.system(.subheadline, design: .default, weight: .semibold)
    public static let label        = Font.system(.subheadline, design: .default, weight: .regular)

    public static let caption      = Font.system(.footnote,   design: .default, weight: .regular)
    public static let captionTight = Font.system(.caption,    design: .default, weight: .regular)

    public static let mono         = Font.system(.body,       design: .monospaced, weight: .regular)
    public static let monoCaption  = Font.system(.caption,    design: .monospaced, weight: .regular)

    /// Display-only — for hero numerals like "07:24" on focus timers.
    public static let numeral      = Font.system(size: 64, weight: .light, design: .rounded)
        .monospacedDigit()
}
