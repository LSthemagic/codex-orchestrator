---
name: sol-orchestrator
description: Use when Codex work spans multiple files or components, requires independent exploration, implementation, testing, research or review, or the user explicitly asks for delegation or subagents. Do not use for trivial localized edits or simple questions.
---

# Sol Orchestrator

Adapted from donvito's orchestration skill for Sol High and Luna Max.
The user's explicit instructions take precedence over this skill.

## Goal and topology

The root owns architecture, decomposition, integration and final verification.
Delegate bounded work, not ownership of the overall direction.

| Role | Model | Reasoning | Sandbox |
| --- | --- | --- | --- |
| Root / orchestrator | `gpt-5.6-sol` | `high` | workspace-write |
| explorer | `gpt-5.6-luna` | `max` | read-only |
| worker | `gpt-5.6-luna` | `max` | workspace-write |
| researcher | `gpt-5.6-luna` | `max` | read-only |
| tester | `gpt-5.6-luna` | `max` | workspace-write |
| reviewer | `gpt-5.6-luna` | `max` | read-only |

These defaults are set in `.codex/config.toml` and `.codex/agents/*.toml`.
A skill does not change the running root model. Do not claim it does.
Verify the selected root model and reasoning in the actual session.

Use the named roles with their configured model and effort. When the spawn
interface supports explicit model/effort arguments, preserve those values.
Do not invent tool parameters unsupported by the current Codex version.
Do not silently change models or reasoning levels. A blocked Luna agent
reports to Sol; changing the model topology requires explicit user permission.

## Delegation gate

Classify the task before substantive work:

- **Root-only:** genuinely small and localized, with no material benefit from
  separate exploration, implementation, testing, research or review.
- **Delegated:** multiple files/components, independent workstreams, unknown
  execution paths, cross-component debugging, version-sensitive research,
  useful independent verification, or an explicit request for subagents.

For delegated work, call `spawn_agent` before doing the assigned work in the
root. Use at least one real subagent; do not narrate or simulate delegation.
If spawning is unavailable or fails, report the limitation. An explicit,
reported root-only fallback is allowed when reasonable; never present that
fallback as independent agent execution or review.

Do not spawn agents just to fill a quota. Use only roles that help the task.

## Root responsibilities

1. Understand the goal, constraints and acceptance criteria.
2. Gather enough evidence to choose the implementation direction.
3. Decompose work and identify dependencies and file ownership.
4. Spawn bounded tasks and retain their returned identifiers.
5. Resolve conflicting evidence and architectural decisions.
6. Integrate changes, inspect the actual diff and verify the result.
7. Report completed work, test evidence, failures and remaining uncertainty.

## Delegation contract

Every task must specify an objective, scope, minimal necessary context,
constraints, deliverable and acceptance criteria.

For writers, assign exact files or an unambiguous subsystem. For exploration
and research, prohibit edits. For reviews, request findings rather than fixes.

Bad: "Fix the backend."

Good: "Trace where POST /invoices validates currency. Return responsible
files, the validation path and existing tests. Do not edit files."

Use concise task names and preserve the identifiers returned by the tools.
Do not ask an agent to work outside its allowed sandbox or approvals.

## Role selection

- `explorer`: map files, symbols, dependencies, execution/data flow and tests.
- `worker`: implement the smallest defensible change within assigned scope.
- `researcher`: verify current APIs, versions and framework behavior using
  primary documentation; return references and uncertainty.
- `tester`: reproduce failures and run targeted verification. Modify tests
  only when assigned; never rewrite production code merely to pass a test.
- `reviewer`: inspect the actual post-change diff for correctness, security,
  regressions, concurrency, data integrity and missing high-value tests.

The reviewer must be a separate agent/context from the implementing worker.
It uses the same Luna model, not an independent model family. Separate context
reduces self-review coupling but does not guarantee unbiased or correct review.
Sol remains responsible for accepting or rejecting its findings.

## Parallelism and ownership

Read `agents.max_concurrent_threads_per_session` from the active config.
Default profiles allow four open child threads; constrained profiles allow two.
The root thread is excluded. The number of role definitions is not a mandate
to run every role simultaneously.

Spawn independent work before waiting where capacity permits. With a two-agent
limit, run independent tasks in waves. Collect results and close finished agents
when the tool supports it before opening more; do not exceed the configured cap.

Serialize dependencies: explore, decide, implement, test, review, fix, verify.
Never run conflicting writes concurrently. Prefer one writer per file or
subsystem; coordinate shared interfaces before delegating implementation.

Do not create branches or worktrees, commit, push or merge unless authorized
by the user or the project's explicit workflow. Respect manual-commit policies.
Do not revert unrelated user changes.

## Default coding workflow

1. Delegate targeted exploration where repository understanding is needed.
2. Sol chooses architecture and implementation boundaries from the evidence.
3. Delegate implementation to Luna workers with non-overlapping ownership.
4. Run targeted tests through a tester when useful; require commands and output.
5. Start a fresh Luna reviewer for material changes after the diff is available.
6. Resolve material findings, then run final verification on the integrated state.
7. Wait for every required agent to finish or explicitly fail before reporting.

Do not spawn every role mechanically and do not review an unfinished diff as
though it were the final implementation.

## Debugging and research

For cross-component bugs, explore independent suspected areas, reproduce the
problem, choose a cause from evidence, make a bounded fix and re-run the original
reproduction. Use a reviewer for high-risk or non-obvious fixes.

For current or version-specific facts, require primary documentation or source
code, exact references and version/date assumptions. Do not turn speculation
into an implementation requirement.

## Escalation and failures

Agents must report architectural choices, breaking API/schema changes, new
dependencies, security-sensitive decisions, conflicting ownership, unclear
requirements and scope expansion to the root rather than deciding silently.

On failure, inspect the cause, then narrow, retry, reassign or explicitly fall
back to the root. Do not hide a failed agent or claim its task succeeded.
No automatic escalation to an unconfigured model is allowed.

## Context and consumption

Keep root context focused on decisions, summarized evidence, relevant diffs,
tests, findings and unresolved risks. Prefer exact paths/symbols and concise
results to whole files or raw logs. More agents and more reasoning can increase
usage; make no cost or quality guarantees without measurements.

## Completion gate

Before claiming completion:

1. Inspect the integrated diff and confirm requested behavior and scope.
2. Ensure all required agents completed or their failures were disclosed.
3. Resolve material findings and conflicting results.
4. Run applicable syntax/type checks, targeted tests, builds and reproductions.
5. Record commands, actual results, coverage gaps and checks not performed.
6. Confirm no required agent is still running.

The final answer should cover changes, evidence and limitations, not every
internal action. When asked for orchestration evidence, report agent identifiers,
actual models, assigned work and completion status from the trace.
Never claim Luna was used without a successful spawn and evidence of its model.
