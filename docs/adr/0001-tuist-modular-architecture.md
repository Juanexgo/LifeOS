# ADR 0001 — Tuist with one framework per module

**Status:** Accepted · **Date:** 2026-05-22

## Context

LifeOS is intended to grow into a multi-feature personal-OS app (tasks, notes,
focus, health, finance, AI assistant, …). Three options for project structure:

1. Single Xcode project with all sources, organized only by groups.
2. Swift Package Manager only (`Package.swift`), no `.xcodeproj`.
3. Tuist with modular targets, regenerated `.xcodeproj`.

## Decision

**Tuist with one framework target per module.** The `.xcodeproj` and
`.xcworkspace` are gitignored and regenerated from `Project.swift` on demand.

## Consequences

- **Dependency graph is linker-checked.** `Tasks` cannot accidentally `import
  Notes` because `Notes` isn't on its link line. This holds the modularity
  promise after six months of feature work.
- **The `.xcodeproj` never causes merge conflicts.** Two engineers can edit
  `Project.swift` declaratively in plain Swift.
- **A new module is one helper-function call** in `Project.swift` via
  [`Target.module(_:layer:dependencies:)`](../../Tuist/ProjectDescriptionHelpers/Module.swift).
- **Cost: contributors must install Tuist** (`brew install tuist`). One-time.

## Alternatives considered

- **Pure SPM:** Limits some Apple capabilities (App Extensions, the Widget
  Extension required separate signing). Ruled out.
- **Single-target Xcode project:** Fine for a tutorial. Doesn't scale past a few
  features without becoming a "groups → folders → utility drawer" mess.
- **XcodeGen:** Lighter alternative, YAML-based. Less Swift-native than Tuist.
  Acceptable; Tuist's `ProjectDescription` types provide better autocomplete
  and type safety when authoring `Project.swift`.
