# Measuring Token Usage

This fork uses the [GPT-6 role matrix](../README.md#model-matrix).
It does not claim a measured speed, cost or quality improvement. Historical
upstream runs are not benchmarks for this configuration.

## Read local session logs

The unchanged read-only `scripts/token_usage.py` reads Codex rollout JSONL
files under `~/.codex/sessions`, groups threads by session and reports
recorded roles, models, efforts and usage. It does not modify those logs.

```bash
python scripts/token_usage.py --list
python scripts/token_usage.py --latest
python scripts/token_usage.py --root YOUR_ROOT_THREAD_ID --format json
```

Use `--sessions-dir` for a custom `CODEX_HOME` session location and
`--date YYYY-MM-DD` to narrow the scan. Root-only sessions can be selected by
id. Guardian/auto-review threads are excluded by default; `--include-guardian`
includes them. See `--help` for options. Fields depend on Codex/log version.

## Compare representative tasks

Use the same revision, prompt, acceptance criteria, test suite, permissions
and available tools. Compare root-only Sol/high against the four-child and
two-child profiles. Repeat runs rather than treating one sample as a benchmark.

Record Codex version, actual role/model/effort, children, retries, escalation
reason, uncached/cached input, output/reasoning tokens, elapsed time, test
results and material review findings. Verify all relevant children were counted.
Measure total successful-task cost, not only per-token tariffs. Luna/max can
use more reasoning and time than lower efforts even at a lower token price.

| Task | Profile | Sol usage | Luna usage | Astra usage | Children/retries | Elapsed | Verified result |
|---|---|---|---|---|---|---|---|
| Fill with measured results | | | | | | | |

## Interpret cautiously

Do not treat raw token totals as money or sum overlapping fields blindly.
Cached input, reasoning and visible output have different meanings.
Quota/rate-limit fields can be account-wide; other sessions and resets
confound comparisons. Use current applicable pricing, not hardcoded promises.

More parallel agents are not automatically cheaper or faster. Keep tasks
bounded, avoid duplicate full-repository context and preserve role defaults
during comparisons. The skill's retry/escalation rules are not a hard billing
guard. Redact private paths and source content before sharing reports.
