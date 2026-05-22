import Foundation
import SwiftData

/// Factory for the app's `ModelContainer`. Centralised so features never
/// instantiate their own container — every screen reads from the same
/// SwiftData store via the environment.
///
/// Models will be registered here as features land (Tasks, Notes, Habits,
/// etc.). Keeping them in one place forces us to think about migrations
/// holistically when the schema changes.
public enum PersistenceFactory {
    /// Build the production container. Throws on disk failure so the App can
    /// degrade gracefully (read-only mode, recovery sheet, etc.).
    public static func liveContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: LifeOSSchemaV1.self)
        let config = ModelConfiguration(
            "LifeOS",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// In-memory container for previews and tests. Never persists.
    public static func previewContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: LifeOSSchemaV1.self)
        let config = ModelConfiguration(
            "LifeOS-preview",
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}

/// Versioned schema — wrap every PersistentModel here. Adding a new model is
/// one line; renaming/migrating goes through a new `LifeOSSchemaV2`.
public enum LifeOSSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    public static var models: [any PersistentModel.Type] {
        [
            TaskItem.self,
            Note.self,
            FocusSession.self,
            Expense.self
        ]
    }
}
