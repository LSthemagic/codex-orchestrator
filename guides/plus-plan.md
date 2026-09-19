# Compatibility Profiles: Plus and Pro

This fork keeps the original installer names and numeric choices to avoid
breaking existing installation instructions. They no longer select different
model families or reasoning efforts based on a subscription label.

`plus` and `pro` both use **Sol high** for the root and **Luna max** for every
subagent, including reviewer, with a four-child ceiling.
`plus-max-2-subagents` and `pro-max-2-subagents` use the same settings with a
two-child ceiling. The files in each alias pair are identical.

Choose option 1 for the default or option 3 to limit concurrency. The installer
also accepts all four profile directory names. It does not check your plan,
provision model access, estimate quota, or promise a cheaper run on Plus.

A previous upstream Plus installation had different model and effort choices.
Update the root config, all five role files, the skill and its `AGENTS.md`
reference together; see [migration](migration.md). Measure your own usage with
[token-usage.md](token-usage.md).
