# Sol High + Luna Max Orchestration

Select `pro` (option 1) for up to four concurrent child agents, or
`pro-max-2-subagents` (option 3) for up to two. All profiles use the same
Sol/Luna model split. `plus` names are compatibility aliases, not plan checks.

```text
Sol root (high): plan, coordinate, integrate, verify
  explorer   Luna (max), read-only
  worker     Luna (max), workspace-write
  researcher Luna (max), read-only
  tester     Luna (max), workspace-write
  reviewer   Luna (max), read-only and separate from the worker
```

Setup copies `profiles/<profile>/codex/` to `.codex/` and
`profiles/<profile>/agents/` to `.agents/`, then installs or appends `AGENTS.md`.
For an existing installation, read [migration](migration.md) first.

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "high"
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[agents]
enabled = true
max_concurrent_threads_per_session = 4
default_subagent_model = "gpt-5.6-luna"
default_subagent_reasoning_effort = "max"
```

Each of the five `.codex/agents/*.toml` files also pins Luna and max explicitly.
Keep these role files together with the root configuration. The reviewer uses
a new context, not a different model from the worker.

Restart Codex in the trusted target and invoke `$sol-orchestrator`. The root
should establish file ownership, delegate bounded work, validate changes,
review material risks, and report exact verification evidence. Independent
work can run concurrently up to the configured limit; dependent work must wait.
A role definition is not evidence of execution: verify actual spawn traces.
