import SwiftUI
import DesignSystem
import SharedUI
import PersistenceKit

/// Create/edit sheet. Edits the passed-in `TaskItem` in place. The caller
/// decides what to do with the result — insert into context for new items,
/// save the context for edits, or discard on cancel.
///
/// This separation matters: the editor never knows whether `task` is a
/// fresh instance or already-persisted. SwiftData's `modelContext` check
/// is what tells the parent.
struct TaskEditor: View {
    enum Result { case saved, cancelled, deleted }

    @Bindable var task: TaskItem
    let onDismiss: (Result) -> Void

    @State private var enableDueDate: Bool = false
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $task.title, axis: .vertical)
                        .font(Type.titleCard)
                        .focused($titleFocused)
                    TextField("Notes (optional)", text: Binding(
                        get: { task.notes ?? "" },
                        set: { task.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(2...6)
                    .font(Type.body)
                }

                Section("Schedule") {
                    Toggle("Due date", isOn: $enableDueDate)
                    if enableDueDate {
                        DatePicker(
                            "Due",
                            selection: Binding(
                                get: { task.dueDate ?? .now },
                                set: { task.dueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $task.priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            HStack {
                                Image(systemName: p.symbol).foregroundStyle(p.tint)
                                Text(p.label)
                            }.tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if task.modelContext != nil {
                    Section {
                        Button("Delete", role: .destructive) {
                            onDismiss(.deleted)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.surface.ignoresSafeArea())
            .navigationTitle(task.modelContext == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onDismiss(.cancelled) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { onDismiss(.saved) }
                        .fontWeight(.semibold)
                        .disabled(task.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                enableDueDate = task.dueDate != nil
                if task.title.isEmpty { titleFocused = true }
            }
            .onChange(of: enableDueDate) { _, newValue in
                if newValue && task.dueDate == nil {
                    task.dueDate = Calendar.current.startOfDay(for: .now)
                        .addingTimeInterval(60 * 60 * 18) // default 6pm today
                } else if !newValue {
                    task.dueDate = nil
                }
            }
        }
    }
}

// SwiftData's @Model classes can be presented in `.sheet(item:)` because
// they're Identifiable — but we need `Identifiable` to be visible to the
// sheet API. @Model already conforms. No bridge needed.
