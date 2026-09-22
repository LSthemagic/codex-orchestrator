# Routine Coding

For a small localized change, the Sol/high root works directly.
`sol-orchestrator` is for complex or explicitly delegated work, not a
requirement to spawn every role for every edit.

For bounded implementation that benefits from delegation, use Luna/max
`implementer`; `worker` is a compatible alias. Assign the smallest defensible
change and exact file ownership. Follow the project's test policy and avoid
unrelated refactors, architectural expansion and automatic commits.

Luna/high `tester` runs targeted validation. A material diff receives a
separate-context Sol/high `reviewer`, not self-review by the implementer.
Return actionable findings to Luna for one corrective retry when appropriate.
Escalate unresolved causes to Sol, not every failed test straight to Astra.

Keep dependent steps sequential even if the child-thread ceiling exceeds one.
