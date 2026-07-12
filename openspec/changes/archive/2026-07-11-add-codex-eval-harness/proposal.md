## Why

Routeprint has a disciplined coding harness, but it cannot measure whether the
Codex workflow selects the right project rules, preserves safety boundaries, or
finishes tasks with a narrow verified diff. This Level 2 tooling change turns
the audit's first ten-plus scenarios into a reproducible repository benchmark.

## What Changes

- Add a versioned registry of 12 Routeprint eval cases and their prompts.
- Add a disposable-worktree runner that captures the Codex JSONL trace,
  harness hash, timing, and comparable run metadata.
- Add mechanical graders for changed-file scope, manual schema edits, and
  required verification commands.
- Add CSV experiment storage and a Markdown report that includes pass/fail,
  diff scope, correction time, instruction violations, and execution metrics.
- Add human rubrics and lessons guidance for measures that cannot be inferred
  safely from a trace.
- Keep raw run artifacts under ignored `tmp/harness-runs/` and worktrees under
  ignored `tmp/harness-worktrees/`.

## Capabilities

### New Capabilities

- `codex-eval-harness`: repository-specific case registration, safe execution,
  mechanical grading, and experiment reporting for the Routeprint harness.

### Modified Capabilities

None.

## Impact

- New `harness/` registry, prompts, rubrics, experiment schema, and lessons
  documentation.
- New executable host-side tools under `bin/harness-run`, `bin/harness-eval`,
  and `bin/harness-graders/` using Ruby's standard library only.
- New tooling regression specs and `.gitignore` entries.
- No application runtime code, database schema, external service, or dependency
  changes. No ADR is required because this is a bounded, repository-local
  benchmark and does not establish a product architecture decision.
