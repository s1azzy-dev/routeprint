## ADDED Requirements

### Requirement: The repository SHALL register reproducible eval cases
The harness SHALL provide a versioned case registry with at least ten unique
cases, a prompt file, expected workflow metadata, required checks, forbidden
changes, and graders for every case.

#### Scenario: Validate the case registry
- **WHEN** a developer runs `bin/harness-eval validate`
- **THEN** the command succeeds only when all case references exist and the
  registry contains at least ten unique cases
- **AND THEN** it reports the case count and registry path

#### Scenario: Reject an incomplete case
- **GIVEN** a case references a missing prompt or grader
- **WHEN** the registry validator runs
- **THEN** it exits non-zero and identifies the missing path

### Requirement: The runner SHALL isolate and record a Codex execution
The runner SHALL start from a selected git ref in a disposable worktree below
`tmp/harness-worktrees/`, invoke Codex with JSON output and workspace-write
sandboxing, and preserve a trace plus metadata under `tmp/harness-runs/`.

#### Scenario: Start a harness run
- **GIVEN** a valid case and an available Codex executable
- **WHEN** a developer runs `bin/harness-run --case <id>`
- **THEN** the runner invokes `codex exec --json --sandbox workspace-write`
  with the case prompt in an isolated worktree
- **AND THEN** it records the case, base ref, variant, harness hash, elapsed
  time, trace path, and cleanup status

#### Scenario: Refuse an unsafe worktree location
- **GIVEN** a caller supplies a worktree path outside `tmp/harness-worktrees/`
- **WHEN** the runner validates its options
- **THEN** it exits non-zero before invoking Codex

### Requirement: Mechanical graders SHALL produce composable results
The harness SHALL expose independent graders for diff scope, manual schema
edits, and required command evidence. Each grader SHALL emit machine-readable
JSON with a pass/fail result and evidence, and `harness-eval grade` SHALL
combine those results into a run-level `grade.json`.

#### Scenario: Grade a completed run
- **GIVEN** a run directory contains metadata, a trace, and a worktree
- **WHEN** a developer runs `bin/harness-eval grade --case <id> --run-dir <dir>`
- **THEN** every configured grader runs and the output records each result,
  aggregate pass/fail, and changed-file evidence

#### Scenario: Detect a forbidden schema edit
- **GIVEN** a run changes `db/structure.sql`
- **WHEN** the no-manual-schema grader runs
- **THEN** it fails with the changed path as evidence

### Requirement: Experiment reporting SHALL expose human and mechanical metrics
The harness SHALL define a CSV result schema and a report command that shows
pass/fail, diff scope, human correction minutes, instruction violations,
skipped required gates, execution time, tool calls, token metrics, RTK savings,
and harness hash when values are available.

#### Scenario: Render a comparison report
- **GIVEN** the experiment CSV contains rows for two variants
- **WHEN** a developer runs `bin/harness-eval report`
- **THEN** the command writes a Markdown report with one row per experiment
  and includes the comparison fields without requiring identical diffs

#### Scenario: Preserve unmeasured values
- **GIVEN** a trace does not expose token or RTK metrics
- **WHEN** a run is recorded
- **THEN** those fields remain blank or `unknown` and the report does not
  invent a measurement
