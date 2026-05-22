import Foundation
import SwiftData
import SwiftUI

/// One spending entry. Amount stored as Decimal-equivalent Double — fine
/// for personal-finance precision, simpler than NSDecimalNumber for now.
@Model
public final class Expense {
    public var id: UUID
    public var amount: Double
    public var note: String
    public var date: Date
    public var categoryRaw: Int
    public var currencyCode: String

    public init(
        id: UUID = UUID(),
        amount: Double,
        note: String = "",
        date: Date = .now,
        category: ExpenseCategory = .other,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    ) {
        self.id = id
        self.amount = amount
        self.note = note
        self.date = date
        self.categoryRaw = category.rawValue
        self.currencyCode = currencyCode
    }
}

public extension Expense {
    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var formattedAmount: String {
        amount.formatted(.currency(code: currencyCode))
    }
}

public enum ExpenseCategory: Int, Codable, CaseIterable, Sendable {
    case food = 0
    case transport = 1
    case subscriptions = 2
    case home = 3
    case health = 4
    case fun = 5
    case other = 99

    public var label: String {
        switch self {
        case .food: return "Food"
        case .transport: return "Transport"
        case .subscriptions: return "Subscriptions"
        case .home: return "Home"
        case .health: return "Health"
        case .fun: return "Fun"
        case .other: return "Other"
        }
    }

    public var symbol: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .subscriptions: return "repeat.circle.fill"
        case .home: return "house.fill"
        case .health: return "heart.fill"
        case .fun: return "music.note"
        case .other: return "circle.dashed"
        }
    }

    public var tint: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .subscriptions: return .purple
        case .home: return .teal
        case .health: return .red
        case .fun: return .pink
        case .other: return .gray
        }
    }
}
