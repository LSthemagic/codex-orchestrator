# Codex Orchestrator: GPT-6 role routing

A global-or-project Codex setup: **Sol High coordinates and reviews; Luna Max
implements and researches**. Lighter roles use less reasoning; architecture and
exceptional escalation have their own explicitly configured roles.

Adapted from [donvito/codex-astra-luna-orchestrator](https://github.com/donvito/codex-astra-luna-orchestrator).
Original workflow, installer and token-utility attribution is retained under
the [Apache License 2.0](LICENSE).

## Model matrix

| Role | Model | Effort | Sandbox |
|---|---|---|---|
| root / orchestrator | `gpt-6-sol` | `high` | workspace-write |
| explorer | `gpt-6-luna` | `medium` | read-only |
| researcher | `gpt-6-luna` | `max` | read-only |
| implementer | `gpt-6-luna` | `max` | workspace-write |
| worker (compatibility alias) | `gpt-6-luna` | `max` | workspace-write |
| tester | `gpt-6-luna` | `high` | workspace-write |
| debugger | `gpt-6-sol` | `high` | workspace-write |
| reviewer | `gpt-6-sol` | `high` | read-only |
| architect | `gpt-6-sol` | `xhigh` | read-only |
| escalation (exceptional consultation) | `gpt-6-astra` | `high` | read-only |

Every named role explicitly pins its model, effort and sandbox. `worker` retains
the same implementation instructions as `implementer` for existing prompts.
Child roles disable further agent spawning; the root dispatches all work.
Changing root/default-child settings alone does not update named-role overrides.

## Routing and consumption

Small localized work stays root-only. Delegate only bounded tasks with useful
independent work or validation. Prefer Luna Max for normal implementation.
After an actionable test/review failure, allow **one corrective retry** (two
total implementation attempts per bounded item); do not repeat without new
evidence. Then route causal investigation to `debugger` or structural decisions
to `architect`. High-risk work can use the appropriate Sol role immediately.

The Sol reviewer uses a **separate context** from the implementer and reports
findings instead of editing. A different model/context is not a correctness
guarantee: the root verifies evidence and tests on the integrated result.

Astra is not part of the normal pipeline. After relevant Sol analysis remains
blocked, or an explicit user request, the root may request **at most one
justified Astra consultation per bounded item**, with evidence and a precise
decision question. Authentication, model availability, permissions and quota
errors are operational blockers, not reasons to escalate to a costlier model.

Routing, retry budgets and escalation gates are **skill instructions, not a
programmatic scheduler or hard billing guard**. Inspect actual traces.
The configuration enforces supported client limits; it does not guarantee
model behavior, throughput, quality, or spend. No paid Fast tier is enabled.

## Profiles

| Installer choice | Profile | Concurrent children |
|---|---|---:|
| 1 (default) | `pro` | 4 |
| 2 | `plus` | 4 |
| 3 | `pro-max-2-subagents` | 2 |
| 4 | `plus-max-2-subagents` | 2 |

All profiles use the matrix above. `pro` and `plus` are compatibility aliases,
not subscription checks. Alias pairs are byte-identical; two-child variants
change only the concurrency limit. The root is excluded from that ceiling.
Use 2-4 Luna agents only for independent tasks; never overlap writers on the
same files or spawn all roles just because they exist.

## Requirements

Use an updated Codex client/account exposing these models, reasoning efforts
and custom subagents. Consult the official [model announcement](https://openai.com/index/introducing-gpt-6-sol-and-luna/),
[configuration reference](https://developers.openai.com/codex/config-reference/)
and [subagents documentation](https://developers.openai.com/codex/subagents/).
Availability depends on version, account and rollout. The installer does not
provision access or make authenticated model calls. Report rejected settings;
do not silently substitute another model or effort.

Installation uses shell/awk or PowerShell and does **not require Python**.
Repository tests require Python 3.11+.

## Install or update

```bash
git clone https://github.com/LSthemagic/codex-orchestrator.git
cd codex-orchestrator
```

For an existing clean clone, run `git pull --ff-only`, then **rerun the
installer**. Pulling the repository alone does not update installed home/project
files. Keep the setup repository separate from your target project.

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

PowerShell 7 alternative: `pwsh -File .\setup.ps1`.

Linux/macOS:

```bash
sh ./setup.sh
```

Choose **1 (Global)**, the default, for all projects of this user, or **2
(Project)** for one existing repository. Then choose profile 1 for four children
or profile 3 for two.

Global installation updates:

```text
~/.codex/config.toml
~/.codex/agents/*.toml                (nine named roles)
~/.codex/AGENTS.md
~/.agents/skills/sol-orchestrator/SKILL.md
```

`CODEX_HOME`, when set, replaces `~/.codex`; skills remain in
`$HOME/.agents/skills`. Global configuration merging updates owned root/agent
keys, preserves unrelated simple TOML settings such as MCP tables, and creates
`config.toml.bak`. This is a line-oriented merge, not a general TOML editor;
manually reconcile complex multiline/quoted-key configurations.

Project installation writes `.codex/`, `.agents/` and `AGENTS.md` in the target.
Existing component updates default to **no**. Directory merging preserves
unrelated files, but an approved project `config.toml` replacement replaces that
whole file: it is **not a semantic TOML merge**. Decline that component and
manually merge the root config and all nine role files when retaining custom
project configuration.

### Safe instruction migration

The installer manages only the block between
`<!-- codex-orchestrator:begin -->` and `<!-- codex-orchestrator:end -->`.
It replaces an existing managed block or the exact previous GPT-5.6 preset,
preserving surrounding custom rules and creating `AGENTS.md.bak` before changes.
Reinstalling unchanged instructions does not duplicate them or overwrite that
backup. Line endings can be normalized; the backup retains the original bytes.

Customized old Sol instructions, malformed/duplicate managed markers and legacy
`astra-orchestrator` policies block installation before target writes. Reconcile
those instructions using [migration](guides/migration.md); do not stack
contradictory policies. The legacy preset in `scripts/legacy-sol-AGENTS.md` is
migration data, not an active instruction file.

Back up existing config, named roles and skills before updating: matching role
files are replaced. Project settings can override global defaults, and
`AGENTS.override.md` can override installed instructions; the installer warns
about a global override file.

## Configuration

The default four-child root profile:

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

Named files under `.codex/agents/` provide the role-specific overrides. Use
`implementer` (or `worker`) for coding, not an anonymous agent for every role.
The skill cannot change an already running root model. Do not invent unsupported
spawn arguments; explicit supported model/effort overrides must match the role.

## Start and verify

Restart Codex in the trusted target project. Confirm Sol/high in the active
session, then invoke:

```text
$sol-orchestrator

Map the relevant execution path. Use the configured explorer and implementer,
validate with tester and request a separate Sol reviewer for material changes.
Preserve public contracts and file ownership. Do not commit or push.
```

Verify actual root/child model, effort, role, concurrent-child count and result
in the traces. A configuration file or skill is not proof an agent ran.
Report unavailable delegation and root-only fallbacks honestly.

## Guides and token measurement

[Full orchestration](guides/full-orchestration.md),
[complex repository work](guides/complex-repo-work.md),
[routine coding](guides/routine-coding.md),
[fast iteration](guides/fast-iteration.md),
[profile compatibility](guides/plus-plan.md),
[migration](guides/migration.md), and
[token measurement](guides/token-usage.md).

The read-only token utility is unchanged:

```bash
python scripts/token_usage.py --list
python scripts/token_usage.py --latest
```

Compare representative tasks, actual token usage, elapsed time and verified
outcomes. Luna Max's tariff does not make total task cost or latency fixed.

## Validation

```bash
python -m unittest discover -s tests -v
sh -n setup.sh
```

Tests validate all profile matrices, role isolation, compatibility aliases,
documentation and real installers in disposable directories: fresh installs,
upgrades, backups, idempotence, config preservation and unsafe legacy cases.
The unchanged token utility has its regression tests. Linux/Windows CI exercises
the available shells; local cases skip when their executable is absent.

These tests do not make authenticated Codex calls or prove that an LLM follows
routing instructions. Verify live model availability and behavior in your own
session. No local benchmark or cost guarantee is claimed.
