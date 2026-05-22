import SwiftUI
import DesignSystem
import SharedUI
import PersistenceKit

struct ExpenseEditor: View {
    enum Result { case saved, cancelled }

    @Bindable var expense: Expense
    let onDismiss: (Result) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("0", value: $expense.amount, format: .number)
                        .keyboardType(.decimalPad)
                        .font(Type.titleScreen)
                }
                Section("Details") {
                    TextField("Note", text: $expense.note)
                    Picker("Category", selection: $expense.category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.label, systemImage: cat.symbol).tag(cat)
                        }
                    }
                    DatePicker("Date", selection: $expense.date, displayedComponents: [.date])
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.surface.ignoresSafeArea())
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onDismiss(.cancelled) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { onDismiss(.saved) }
                        .fontWeight(.semibold)
                        .disabled(expense.amount <= 0)
                }
            }
        }
    }
}
