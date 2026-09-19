# Migrating an Existing Installation

The installer intentionally refuses a target containing
`.agents/skills/astra-orchestrator` or an `astra-orchestrator` reference in
`AGENTS.md`. This avoids mixing old and new orchestration policies and occurs
before any installation writes. It does not delete or rewrite legacy content.

## Back up and review

Close the affected Codex session. Back up the target's `.codex`, `.agents` and
`AGENTS.md` somewhere outside skill-discovery directories. Also review
`~/.codex/config.toml`, `~/.codex/agents/`, `~/.agents/skills/` and any global
instructions if you previously installed upstream globally. Project setup does
not scan, migrate or change those global locations.

Move the old `astra-orchestrator` skill to the backup location. Merely renaming
its directory under `.agents/skills/` is not sufficient: Codex may still discover
its `SKILL.md`. Edit only the old orchestration instructions in `AGENTS.md`;
remove or replace the legacy skill reference while preserving project rules.
Review any extra instructions that pin old root, execution or reviewer models.
Do not automatically delete a whole instruction file or unrelated skills.

## Install or merge

Run `setup.ps1` or `setup.sh` and choose the desired profile. The installer
asks separately before replacing existing component files. An approved
`config.toml` replacement replaces the whole file; unrelated keys in that file
are not merged automatically. When you have custom MCP servers, providers,
permissions or other settings, decline `.codex` replacement and manually merge:

- root model `gpt-5.6-sol`, reasoning `high`;
- `[agents]` enabled, desired child limit, default `gpt-5.6-luna` / `max`;
- all five named role files, each with Luna / max and its intended sandbox.

Copy the new `sol-orchestrator` skill and install or append its project
instructions. Review existing `sol-orchestrator` instructions too: a customized
older block should be reconciled manually rather than accumulating contradictory
versions. Preserve your backups until the new configuration is verified.

## Verify

Restart Codex in the trusted target project. Confirm Sol/high for the root,
then run a bounded delegated task and inspect actual child traces for Luna/max.
Confirm a separate reviewer context and the selected concurrent-child ceiling.
Do not assume configuration text proves a model call succeeded.

If a model, effort or configuration key is rejected, check your Codex version,
account availability and official documentation. Report the exact error; do not
silently switch models or remove safeguards. The repository tests validate files
and installers, not account-specific access to live models.

## Roll back

Close Codex and restore the backed-up configuration and instructions together.
Move the newly installed skill outside discovery paths before restoring the old
one. Restore only the files affected by this installation, not unrelated work.
Restart Codex and verify the restored configuration.
