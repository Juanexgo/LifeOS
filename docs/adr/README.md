# Architecture Decision Records

Significant design choices that future-me (and reviewers) shouldn't have to
reverse-engineer from the code.

| # | Decision | Status |
|---|---|---|
| [0001](0001-tuist-modular-architecture.md) | Tuist with one framework per module | Accepted |
| [0002](0002-on-device-ai-first.md) | On-device AI is the default, cloud is opt-in | Accepted |
| [0003](0003-privacy-class-fail-closed.md) | `.personal` AI requests fail closed instead of escalating to cloud | Accepted |
| [0004](0004-swift6-strict-concurrency.md) | Swift 6 strict concurrency `complete`, no `@unchecked` | Accepted |
| [0005](0005-features-do-not-import-features.md) | Cross-feature communication via callbacks, not imports | Accepted |
| [0006](0006-swiftdata-not-coredata.md) | SwiftData as the only persistence layer | Accepted |

Each ADR follows the same skeleton: **context → decision → consequences →
alternatives considered**. New decisions go in numerically-next files.
