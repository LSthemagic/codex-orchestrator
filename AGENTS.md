<!-- codex-orchestrator:begin -->
# Codex project instructions

For complex coding tasks, use the `sol-orchestrator` skill when its trigger conditions match.

The root uses GPT-6 Sol / high and owns direction, delegation, integration and final
verification. Named roles: explorer Luna / medium; researcher and implementer Luna / max;
tester Luna / high; debugger and reviewer Sol / high; architect Sol / xhigh.
`worker` remains a compatibility alias for implementer. Astra / high is reserved for
the exceptional read-only `escalation` role, not routine execution or review.

Keep trivial tasks root-only. Use independent workstreams within the configured
child-thread limit (four or two); never assign overlapping writes. Only the root
dispatches agents. Review material changes in a separate Sol context.
For a localized Luna failure, use actionable feedback for at most one corrective
retry, then investigate with the relevant Sol role. Operational/access failures
are blockers, not reasons to escalate. Use at most one justified Astra consultation
per bounded work item after relevant Sol analysis, or at the user's explicit request.
Routing and retry rules are agent instructions, not a programmatic cost limiter.

Use the configured model/effort for each role; report unsupported settings and failed
spawns instead of silently substituting models or pretending delegation occurred.
Respect the target repository's engineering rules, approvals and scope.
Do not commit or push unless explicitly authorized by the user.
User instructions always take precedence over this orchestration policy.
<!-- codex-orchestrator:end -->
