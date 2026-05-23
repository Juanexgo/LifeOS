# ADR 0002 — On-device AI is the default, cloud is opt-in

**Status:** Accepted · **Date:** 2026-05-22

## Context

The original product brief listed Ollama, DeepSeek, MLX, and CoreML as
candidate AI backends. The default in most AI-powered apps is "talk to a
cloud API." That decision is usually made for engineering convenience, not
for the user.

With iOS 26 shipping `FoundationModels` (Apple Intelligence's
`SystemLanguageModel`), an on-device LLM is available on every supported
iPhone with no per-request cost and no network round-trip.

## Decision

`FoundationModelsProvider` is the **primary** registered provider. Cloud
providers (DeepSeek, future others) are registered in the router but never
selected by default for `.personal` requests, and never selected at all
unless the user has explicitly configured them.

## Consequences

- **Privacy by default.** A user who downloads the app and runs the assistant
  immediately gets responses generated on-device. Their messages never reach
  Apple's, DeepSeek's, or anyone else's servers.
- **No API key required to ship.** No paid tier, no rate limit, no exposure
  of credentials.
- **The cloud is a deliberate user choice.** The Settings screen surfaces
  DeepSeek as "Optional cloud fallback" with a biometric-gated key entry —
  it never asks for the key on first launch.
- **Cost: smaller context window** than frontier cloud models. The on-device
  model is good for productivity-app use cases (summarisation, drafting,
  intent classification); it's not GPT-5.

## Alternatives considered

- **DeepSeek as primary, on-device as fallback.** Cheaper inference per
  request but spills personal data into the cloud by default. Rejected on
  product principle.
- **CoreML with a custom small model.** Heavier integration cost, no
  obvious win over `FoundationModels` for a generic chat assistant.

## Relation to ADR 0003

This decision and [ADR 0003](0003-privacy-class-fail-closed.md) work together:
ADR 0002 sets the default, ADR 0003 ensures the default isn't silently
violated by the router's fallback logic.
