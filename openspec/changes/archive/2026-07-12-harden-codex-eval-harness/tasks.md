## 1. Bounded execution and reproducibility

- [x] 1.1 Add case timeout/profile metadata and refactor `bin/harness-run` to use ephemeral, process-group-aware Codex execution with timeout/interrupt status and partial evidence.
- [x] 1.2 Record Codex version/command, base commit, prompt/registry/source hashes, sandbox, timeout, and stable source-only harness hash; exclude results/tmp artifacts.

## 2. Trustworthy grading

- [x] 2.1 Include tracked, staged, and untracked files in shared grader support; add `files_any`, `files_all`, `allowed_files`, and housekeeping semantics to the registry.
- [x] 2.2 Replace text-only command grading with structured exit-code evidence and explicit missing/failed/blocked/passed statuses.
- [x] 2.3 Add workflow and static behavior graders for SDD, skills, OpenSpec, approval evidence, and declared assertions.

## 3. Review, profiles, and reporting

- [x] 3.1 Add `harness-eval review` and a separate review CSV for human correctness, minimality, security, behavior notes, and correction minutes.
- [x] 3.2 Add smoke-profile listing/execution metadata and expand report/results fields with mechanical, workflow, behavior, timeout, and scope evidence.
- [x] 3.3 Narrow ambiguous cases, add behavior assertions/allowed files, and document the economical smoke-first workflow.

## 4. Regression coverage and verification

- [x] 4.1 Extend tooling specs with fake traces/worktrees covering untracked files, failed commands, timeout metadata, stable hashes, workflow/behavior review, and report output.
- [x] 4.2 Update `CHANGES.md`, validate the registry and strict OpenSpec artifacts, then run focused tooling specs and the applicable project gates without launching Codex cases.
