# Codex project instructions

For complex coding tasks, use the `sol-orchestrator` skill when its trigger conditions match.

The root runs on GPT-5.6 Sol with high reasoning and owns architecture, decomposition,
integration and final verification. All named subagents, including reviewer, use
GPT-5.6 Luna with max reasoning. Start the reviewer in a separate context from the worker.

Prefer bounded exploration, implementation, testing, review and technical research.
Do not delegate trivial work merely for parallelism. Respect the configured concurrent
child-thread limit and do not let implementation agents edit overlapping files.
Do not commit or push unless explicitly authorized by the user.
User instructions always take precedence over this orchestration policy.
