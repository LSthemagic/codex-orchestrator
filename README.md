# Codex Orchestrator: Sol High + Luna Max

A global-or-project Codex setup with **GPT-5.6 Sol at high reasoning** as the
root/orchestrator and **GPT-5.6 Luna at max reasoning** for every subagent,
including the reviewer. No active profile selects Astra.

This fork adapts [donvito/codex-astra-luna-orchestrator](https://github.com/donvito/codex-astra-luna-orchestrator).
Credit for the original orchestration workflow, installers and token-usage
utility remains with the upstream project. The Apache 2.0 license is preserved.

## Topology

```text
GPT-5.6 Sol - high (plan, coordinate, integrate, verify)
  |-- explorer   : GPT-5.6 Luna - max (read-only)
  |-- worker     : GPT-5.6 Luna - max (workspace-write)
  |-- researcher : GPT-5.6 Luna - max (read-only)
  |-- tester     : GPT-5.6 Luna - max (workspace-write)
  `-- reviewer   : GPT-5.6 Luna - max (read-only, separate context)
```

The reviewer must not reuse the implementing worker's context. It is a
separate review pass, not a different model family or a guarantee of correctness.
The root remains responsible for integrating findings and checking tests.

## Profiles

| Installer choice | Profile directory | Root | All subagents | Concurrent children |
|---|---|---|---|---:|
| 1 (default) | `pro` | Sol high | Luna max | 4 |
| 2 | `plus` | Sol high | Luna max | 4 |
| 3 | `pro-max-2-subagents` | Sol high | Luna max | 2 |
| 4 | `plus-max-2-subagents` | Sol high | Luna max | 2 |

`pro` and `plus` are retained as compatibility names, **not subscription or
pricing checks**. They now install the same models and efforts. The two-child
variants differ only in their concurrent-child limit. Four is a ceiling, not
an instruction to launch four agents for every task.

## Requirements and compatibility

Use a Codex client/account that exposes `gpt-5.6-sol` with `high` reasoning,
`gpt-5.6-luna` with `max` reasoning, and custom subagents. Consult the official
[models](https://developers.openai.com/pt-BR/docs/models) and
[subagents](https://developers.openai.com/pt-BR/docs/agent-configuration/subagents)
documentation. Availability can depend on client version, login and rollout.
The installer copies configuration; it does not provision model access or
validate an authenticated model call. Do not silently substitute another model
or reasoning effort when your client rejects a setting.

## Install globally or into a project

Clone this fork into a separate directory:

```bash
git clone https://github.com/LSthemagic/codex-orchestrator.git
cd codex-orchestrator
```

For an existing clean clone, update with `git pull --ff-only` first.
The target project must already exist and be different from this setup repository.

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

PowerShell 7 alternative: `pwsh -File .\setup.ps1`.

### Linux and macOS

```bash
sh ./setup.sh
```

The installer now asks for scope first. Choose **1 (Global)** to apply the setup to every Codex project for your user, or **2 (Project)** for one repository. Global is the default. Then select profile **1** for four concurrent children or **3** for two.

Global installation writes/merges:

```text
~/.codex/config.toml
~/.codex/agents/{explorer,worker,researcher,tester,reviewer}.toml
~/.codex/AGENTS.md
~/.agents/skills/sol-orchestrator/SKILL.md
```

If `CODEX_HOME` is set, the config, named agents and global `AGENTS.md` use that directory. Skills remain under `$HOME/.agents/skills`, matching Codex user-scope skill discovery. Existing global `config.toml` is merged for only the Sol/Luna keys and backed up as `config.toml.bak`; unrelated settings such as MCP servers are preserved. An existing global `AGENTS.md` is appended idempotently. If `AGENTS.override.md` exists in `CODEX_HOME`, the installer warns because Codex prefers that file over global `AGENTS.md`.

Project installation adds:

```text
<target>/
  .codex/config.toml
  .codex/agents/{explorer,worker,researcher,tester,reviewer}.toml
  .agents/skills/sol-orchestrator/SKILL.md
  AGENTS.md
```

### Existing configurations

Back up your target configuration before updating. The installer lists files
that would be replaced and defaults to **no** for existing-component updates.
Directory merging preserves unrelated files, but **an approved replacement of
`config.toml` replaces that entire file: it is not a semantic TOML merge**.
For custom MCP servers, providers or permissions, decline `.codex` replacement
and manually merge the settings and all five role files instead.

Existing `AGENTS.md` content is preserved and the new instructions are appended
only once. A detected legacy `astra-orchestrator` skill or reference in the
target's `AGENTS.md` blocks installation before any writes. Follow the
[migration guide](guides/migration.md) rather than loading both policies.
Project mode never changes your global Codex configuration. Global mode changes only the user-level Codex configuration and skill locations described above, with a backup before merging an existing config.

## Configuration

The four-child profiles install:

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

All five named role files explicitly set `model = "gpt-5.6-luna"` and
`model_reasoning_effort = "max"`. Changing only the default subagent settings
does not change these explicit role overrides.

For personal/global installation, choose **Global** in `setup.ps1` or `setup.sh`. The installer performs the user-level merge and copies the named roles, skill, and global instructions. Project-level `.codex/config.toml` and `AGENTS.md` files can still override global defaults.

## Start and verify

Restart Codex in the trusted target project after installation. Confirm that
the active root model is Sol with high reasoning. Invoke:

```text
$sol-orchestrator

Map the relevant execution path before changing code. Use Luna subagents for
bounded implementation, testing and a separate read-only review. Preserve
existing APIs, avoid unrelated refactors, and do not commit or push.
```

Inspect the actual subagent traces to verify Luna/max and the configured
concurrency limit. The skill must report missing/failed delegation honestly;
its presence alone is not evidence that any subagent ran. Small localized
changes should remain root-only instead of spawning agents mechanically.

An unrelated workflow's `config.json` is not a replacement for Codex's
`config.toml`. Keep workflow controls separate; a workflow that disables
parallel execution may intentionally schedule agents serially.

## Guides and usage

[Full orchestration](guides/full-orchestration.md),
[complex repository work](guides/complex-repo-work.md),
[routine coding](guides/routine-coding.md),
[fast iteration](guides/fast-iteration.md),
[profile compatibility](guides/plus-plan.md),
[migration](guides/migration.md), and
[token measurement](guides/token-usage.md).

The existing read-only token utility remains available:

```bash
python scripts/token_usage.py --list
python scripts/token_usage.py --latest
```

No Sol/Luna performance or cost benchmark is claimed by this fork. Measure
representative tasks in your own environment before increasing concurrency.

## Validation

Python 3.11+ is required for repository tests (`tomllib`); installation itself
does not require Python. Run:

```bash
python -m unittest discover -s tests -v
```

Tests cover profile/role settings, skill naming, documentation consistency,
and real installer runs in disposable directories, including updates,
idempotence, legacy detection and unsafe target types. Shell and PowerShell
cases skip only when the corresponding executable is absent. The CI workflow
runs on Linux and Windows. These tests do not make authenticated Codex calls.

## License

[Apache License 2.0](LICENSE). Original attribution is retained.
