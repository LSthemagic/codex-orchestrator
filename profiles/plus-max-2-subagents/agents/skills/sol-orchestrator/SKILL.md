---
name: sol-orchestrator
description: Use when Codex work spans multiple files or components, requires independent exploration, implementation, testing, research or review, or the user explicitly asks for delegation or subagents. Do not use for trivial localized edits or simple questions.
---

# Sol Orchestrator

Adapted from donvito's orchestration workflow for the GPT-6 role matrix.
User instructions and the target repository's engineering rules take precedence.

## Goal and configured topology

The root owns direction, decomposition, integration and final verification.
Delegate bounded work, not ownership of the overall objective.

| Role | Model | Reasoning | Sandbox |
| --- | --- | --- | --- |
| Root / orchestrator | `gpt-6-sol` | `high` | workspace-write |
| explorer | `gpt-6-luna` | `medium` | read-only |
| researcher | `gpt-6-luna` | `max` | read-only |
| implementer | `gpt-6-luna` | `max` | workspace-write |
| worker | `gpt-6-luna` | `max` | workspace-write |
| tester | `gpt-6-luna` | `high` | workspace-write |
| debugger | `gpt-6-sol` | `high` | workspace-write |
| reviewer | `gpt-6-sol` | `high` | read-only |
| architect | `gpt-6-sol` | `xhigh` | read-only |
| escalation | `gpt-6-astra` | `high` | read-only |

`worker` is a compatibility alias for `implementer`, not an extra mandatory stage.
Unnamed subagents fall back to Luna Max. Prefer named roles for predictable routing.
Each child disables multi-agent tools; only the root dispatches additional work.

The TOML files configure models, efforts, sandboxes and the child-thread cap.
This skill is a decision policy, not a programmatic scheduler: retry budgets,
role selection and Astra conditions are instructions followed by the root,
not additional Codex config keys or a separately enforced billing limit.
A skill cannot change the running root model. Verify it in the actual session.

Use named roles with their configured model/effort. If the spawn interface
accepts explicit overrides, pass that role's pair, not the global Luna fallback
for every role. Do not invent tool parameters or unsupported config keys.
Do not silently substitute an unavailable model or effort. Report the exact
error and the client/account limitation rather than claiming the requested model ran.

## Delegation gate and contract

Keep genuinely small localized tasks root-only. Delegate when independent
exploration, research, implementation or verification materially helps, or when
the user explicitly requests it. Do not spawn agents merely to fill a quota.

For delegated work, use a real spawn and retain the returned identifier.
If spawning is unavailable or fails, disclose an explicit root-only fallback.
Never simulate delegation or present self-review as independent agent review.

Each assignment includes objective, scope, minimal context, constraints,
deliverable and acceptance criteria. Assign writers exact files or a clear
subsystem. Establish shared contracts before parallel implementation.
Include attempt count and concrete failure evidence when requesting a correction.

For example: "Trace POST /invoices currency validation. Return exact files,
symbols, call path and relevant tests. Do not edit files."

## Select the smallest useful role

- `explorer`: targeted file/symbol search, call paths, configuration and tests.
  Do not use Max for a lookup or ask this role for a broad redesign.
- `researcher`: version-sensitive docs, provider semantics, APIs and dependencies.
  Require primary sources, versions/dates, references and explicit uncertainty.
- `implementer` / `worker`: normal bounded code changes and localized fixes.
  Luna Max does the implementation volume; preserve existing contracts.
- `tester`: reproduction, targeted verification and test changes only when assigned.
  Require commands, exit status and output. Do not rewrite production code to pass.
- `debugger`: evidence-led diagnosis of difficult failures, concurrency, performance,
  cross-service state or an exhausted bounded Luna correction. Fix only when assigned.
- `reviewer`: inspect the actual integrated diff for correctness, security,
  regressions, compatibility, concurrency, data integrity and missing useful tests.
- `architect`: a concrete high-impact design decision, shared abstraction, migration
  or cross-service contract. Do not call it for ordinary CRUD, adapters or boilerplate.
- `escalation`: justified exceptional Astra consultation under the conditions below.

A known difficult cross-service bug may go directly to `debugger`; a critical
contract question may go directly to `architect`. Do not force a failed Luna
attempt merely to walk a ladder. Sol analysis can return a bounded fix to Luna.

The Sol reviewer must run in a separate context from the Luna implementer.
This reduces self-review coupling; it does not guarantee independence of errors
or correctness. The root must assess the evidence and run final verification.

## Parallelism and ownership

Read `agents.max_concurrent_threads_per_session` from the active configuration.
The supplied profiles allow four open children or two in constrained variants.
The root is excluded; role definitions do not imply simultaneous execution.

Use zero children for trivial work, one for a bounded independent task, and
two to four only for genuinely independent workstreams within the configured cap.
With a two-child profile, process independent tasks in waves.
Collect results and close completed children before opening replacements.
A retry or specialist is a replacement assignment, not an excuse to exceed the cap.

Never permit concurrent writers on overlapping files. Serialize dependencies:
evidence, decision, implementation, testing/review, corrections, final verification.
Testing and review may run in parallel only on a stable diff, without conflicting
writes. Stop or refresh them if the implementation changes beneath their evidence.
Do not create branches/worktrees, commit, push or merge unless authorized.
Never revert unrelated user changes or weaken sandbox/approval requirements.

## Retry, escalation and stopping rules

Distinguish a reasoning/implementation failure from an operational blocker.
Missing authentication, unavailable models, denied permissions, rate limits,
missing credentials, broken infrastructure and absent task inputs are not proof
that a stronger model is needed. Report the blocker; do not route around controls.

For a localized Luna failure with actionable test/review evidence, allow
one corrective retry (two total attempts for that bounded work item).
Supply the failing command, relevant output and precise correction criteria.
Do not repeat the same prompt without new evidence or retry indefinitely.

If the second attempt remains blocked, stop Luna retries and ask Sol `debugger`
for a causal investigation, or `architect` for a structural decision. Root-only
diagnosis is allowed when the issue does not justify another child.
Escalate earlier only when risk, scope or a contract problem makes a Luna retry
inappropriate. A new attempt must not silently expand permissions or scope.

Astra is not a routine fallback and is never an automatic response to one failure.
Use `escalation` only when the user explicitly requests Astra, or when a
high-impact issue remains unresolved after the relevant Sol analysis. For a
structural issue, obtain Sol XHigh `architect` analysis before consulting Astra.
Record the justification, prior attempts, remaining question and acceptance criteria.
Allow at most one Astra consultation per bounded work item. If it is unavailable
or inconclusive, report the blocker and options; do not start an expensive loop.
Its default is high effort; changing that or using other models needs user direction.

Astra and architect advice does not itself complete a fix. The root decides,
assigns any bounded implementation, obtains fresh review and verifies the result.
Security-sensitive decisions, breaking contracts, new dependencies and scope
expansion always return to the root and remain subject to user authorization.

## Default workflow and completion gate

Gather only enough context to choose the direction. Let Luna implement bounded
changes. For material changes, use a fresh Sol review after a real diff exists.
Run relevant verification, resolve findings and re-check the integrated state.
Do not mechanically call every role and do not review an unfinished diff as final.

Before completion, inspect the final diff, resolve material findings, collect or
explicitly fail every required child, and run relevant syntax/type checks,
tests, builds and reproductions. Confirm no required child is still running.
Report changed files, commands/results, failed or skipped checks and remaining risks.

Keep context focused on decisions, paths/symbols, compact evidence and real results.
Reuse an existing child context for a corrective retry when the tool supports it,
but start review separately. Caching depends on runtime behavior; do not promise
cache hits, fixed savings, unbiased reviews or a task-success rate.
When asked for orchestration evidence, report actual agent IDs, models, efforts,
assignments and statuses from traces. Never claim a model ran without evidence.
