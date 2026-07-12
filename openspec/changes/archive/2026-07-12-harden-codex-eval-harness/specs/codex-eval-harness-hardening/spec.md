## ADDED Requirements

### Requirement: Eval runs SHALL be bounded and reproducible
The runner SHALL record a terminal status, partial trace paths, timeout,
interrupt, cleanup, Codex command/version, sandbox, base commit, prompt hash,
registry hash, and source-only harness hash. Codex SHALL run ephemerally.

#### Scenario: Complete a bounded run
- **GIVEN** a valid case and available Codex executable
- **WHEN** the runner finishes before the case timeout
- **THEN** metadata records `completed` or `failed`, the exact command,
  version, hashes, elapsed time, and cleanup status

#### Scenario: Timeout a stuck run
- **GIVEN** Codex does not finish before the configured timeout
- **WHEN** the timeout expires
- **THEN** the runner terminates the process group, records `timeout`, writes
  partial stdout/stderr evidence, and does not leave the run in `preparing`

### Requirement: Scope graders SHALL include all repository file states
The harness SHALL grade tracked, staged, and untracked files and SHALL support
explicit any/all required path groups and expected housekeeping files.

#### Scenario: Include an untracked required spec
- **GIVEN** a run creates a new request spec without staging it
- **WHEN** the diff-scope grader runs
- **THEN** the spec appears in changed-file evidence and satisfies its matching
  required pattern

#### Scenario: Distinguish any and all requirements
- **GIVEN** a case requires at least one documentation file but allows `README.md`
  or `docs/TODO.md`
- **WHEN** only `README.md` changes
- **THEN** the case passes its `files_any` requirement

### Requirement: Required command grading SHALL use structured exit evidence
The tests grader SHALL distinguish missing, attempted-failed, blocked, and
passed commands. Textual presence of a command SHALL NOT be sufficient.

#### Scenario: Reject a failed required gate
- **GIVEN** the trace contains `make verify-fast` with exit code 2
- **WHEN** the tests grader evaluates the case
- **THEN** that gate is marked failed and the aggregate grader does not pass

#### Scenario: Accept a successful required gate
- **GIVEN** the trace contains a matching command execution with exit code 0
- **WHEN** the tests grader evaluates the case
- **THEN** that gate is marked passed with its command evidence

### Requirement: Workflow and behavior expectations SHALL be inspectable
The harness SHALL grade expected SDD level, skill activation, OpenSpec use,
approval-stop evidence, and declared static behavior assertions. Human review
fields SHALL remain explicitly separate from mechanical proof.

#### Scenario: Detect missing approval evidence
- **GIVEN** a case declares `approval_required: true`
- **WHEN** the workflow grader finds no approval-stop evidence
- **THEN** the workflow result fails with the missing expectation

#### Scenario: Record human correctness review
- **GIVEN** a completed run has mechanical grade evidence
- **WHEN** a reviewer records correctness, minimality, security, behavior
  notes, and correction minutes
- **THEN** `harness-eval review` appends a review row without changing the raw
  trace or mechanical grade

### Requirement: Reports SHALL preserve trustworthy comparison fields
The report SHALL include mechanical aggregate status, workflow/behavior status,
changed-file scope, gate statuses, timeout state, stable hash, token metrics,
and explicit `unknown` values for unreviewed human fields. The registry SHALL
define a cheap smoke profile.

#### Scenario: Render a smoke profile
- **WHEN** a developer asks the harness to list or run the smoke profile
- **THEN** it exposes the named representative cases without requiring the
  full 12-case suite

#### Scenario: Compare source-stable runs
- **GIVEN** two runs append different experiment rows
- **WHEN** their metadata hashes are compared
- **THEN** the source harness hash remains equal unless harness source changed
