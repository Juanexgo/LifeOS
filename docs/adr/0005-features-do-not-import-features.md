# ADR 0005 — Features do not import other features

**Status:** Accepted · **Date:** 2026-05-22

## Context

In a typical iOS codebase, a "Modules" or "Features" folder houses
feature-scoped views, view models, and services. Over time, features start
reaching across to each other: `TasksFeature` imports `NotesFeature` to link
a task to a note; `Dashboard` imports `Assistant` to embed a chat panel. The
import graph becomes a spaghetti diagram and "modular" stops being meaningful.

## Decision

**Features cannot import other features.** Cross-feature interaction happens
through three mechanisms:

1. **Shared domain types** — declared in `DomainKit` or `PersistenceKit`,
   imported by both features.
2. **Callback injection** — features expose hooks to the App layer, e.g.
   `DashboardFeature.rootView(onOpenAssistant: () -> Void)`. The App layer
   wires the callback.
3. **App-mediated state** — the `AppContainer` owns shared services (the
   `AIRouter`, `ModelContainer`, `Keychain`) and passes them into features by
   their public root-view factory.

This is enforced by `Project.swift`: feature targets only declare
`featureDependencies` (Core layer + AIKit). Adding `.target(name:
"NotesFeature")` to `TasksFeature`'s dependencies would require a PR — and
that PR would be the conversation we wanted to have.

## Consequences

- **No more "this feature accidentally became a god module."** The blast
  radius of a refactor is one feature, not the whole app.
- **The App layer is the only multi-feature integrator.** [`AppContainer`](../../App/Sources/DI/AppContainer.swift)
  and [`RootView`](../../App/Sources/RootView.swift) are the only files that
  know about all features simultaneously. This is intentional — the
  composition root is allowed to be the one place with cross-cutting
  knowledge.
- **Cost: a small amount of callback ceremony.** Dashboard's "Open
  Assistant" CTA is a `() -> Void` rather than a direct `import Assistant`.
  Worth it for the discipline.

## Example

The Dashboard wants to summon the Assistant overlay, but **does not import
the Assistant module**:

```swift
// In DashboardFeature.swift
public static func rootView(onOpenAssistant: @escaping () -> Void) -> some View {
    DashboardScreen(onOpenAssistant: onOpenAssistant)
}

// In RootView (App layer — the ONLY place that imports both)
DashboardFeature.rootView(onOpenAssistant: { isAssistantPresented = true })
// ...
.sheet(isPresented: $isAssistantPresented) {
    AssistantFeature.rootView(router: container.aiRouter)
}
```

## Alternatives considered

- **A `Coordinator` per feature.** More machinery, same outcome.
- **A shared `Router` in the Core layer.** Defers the problem one layer
  down — now Core has to know about every feature, which is the same anti-
  pattern in different clothing.
