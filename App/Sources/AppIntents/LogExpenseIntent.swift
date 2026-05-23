import AppIntents
import SwiftData
import Foundation
import PersistenceKit

/// "Hey Siri, log $20 coffee in LifeOS." Inserts an `Expense` in the
/// background and confirms verbally.
struct LogExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Expense"
    static let description = IntentDescription(
        "Log a new expense to LifeOS",
        categoryName: "Finance",
        searchKeywords: ["spend", "expense", "money", "log", "buy"]
    )
    static let openAppWhenRun = false
    static let isDiscoverable = true

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Note", default: "")
    var note: String

    @Parameter(title: "Category", default: ExpenseCategoryAppEnum.other)
    var category: ExpenseCategoryAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) for \(\.$note)") {
            \.$category
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try PersistenceFactory.liveContainer()
        let ctx = ModelContext(container)
        let expense = Expense(
            amount: amount,
            note: note,
            category: category.toDomain()
        )
        ctx.insert(expense)
        try ctx.save()

        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        let formatted = amount.formatted(.currency(code: currencyCode))
        let dialogText: String
        if note.isEmpty {
            dialogText = "Logged \(formatted) under \(category.label)"
        } else {
            dialogText = "Logged \(formatted) for \(note)"
        }
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }
}

enum ExpenseCategoryAppEnum: String, AppEnum {
    case food, transport, subscriptions, home, health, fun, other

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static let caseDisplayRepresentations: [ExpenseCategoryAppEnum: DisplayRepresentation] = [
        .food:          "Food",
        .transport:     "Transport",
        .subscriptions: "Subscriptions",
        .home:          "Home",
        .health:        "Health",
        .fun:           "Fun",
        .other:         "Other"
    ]

    var label: String {
        Self.caseDisplayRepresentations[self]?.title.key.description ?? rawValue.capitalized
    }

    func toDomain() -> ExpenseCategory {
        switch self {
        case .food: return .food
        case .transport: return .transport
        case .subscriptions: return .subscriptions
        case .home: return .home
        case .health: return .health
        case .fun: return .fun
        case .other: return .other
        }
    }
}
