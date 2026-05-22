import SwiftUI

/// Corner radius scale. Always paired with `.continuous` style — sharp corners
/// look cheap next to iOS 26 glass surfaces.
public enum Radius: CGFloat, Sendable, CaseIterable {
    case xs = 6   // chips, tiny controls
    case sm = 12  // buttons, list rows
    case md = 20  // cards
    case lg = 28  // sheets, hero surfaces

    public var value: CGFloat { rawValue }

    public var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: value, style: .continuous)
    }
}

public extension View {
    func clipShape(_ r: Radius) -> some View { clipShape(r.shape) }
    func cornerRadius(_ r: Radius) -> some View { clipShape(r) }
}
