## 1. Registry and documentation

- [x] 1.1 Add the 12-case YAML registry and separate prompt files covering the audit's Level 0-3, security, schema, tooling, and UI scenarios.
- [x] 1.2 Add correctness, minimality, and security human rubrics, experiment CSV schema, lessons guidance, and harness README.

## 2. Execution and grading

- [x] 2.1 Implement registry validation and Markdown report generation in `bin/harness-eval`.
- [x] 2.2 Implement the disposable-worktree `bin/harness-run` with JSONL capture, metadata, harness hash, cleanup, and optional CSV row recording.
- [x] 2.3 Implement JSON mechanical graders for diff scope, manual schema edits, and required command evidence.

## 3. Regression coverage and integration

- [x] 3.1 Add tooling specs covering registry completeness, ignored raw paths, executable entrypoints, grader protocol, and report fields.
- [x] 3.2 Update `CHANGES.md` and `.gitignore`, then validate the harness registry and strict OpenSpec artifacts.
- [x] 3.3 Run the focused tooling specs, `make verify-fast`, and the full applicable project verification; record any environment blocker.
