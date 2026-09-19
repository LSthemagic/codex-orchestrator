# Routine Coding

For a small, localized change, let the Sol `high` root work directly. The
`sol-orchestrator` skill is intended for complex or explicitly delegated work,
not a requirement to spawn every role for every edit.

Retain the installed model configuration. Ask for the smallest defensible
change, a targeted regression test and a check of the final diff. Do not
introduce architectural changes, automatic commits or unrelated refactors.

When independent validation materially helps, delegate a bounded test or review
to Luna `max`. Keep a review context separate from an implementation context.
For strictly sequential work, avoid overlapping agents even if the configured
concurrent-child ceiling is greater than one.
