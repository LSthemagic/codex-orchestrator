# Migrating an Existing Installation

Close the affected Codex session and back up config, named roles, skills and
instructions outside skill-discovery directories. Preserve unrelated user
changes. A repository `git pull --ff-only` does not update installed files;
rerun `setup.ps1` or `setup.sh` afterward.

## GPT-5.6 Sol preset to GPT-6

Choose the same scope as the existing installation: Global (default option 1)
or Project (option 2), then the desired four- or two-child profile.

The installer replaces the exact previous Sol preset instruction block with
a managed block between `<!-- codex-orchestrator:begin -->` and
`<!-- codex-orchestrator:end -->`. Surrounding custom rules are retained.
An existing managed block is updated in place. Before changing instructions,
the original bytes are saved as `AGENTS.md.bak`; an unchanged reinstall does
not append a second policy or overwrite that backup. Line endings may normalize.

A customized old block or malformed/duplicate markers is rejected before
target writes. Manually reconcile only the old orchestration instructions,
preserving your rules, then rerun setup. Do not remove a whole custom file.

Global mode merges owned root/agent settings and backs up existing config as
`config.toml.bak`. Unrelated simple settings/MCP tables remain. This merge is
line-oriented: manually handle complex multiline/quoted-key TOML. Matching
named-role and skill files are replaced, so keep your full backup.

Project mode asks separately before replacing existing components. Approved
project `config.toml` replacement replaces the entire file; it is not a
semantic TOML merge. For customized project config, decline that component
and merge manually:

- root `gpt-6-sol` / `high`, existing approval and sandbox policy reviewed;
- enabled root agents, desired child ceiling, default `gpt-6-luna` / `max`;
- all nine role files from the selected profile, not just the default model;
- new skill and managed instructions, without leaving an old policy active.

The [matrix](../README.md#model-matrix) defines explicit role overrides.
`implementer` is the preferred name; `worker` remains compatible.

## Migrating the old upstream Astra skill

A legacy `astra-orchestrator` skill or instruction reference blocks setup
before writes. Move that skill outside `.agents/skills/`: simply renaming a
directory there can leave its `SKILL.md` discoverable. Reconcile only its
old instructions. Do not load both orchestration policies together.

The new `escalation` role is a bounded Astra consultation, not the old
`astra-orchestrator` skill, and does not require removing valid custom agents.

## Scope and overrides

Global config, agents and instructions use `CODEX_HOME` or `~/.codex`;
global skills use `$HOME/.agents/skills`. Project installation never changes
global locations. Check both scopes if previously installed in both:
project config and `AGENTS.override.md` can override new global settings.

## Verify and roll back

Restart Codex in the trusted project. Confirm root Sol/high and actual child
model/effort per role, reviewer context separation and concurrent-child cap.
Check that no older instruction block remains. Configuration text is not
evidence of a successful authenticated model call.

Report rejected models, efforts or configuration keys with exact errors.
Do not silently substitute a model or remove approvals to make a run succeed.
Tests validate files/installers, not account-specific access or LLM compliance.

For rollback, close Codex and restore affected config, roles, skill and
instructions together from your backup. Move the newer skill outside discovery
before restoring an older one. Do not overwrite unrelated changes.
