# GPT-6 Orchestration

The [model matrix](../README.md#model-matrix) is shared by every profile.
Sol/high owns planning, integration and final verification. Explorer uses
Luna/medium; researcher and implementer use Luna/max; tester uses Luna/high.
Debugger and reviewer use Sol/high, architect Sol/xhigh, and exceptional
read-only escalation uses Astra/high. `worker` aliases the implementer.

Choose `pro` (option 1) for four concurrent children or
`pro-max-2-subagents` (option 3) for two. Plus names are compatibility aliases,
not plan checks. All child roles disable further spawning; the root dispatches.

```toml
model = "gpt-6-sol"
model_reasoning_effort = "high"
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[agents]
enabled = true
max_concurrent_threads_per_session = 4
default_subagent_model = "gpt-6-luna"
default_subagent_reasoning_effort = "max"
```

Keep all nine named role files, root configuration, skill and managed
instructions together. Global is the installer's default scope; project
scope writes only in the selected target. Read [migration](migration.md)
before updating existing configuration.

The root gathers evidence, establishes file ownership and delegates only
useful independent work. A normal flow is exploration, implementation, tests,
fresh-context Sol review, corrective feedback and final verification.
One corrective Luna retry is allowed with actionable feedback; repeated or
structural failures route to the appropriate Sol role.

Astra is limited by policy to one justified consultation per bounded item
after relevant Sol analysis or an explicit request, never automatic fallback
for authentication, model availability or quota errors. These are skill
instructions, not an executable scheduler or hard spending limit.

Restart Codex and invoke `$sol-orchestrator`. Verify the actual role, model,
effort and child ceiling in traces. A role definition does not prove execution.
