# Compatibility Profiles: Plus and Pro

Original profile names and numeric choices are retained to avoid breaking
installation instructions. They do not infer subscriptions or choose models
from a plan label.

`plus` and `pro` share the complete [GPT-6 role matrix](../README.md#model-matrix)
and a four-child ceiling. `plus-max-2-subagents` and `pro-max-2-subagents` use
the same matrix with a two-child ceiling. Alias pairs are byte-identical.

Choose option 1 by default or option 3 to limit concurrency. The installer
also accepts the four profile directory names. It does not provision model
access, estimate quota or promise cheaper execution for any subscription.

Update the root config, all nine role files (including the compatible `worker`),
skill and managed instructions together. See [migration](migration.md).
Measure your environment with [token usage](token-usage.md).
