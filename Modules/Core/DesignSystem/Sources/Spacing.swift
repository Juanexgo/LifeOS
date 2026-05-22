import SwiftUI

/// Spacing scale. Use these instead of raw values so layout density is tunable
/// from one file. Apple's HIG converges on 8pt rhythm — we keep 4 for fine
/// adjustments inside compact controls.
public enum Spacing: CGFloat, Sendable, CaseIterable {
    case xxs = 4
    case xs  = 8
    case sm  = 12
    case md  = 16
    case lg  = 24
    case xl  = 32
    case xxl = 48

    public var value: CGFloat { rawValue }
}

public extension View {
    /// Symmetric padding using a token. Prefer this over raw `.padding(16)`.
    func padding(_ s: Spacing) -> some View { padding(s.value) }

    func padding(_ edges: Edge.Set, _ s: Spacing) -> some View {
        padding(edges, s.value)
    }
}

public extension EdgeInsets {
    static func all(_ s: Spacing) -> EdgeInsets {
        EdgeInsets(top: s.value, leading: s.value, bottom: s.value, trailing: s.value)
    }
}
