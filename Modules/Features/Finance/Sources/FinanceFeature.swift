import SwiftUI
import SwiftData
import DesignSystem
import SharedUI
import PersistenceKit

public enum FinanceFeature {
    public enum Route: Hashable, Sendable {
        case detail(UUID)
        case newExpense
    }

    @MainActor
    public static func rootView() -> some View {
        FinanceScreen()
    }
}

@MainActor
struct FinanceScreen: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var expenses: [Expense]

    @State private var draft: Expense? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg.value) {
                        summaryCard
                        breakdownCard
                        recentCard
                    }
                    .padding(.horizontal, .md)
                    .padding(.top, .md)
                    .padding(.bottom, .xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Finance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        draft = Expense(amount: 0)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                    }
                }
            }
            .sheet(item: $draft) { e in
                ExpenseEditor(expense: e) { result in
                    handle(result, for: e)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Derived

    private var monthTotal: Double {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        guard let monthStart = cal.date(from: comps) else { return 0 }
        return expenses
            .filter { $0.date >= monthStart }
            .map(\.amount)
            .reduce(0, +)
    }

    private var byCategory: [(category: ExpenseCategory, total: Double)] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        guard let monthStart = cal.date(from: comps) else { return [] }
        let monthSpends = expenses.filter { $0.date >= monthStart }
        return Dictionary(grouping: monthSpends, by: \.category)
            .map { ($0.key, $0.value.map(\.amount).reduce(0, +)) }
            .sorted { $0.1 > $1.1 }
    }

    private var currencyCode: String {
        expenses.first?.currencyCode ?? (Locale.current.currency?.identifier ?? "USD")
    }

    // MARK: - Cards

    private var summaryCard: some View {
        GlassCard(tier: .floating, radius: .lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("This month")
                    .font(Type.labelStrong)
                    .foregroundStyle(Palette.textSecondary)
                Text(monthTotal.formatted(.currency(code: currencyCode)))
                    .font(Type.numeral)
                    .foregroundStyle(Palette.textPrimary)
                Text("\(expenses.count) total entries")
                    .font(Type.captionTight)
                    .foregroundStyle(Palette.textTertiary)
            }
        }
    }

    private var breakdownCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("By category")
                if byCategory.isEmpty {
                    Text("Tap + to log your first expense.")
                        .font(Type.bodySoft)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    ForEach(byCategory, id: \.category) { row in
                        HStack {
                            Image(systemName: row.category.symbol)
                                .frame(width: 24)
                                .foregroundStyle(row.category.tint)
                            Text(row.category.label)
                                .font(Type.body)
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                            Text(row.total.formatted(.currency(code: currencyCode)))
                                .font(Type.mono)
                                .foregroundStyle(Palette.textSecondary)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var recentCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Recent")
                if expenses.isEmpty {
                    Text("Nothing yet.")
                        .font(Type.bodySoft)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    ForEach(expenses.prefix(8)) { e in
                        HStack {
                            Image(systemName: e.category.symbol)
                                .frame(width: 24)
                                .foregroundStyle(e.category.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.note.isEmpty ? e.category.label : e.note)
                                    .font(Type.body)
                                    .foregroundStyle(Palette.textPrimary)
                                    .lineLimit(1)
                                Text(e.date, format: .dateTime.month().day())
                                    .font(Type.captionTight)
                                    .foregroundStyle(Palette.textTertiary)
                            }
                            Spacer()
                            Text(e.formattedAmount)
                                .font(Type.mono)
                                .foregroundStyle(Palette.textPrimary)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button(role: .destructive) {
                                ctx.delete(e)
                                try? ctx.save()
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
            }
        }
    }

    private func handle(_ result: ExpenseEditor.Result, for e: Expense) {
        switch result {
        case .saved:
            if e.modelContext == nil { ctx.insert(e) }
            try? ctx.save()
            Haptics.commit()
        case .cancelled:
            break
        }
        draft = nil
    }
}
