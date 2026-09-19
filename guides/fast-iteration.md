# Fast Iteration

Keep the configured Sol `high` root and Luna `max` subagents. For a faster
feedback loop, reduce unnecessary work rather than silently replacing the
requested models or reasoning levels.

Use narrow tasks, targeted test commands and concise subagent reports. Keep
small edits root-only; for larger tasks parallelize only independent exploration
or implementation with non-overlapping file ownership. The two-child profile
can limit concurrency, but is not guaranteed to minimize wall time or total usage.

This fork does not enable a paid Fast/service tier automatically. Check the
current client capabilities and any pricing implications before changing such
settings. Compare measurements using [token-usage.md](token-usage.md).
