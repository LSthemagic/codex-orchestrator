# Measuring Token Usage

This fork ships Sol `high` for the root and Luna `max` for every subagent.
It does not claim a measured speed, cost or quality improvement. Historical
upstream measurements used a different topology and are not Sol/Luna benchmarks.

## Read the local session logs

The unchanged `scripts/token_usage.py` utility reads Codex rollout JSONL files
under `~/.codex/sessions`. It groups threads by session, reports recorded models,
efforts and token usage, and does not modify the logs.

```bash
python scripts/token_usage.py --list
python scripts/token_usage.py --latest
python scripts/token_usage.py --root YOUR_ROOT_THREAD_ID --format json
```

Use `--date YYYY-MM-DD` to narrow the scan. Root-only sessions can be selected by
id. Guardian/auto-review threads are excluded from totals by default; pass
`--include-guardian` to include them. Run `python scripts/token_usage.py --help`
for all options. Available fields depend on the Codex version and log format.

## Compare representative tasks

Use the same repository revision, prompt, acceptance criteria and test suite
for each run. Compare a root-only Sol/high baseline with the four-child profile
and, when useful, the two-child profile. Keep permissions and available tools
consistent. Repeat runs rather than treating a single sample as a benchmark.

Record Codex version, profile, actual models/efforts, spawned-agent count,
uncached input, cached input, output and reasoning tokens, elapsed time, test
results and material review findings. Verify that any usage report actually
includes the relevant child sessions before interpreting totals.

| Task | Profile | Sol usage | Luna usage | Actual children | Elapsed | Verification |
|---|---|---|---|---:|---|---|
| Fill with measured results | | | | | | |

## Interpret cautiously

Do not treat raw token totals as money or sum overlapping fields blindly.
Cached input and reasoning output have different meanings from uncached input
and visible output. Rate-limit fields, when present, may be account-wide;
other sessions and window resets can confound before/after differences.

More concurrent agents are not automatically cheaper, faster or better. Reduce
unnecessary delegation, keep reports focused and avoid sending the same full
repository context to every task. Preserve the requested Sol/high and Luna/max
settings while measuring workflow changes. Redact private paths and source
content before sharing reports.
