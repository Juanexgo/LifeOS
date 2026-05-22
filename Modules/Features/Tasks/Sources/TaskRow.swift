import SwiftUI
import DesignSystem
import SharedUI
import PersistenceKit

/// A single task row. Tap circle = toggle complete, tap rest = open editor.
/// Pure presentation — no SwiftData calls inside; parents own mutations.
struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm.value) {
            // Completion circle — generous tap target.
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(task.isCompleted ? Palette.accent : Palette.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title.isEmpty ? "Untitled" : task.title)
                    .font(Type.bodyEmph)
                    .foregroundStyle(task.isCompleted ? Palette.textSecondary : Palette.textPrimary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)

                metadata
            }

            Spacer(minLength: 0)

            if task.priority != .none {
                Image(systemName: task.priority.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(task.priority.tint)
            }
        }
        .padding(.md)
        .frame(maxWidth: .infinity)
        .glass(.raised, in: Radius.md.shape)
        .clipShape(Radius.md.shape)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    @ViewBuilder
    private var metadata: some View {
        if let due = task.dueDate {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                Text(due, style: .date)
                    .font(Type.caption)
            }
            .foregroundStyle(task.isOverdue ? Palette.danger : Palette.textSecondary)
        }
    }
}
