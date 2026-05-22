import Foundation
import SwiftData

/// Core SwiftData model for a task. Lives in PersistenceKit because that's
/// where the schema is owned. Feature modules read/write through `@Query`
/// and `ModelContext`; they never construct queries that bypass this type.
///
/// Why not split into a domain struct + persistence model? SwiftData's
/// `@Query`, predicate macros, and migrations all work directly with the
/// `@Model` class. Splitting would force us to bridge at every read site —
/// dead weight for an app of this shape.
@Model
public final class TaskItem {
    /// Stable identity. We don't rely on SwiftData's PersistentIdentifier
    /// for app-level logic — UUIDs survive store migrations and exports.
    public var id: UUID

    public var title: String
    public var notes: String?
    public var dueDate: Date?

    /// Backed by Int so SwiftData's `SortDescriptor` (which requires
    /// `Comparable`) can sort completed-after-pending. Use `isCompleted`
    /// at call sites — never read `isCompletedRaw` directly.
    public var isCompletedRaw: Int
    public var completedAt: Date?

    public var priorityRaw: Int
    public var createdAt: Date

    /// Free-text tags for AI categorization (Phase 4). Comma-separated for
    /// now; promoted to a relationship if cardinality grows.
    public var tagsRaw: String

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        priority: TaskPriority = .none,
        createdAt: Date = .now,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompletedRaw = isCompleted ? 1 : 0
        self.completedAt = completedAt
        self.priorityRaw = priority.rawValue
        self.createdAt = createdAt
        self.tagsRaw = tags.joined(separator: ",")
    }
}

// MARK: - Computed conveniences

public extension TaskItem {
    var isCompleted: Bool {
        get { isCompletedRaw == 1 }
        set { isCompletedRaw = newValue ? 1 : 0 }
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .none }
        set { priorityRaw = newValue.rawValue }
    }

    var tags: [String] {
        get { tagsRaw.isEmpty ? [] : tagsRaw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } }
        set { tagsRaw = newValue.joined(separator: ",") }
    }

    /// Is this task due today (or before) and not yet done?
    var isDueToday: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return Calendar.current.isDateInToday(due) || due < .now
    }

    /// Is this task overdue (past due, not done)?
    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Calendar.current.startOfDay(for: .now)
    }

    /// Toggle completion with proper timestamping.
    func toggleCompletion() {
        if isCompleted {
            isCompleted = false
            completedAt = nil
        } else {
            isCompleted = true
            completedAt = .now
        }
    }
}
