# ADR 0006 — SwiftData as the only persistence layer

**Status:** Accepted · **Date:** 2026-05-22

## Context

The original product brief listed "SwiftData, CoreData, Keychain" as
persistence options. With iOS 26 as the floor, SwiftData has matured enough
to be the sole choice for relational/document storage.

## Decision

`PersistenceKit` exposes one persistence stack:

- **SwiftData `ModelContainer`** via [`PersistenceFactory`](../../Modules/Core/PersistenceKit/Sources/PersistenceKit.swift)
- **`VersionedSchema`** (`LifeOSSchemaV1`) wraps every `@Model` — schema
  evolution will happen through `LifeOSSchemaV2` + a `MigrationStage`, not
  through manual `NSPersistentStoreCoordinator` migrations.
- **Models** so far: `TaskItem`, `Note`, `FocusSession`, `Expense`.
- **Keychain** handles secrets only (API keys, biometric-gated values). Not
  a general key-value store.

CoreData is not imported anywhere.

## Consequences

- **One mental model.** Feature code uses `@Query` and `ModelContext`
  uniformly. No "CoreData for legacy, SwiftData for new."
- **`@Query` in SwiftUI views is reactive by default.** [`TasksScreen`](../../Modules/Features/Tasks/Sources/TasksScreen.swift)
  doesn't need a view model layer between the view and the store — the
  fetched array updates the UI automatically as the underlying store mutates.
- **Migrations are visible.** Adding a model is one line in
  `LifeOSSchemaV1.models`. Breaking changes get a new schema version with
  an explicit `MigrationStage` in the same file.
- **Cost: a single non-Comparable Bool sort.** SwiftData's `SortDescriptor`
  requires `Comparable`; `Bool` isn't. `TaskItem.isCompleted` is backed by
  `isCompletedRaw: Int` with a computed `Bool` wrapper. Same trick for
  `priority`. Tiny ceremony for a real win.

## Alternatives considered

- **GRDB.** Excellent library, but adds a third-party dependency for
  problems SwiftData solves natively on iOS 26.
- **Realm.** Heavier, MongoDB-owned, dependency.
- **CoreData.** The fallback story was for pre-iOS 17 deploy targets. We
  deploy iOS 26.

## Field protection

The store uses `cloudKitDatabase: .none` for now (CloudKit sync is a future
decision — see the roadmap). File protection is the SwiftData default
(`.completeUntilFirstUserAuthentication`), which means the file is decrypted
on first unlock and stays decrypted while the device is awake. For health
and financial data this is acceptable; we'd tighten to
`.complete` only if/when push notifications need to wake the app to read
those files (they don't yet).
