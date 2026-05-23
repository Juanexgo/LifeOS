# ADR 0004 — Swift 6 strict concurrency `complete`, no `@unchecked`

**Status:** Accepted · **Date:** 2026-05-22

## Context

Swift 6 ships with three strict-concurrency modes: `minimal`, `targeted`, and
`complete`. The default for new projects is `minimal`. `complete` turns every
unsafe data-race warning into an error.

## Decision

Every target sets `SWIFT_STRICT_CONCURRENCY=complete` and
`SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY=YES`. No file uses `@unchecked
Sendable` to silence the compiler.

## Consequences

- **The compiler proves the absence of data races.** Most concurrency bugs
  in iOS apps (state mutation across actors, shared `URLSession` delegate
  state, view-model writes from background) are caught at build time.
- **Forced design discipline.** The AI providers started life as
  `actor OllamaProvider`. The router's `nonisolated public func stream` then
  couldn't synchronously read the actor's stored properties — leading to a
  refactor to `final class OllamaProvider` with `let` properties of `Sendable`
  type. The new design is simpler.
- **Cost: every new file requires concurrency thinking up front.** Worth it.
  The bugs `complete` catches are the worst ones to debug after shipping.

## Where this shows up

- [`AIRouter`](../../Modules/AI/AIKit/Sources/AIRouter.swift) is an `actor`
  because providers register/unregister concurrently with stream lookups.
- [`Keychain`](../../Modules/Core/SecurityKit/Sources/Keychain.swift) is an
  `actor` because `LAContext` evaluation is async and shouldn't be parallelised
  across requests.
- Cloud providers ([`DeepSeekProvider`](../../Modules/AI/DeepSeekProvider/Sources/DeepSeekProvider.swift),
  [`OllamaProvider`](../../Modules/AI/OllamaProvider/Sources/OllamaProvider.swift))
  are `final class` with `let`-only stored Sendable properties — implicitly
  Sendable, no `@unchecked` needed.

## Alternatives considered

- **Targeted mode.** Easier on day one. Defers the design tension to the first
  multi-actor bug in production. Rejected.
- **`@unchecked Sendable` as escape hatch.** Considered. Disallowed by team
  policy of one: every time a contributor reaches for it, the right answer
  is to change the type's design.
