## Why

The first real Routeprint eval runs showed that the harness consumed millions of
tokens while still producing false-positive grades. Untracked files were absent
from scope checks, required commands were treated as successful when their
trace exit code was non-zero, runs had no timeout, and the declared SDD/skill/
approval expectations were not graded.

This Level 2 tooling change makes the benchmark trustworthy and economical
before any further model runs.

## What Changes

- Make run termination explicit with per-case timeout, interrupt handling,
  partial trace preservation, and safe cleanup metadata.
- Run Codex ephemerally and record model, CLI, sandbox, base commit, prompt,
  registry, and stable harness source hashes.
- Include staged, tracked, and untracked files in diff grading.
- Grade required commands by structured command exit status instead of text
  presence and expose attempted/passed/failed/blocked evidence.
- Add workflow grading for SDD level, OpenSpec use, skill activation, approval
  stops, and expected final gates.
- Add static behavior assertions and optional declared verification commands,
  plus a human review entrypoint for correctness/minimality/security fields.
- Fix experiment reporting so mechanical grade, changed-file scope, and
  explicit unknown values are preserved in CSV/Markdown output.
- Add stable case metadata, explicit required-any/all scope semantics, expected
  housekeeping files, and a cheap representative smoke profile.
- Exclude experiment results and temporary artifacts from the harness hash.

## Capabilities

### New Capabilities

- `codex-eval-harness-hardening`: trustworthy grading, bounded execution,
  workflow/behavior evidence, reproducible metadata, and economical reports.

### Modified Capabilities

None.

## Impact

- Host-side Ruby tools under `bin/`, graders, the eval registry, reports, and
  tooling specs.
- No Rails runtime behavior, database schema, dependency, or external service
  changes. No ADR is required because the change hardens a bounded repository
  benchmark rather than establishing product architecture.
