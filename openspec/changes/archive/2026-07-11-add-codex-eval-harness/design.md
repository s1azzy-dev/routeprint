## Context

The Routeprint control plane already has compact commands, project-local
skills, Make verification gates, and tooling specs. The audit identifies the
remaining blind spot: there is no repeatable way to run the same Codex task in
an isolated checkout and compare outcomes across harness variants.

The implementation is host-side developer tooling. It must not become part of
the Rails runtime, CI's mandatory application gate, or a network service.

## Goals / Non-Goals

**Goals:**

- Make at least 12 representative cases discoverable and reproducible.
- Capture enough metadata to compare two runs without requiring identical diffs.
- Grade safety and workflow expectations mechanically where possible.
- Preserve raw traces locally without committing them or exposing secrets.
- Keep human correction and qualitative rubrics explicit rather than pretending
  they can be inferred from a Codex trace.

**Non-Goals:**

- Building a universal eval platform or model leaderboard.
- Calling Codex, Context7, GitHub, or other external services from CI.
- Automatically deciding correctness from arbitrary model output.
- Adding runtime dependencies, database tables, or application behavior.

## Decisions

### Versioned YAML registry and Markdown prompts

Cases live in `harness/evals/cases.yml`, while prompts remain separate files so
they can be reviewed and reused. YAML is parsed with Ruby's standard-library
Psych; no new dependency is needed. The registry requires a minimum of ten
cases and validates every prompt, grader, required command, and rubric path.

### Ruby standard-library host tools

`bin/harness-run` and `bin/harness-eval` use Ruby's `Open3`, `JSON`, `YAML`,
`CSV`, `Digest`, and `OptionParser`. This follows the existing `bin/*` tooling
pattern and avoids introducing a second scripting runtime. A shell-only runner
was rejected because safe argument handling, JSONL metrics, and CSV/report
generation would be harder to test consistently.

### Disposable worktrees and explicit trace locations

The runner creates worktrees only below `tmp/harness-worktrees/`, starts from a
selected git ref, and writes traces and metadata below `tmp/harness-runs/`.
Both paths are ignored. The runner invokes `codex exec --json --sandbox
workspace-write` with the case prompt and never commits or pushes the tested
worktree. Cleanup is attempted in an `ensure` block; retaining a failed
worktree is supported for diagnosis.

### Graders return JSON

Each grader is an executable that receives `--case`, `--run-dir`, and
`--worktree`, then emits one compact JSON object. `harness-eval grade` combines
the objects into `grade.json`. This keeps graders independently runnable and
allows later graders to be added without changing the runner protocol.

### CSV as the experiment interchange format

`harness/experiments/results.csv` is a committed schema/header with no raw
traces. A run can append one row after human review, including `harness_hash`,
pass/fail, diff scope, correction minutes, required-gate status, tool calls,
token metrics, RTK savings, and retry/compaction indicators. The report command
renders these rows as Markdown and preserves blank values for metrics not
available in a trace.

### No ADR

This is a bounded repository benchmark and does not change product or runtime
architecture. The durable workflow contract remains in the OpenSpec change,
`AGENTS.md`, `docs/DEVELOPMENT.md`, and the harness README.

## Risks / Trade-offs

- [Codex CLI output changes] → metrics extraction is best-effort and raw JSONL
  remains available for diagnosis.
- [A failed run leaves a worktree] → cleanup is attempted automatically, and
  the run metadata records the path and cleanup result.
- [Mechanical graders overfit to implementation] → graders check observable
  paths, commands, and safety boundaries; correctness/minimality/security
  remain human rubrics.
- [Trace contains sensitive user content] → traces stay in ignored tmp paths,
  prompts forbid real secrets, and the README documents local handling.

## Migration Plan

No runtime migration is needed. Add the harness files, validate the registry,
run its tooling spec, and use `bin/harness-run --case <id>` only when a user
intentionally starts an experiment. Removing the feature means deleting the
new harness paths and their tooling spec; application data is unaffected.

## Open Questions

- Which model/reasoning settings produce the most useful baseline is an
  experiment result, not a code-level decision.
- Human review policy for correction minutes and qualitative rubrics remains
  team-owned and is documented in `harness/evals/rubrics/`.
