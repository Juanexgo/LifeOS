# ADR 0003 — `.personal` AI requests fail closed instead of escalating

**Status:** Accepted · **Date:** 2026-05-22

## Context

Every `AIRequest` carries a `privacyClass`:

- `.personal` — touches user data the user expects to never leave the device
  (journal entries, finances, health, biometric-gated notes).
- `.general` — reasonable to use cloud as fallback.
- `.heavy` — large context / vision / explicit cloud acceptable.

A naïve router would try providers in preference order until one succeeds. If
all on-device providers are unavailable (model not downloaded, OS in
low-power, etc.), the request would fall through to DeepSeek — silently
breaking the privacy promise the call site asked for.

## Decision

The router walks the configured chain for the request's privacy class. If
**no provider in that chain** is both capable and available, the router
throws.

For `.personal` requests specifically, the chain is on-device-only by default.
If every on-device provider is unavailable, the router throws
`AIError.personalRequestEscalationBlocked` rather than substituting a cloud
provider that happens to be ready.

```swift
// Excerpt from AIRouter.stream(_:)
if request.privacyClass == .personal {
    throw AIError.personalRequestEscalationBlocked
}
```

## Consequences

- **The promise is enforceable.** Reviewers and users can read one routing
  function and trust it.
- **Tested behavior, not documentation.** [`LifeOSAppTests.personalDoesNotEscalate`](../../App/Tests/LifeOSAppTests.swift)
  pins this against regression.
- **Call sites must handle the throw.** A failed `.personal` request returns
  an error the UI can show ("This request was kept on-device, but no
  on-device provider is available"). This is preferable to "request
  succeeded but secretly went to the cloud."

## Alternatives considered

- **Warn the user before escalating.** A modal dialog interrupting an AI
  request to ask "fall back to cloud?" breaks the flow and would be
  dismissed habitually. Rejected.
- **Per-request opt-in flag.** Considered, but redundant — the privacy class
  is already that opt-in. The default for `.personal` should match the
  semantic, not require a second checkbox.
