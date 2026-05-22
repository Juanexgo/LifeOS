import Foundation
import SwiftUI

/// Task priority. Integer-backed so SwiftData can index/sort efficiently.
public enum TaskPriority: Int, Codable, CaseIterable, Sendable, Comparable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var label: String {
        switch self {
        case .none:   return "No priority"
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }

    public var symbol: String {
        switch self {
        case .none:   return "flag"
        case .low:    return "flag.fill"
        case .medium: return "flag.fill"
        case .high:   return "exclamationmark.triangle.fill"
        }
    }

    /// Apple-style tint per priority. Lives here, not in features, so
    /// every surface that renders priorities agrees.
    public var tint: Color {
        switch self {
        case .none:   return .secondary
        case .low:    return .blue
        case .medium: return .orange
        case .high:   return .red
        }
    }
}
