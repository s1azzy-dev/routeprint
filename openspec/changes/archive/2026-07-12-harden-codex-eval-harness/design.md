## Context

The initial eval harness in the archived `add-codex-eval-harness` change can
register cases, invoke Codex in an isolated checkout, and write traces. The
first real runs exposed reliability gaps: scope grading omitted untracked
files, command grading matched strings instead of exit codes, one case ran for
over ten minutes without a terminal result, and declared workflow expectations
were never evaluated.

## Goals / Non-Goals

**Goals:**

- Make a grade evidence-backed and distinguish passed, failed, blocked,
  missing, timeout, and unknown states.
- Bound every run and preserve enough partial evidence for diagnosis.
- Make results reproducible across variants without hashing mutable results.
- Add workflow and static behavior checks plus an explicit human review path.
- Keep a cheap representative profile available without launching all cases.

**Non-Goals:**

- Running Codex cases as part of CI or `make verify`.
- Claiming that static patterns or agent self-reports prove business
  correctness.
- Adding a new runtime dependency, external service, model provider, or Rails
  application behavior.
- Automatically cleaning user-created worktrees outside the harness roots.

## Decisions

### Structured process execution with timeout and ephemeral Codex

Replace `Open3.capture3` with a process-group-aware execution helper that
captures stdout/stderr, kills the process group on timeout/interruption, and
records terminal status. Every Codex command includes `--ephemeral` so evals do
not mutate the user's persistent Codex state database. Case timeout defaults to
600 seconds and can be overridden explicitly.

### Source-only hashes and explicit run metadata

The harness hash covers only control-plane source, registry, prompts, rubrics,
graders, and entrypoints. Experiment CSV rows, reports, and tmp traces are
excluded. Metadata records Codex version, exact command, sandbox, base commit,
prompt hash, registry hash, source hash, timeout, and selected variant.

### Git status as the changed-file source

Graders combine `git diff HEAD` with `git ls-files --others --exclude-standard`.
This includes tracked, staged, and untracked files. Registry cases distinguish
`files_any`, `files_all`, and `allowed_files`; expected bookkeeping such as
`CHANGES.md` is explicit instead of being treated as unrelated scope.

### Structured command evidence

The tests grader parses completed `command_execution` events and records every
matching command's exit code. Text presence is retained only as evidence of an
attempt, never as proof of success. A required command passes only after at
least one matching invocation exits zero.

### Separate workflow, behavior, and human review evidence

The workflow grader checks declared SDD level, expected skill names, OpenSpec
evidence, approval-stop evidence, and required command outcomes. The behavior
grader supports repository-local file/pattern assertions and declared
post-run verification commands without pretending that either replaces a
human review. `harness-eval review` records correctness, minimality, security,
behavior notes, correction minutes, and reviewer identity in a separate review
CSV.

### Profiled execution and stable baselines

The registry defines a `smoke` profile with three representative cases. Full
case coverage remains available, but normal iteration uses the smoke profile.
Each case may name a stable base ref and explicit timeout; `HEAD` is only the
bootstrap fallback, not a historical baseline promise.

## Risks / Trade-offs

- [A command writes sensitive output] → traces remain under ignored tmp paths;
  graders emit statuses and paths, not raw command output.
- [Killing a process group misses a detached child] → record `cleanup_status`,
  retain the run directory, and allow `--keep-worktree` for diagnosis.
- [Static behavior assertions overfit implementation] → label them static,
  keep human review fields, and allow optional explicit verification commands.
- [Existing cases use old registry fields] → preserve compatibility while
  migrating cases to `files_any`/`files_all` and new behavior metadata.

## Migration Plan

Update the host tools and registry in place. Existing result rows remain
readable; new rows add mechanical/workflow/behavior status fields while blank
legacy human fields render as `unknown`. Run registry validation and tooling
specs without launching Codex. Archive this change after the project gates pass.

## Open Questions

- Which stable commit refs should replace `HEAD` for the final benchmark set is
  a future case-authoring decision.
- Human reviewer identity may later map to a team system; this slice stores a
  local string only.
