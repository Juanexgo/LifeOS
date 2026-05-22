import SwiftUI

/// Centralised animation curves. Every animated change in LifeOS routes through
/// here so we can re-tune feel globally after living with the app.
///
/// Reference points (Apple):
///   - `.snappy`   — fast, slight overshoot. Use for taps and toggles.
///   - `.smooth`   — fluid, no overshoot. Use for state transitions.
///   - `.bouncy`   — large overshoot. Use sparingly (success states, reveal).
public enum Motion {
    /// Tap/toggle/button press. Should feel immediate.
    public static let snap: Animation =
        .snappy(duration: 0.22, extraBounce: 0.08)

    /// Default state change. The workhorse.
    public static let gentle: Animation =
        .smooth(duration: 0.32, extraBounce: 0.0)

    /// Sheet/modal presentations and reveals.
    public static let springy: Animation =
        .spring(response: 0.45, dampingFraction: 0.78, blendDuration: 0.2)

    /// Glass material morphs and parallax. Subtle, longer.
    public static let glass: Animation =
        .smooth(duration: 0.55, extraBounce: 0.0)

    /// Page/screen-level transitions.
    public static let page: Animation =
        .spring(response: 0.55, dampingFraction: 0.85)
}

public extension View {
    /// `.animation(Motion.snap, value: x)` shorthand — readable at call sites.
    func motion<V: Equatable>(_ m: Animation, _ value: V) -> some View {
        animation(m, value: value)
    }
}
