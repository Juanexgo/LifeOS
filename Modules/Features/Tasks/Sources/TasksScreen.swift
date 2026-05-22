import SwiftUI
import SwiftData
import DesignSystem
import SharedUI
import PersistenceKit

/// The Tasks tab. Uses SwiftData `@Query` directly — no view-model layer
/// between the view and the store. For lists this is the right call:
/// SwiftData's `@Query` is already an observable, animated, diffable
/// data source. Adding a VM only hides what SwiftUI already does well.
///
/// We DO use a separate state holder (`TasksState`) for non-query state:
/// sort order, the currently-presented editor sheet, search text. That's
/// where `@Observable` shines.
@MainActor
struct TasksScreen: View {
    @Environment(\.modelContext) private var ctx

    @Query(sort: [SortDescriptor(\TaskItem.isCompletedRaw),
                  SortDescriptor(\TaskItem.priorityRaw, order: .reverse),
                  SortDescriptor(\TaskItem.createdAt, order: .reverse)])
    private var tasks: [TaskItem]

    @State private var state = TasksState()

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                if tasks.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        state.editing = TaskItem(title: "")
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                    }
                }
            }
            .sheet(item: $state.editing) { task in
                TaskEditor(task: task) { result in
                    handle(result: result, for: task)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.xs.value) {
                ForEach(tasks) { task in
                    TaskRow(task: task) {
                        toggle(task)
                    } onTap: {
                        state.editing = task
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 0.96))
                    ))
                }
            }
            .padding(.horizontal, .md)
            .padding(.top, .sm)
            .padding(.bottom, .xl)
            .animation(Motion.gentle, value: tasks.map(\.id))
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md.value) {
            Image(systemName: "checklist")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Palette.textTertiary)
            Text("No tasks yet")
                .font(Type.titleCard)
                .foregroundStyle(Palette.textPrimary)
            Text("Tap + to add your first one.")
                .font(Type.bodySoft)
                .foregroundStyle(Palette.textSecondary)
            GlassButton("Add task", systemImage: "plus") {
                state.editing = TaskItem(title: "")
            }
            .padding(.top, Spacing.sm.value)
        }
        .padding(.lg)
    }

    // MARK: - Mutations

    private func toggle(_ task: TaskItem) {
        Haptics.success()
        withAnimation(Motion.snap) {
            task.toggleCompletion()
        }
        save()
    }

    private func delete(_ task: TaskItem) {
        Haptics.warn()
        withAnimation(Motion.gentle) {
            ctx.delete(task)
        }
        save()
    }

    private func handle(result: TaskEditor.Result, for task: TaskItem) {
        switch result {
        case .cancelled:
            // If the task isn't in the store (new task), nothing to do.
            if task.modelContext == nil { /* discarded */ }
        case .saved:
            if task.modelContext == nil {
                ctx.insert(task)
            }
            save()
            Haptics.commit()
        case .deleted:
            if task.modelContext != nil {
                ctx.delete(task)
                save()
            }
            Haptics.warn()
        }
        state.editing = nil
    }

    private func save() {
        do {
            try ctx.save()
        } catch {
            // PHASE 7: surface persistence errors via a non-intrusive toast.
            print("SwiftData save failed: \(error)")
        }
    }
}

@Observable
@MainActor
final class TasksState {
    var editing: TaskItem? = nil
    var search: String = ""
}
