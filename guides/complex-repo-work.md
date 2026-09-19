# Complex Repository Work

The standard [Sol/Luna profile](full-orchestration.md) already uses Sol at
`high` reasoning. No model override is needed for cross-component debugging,
architecture-sensitive fixes or multi-file features.

Ask the root to map dependencies and establish acceptance criteria first.
Delegate independent exploration to Luna, then assign implementation with
explicit file ownership. Keep dependent changes sequential. Use a fresh Luna
reviewer context for correctness, security and regression risks; Sol integrates
findings and owns final verification.

Start with the existing four-child ceiling or select the two-child profile.
Do not add agents merely because a slot is available. Avoid simultaneous
writers to shared schemas, API contracts or configuration files. Report
architectural blockers to the root instead of automatically changing models.

Measure actual results with [token-usage.md](token-usage.md). More concurrency
or reasoning is not a guarantee of higher quality, lower cost or faster delivery.
