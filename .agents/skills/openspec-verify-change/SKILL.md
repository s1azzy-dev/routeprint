---
name: openspec-verify-change
description: Verify implementation matches change artifacts. Use when the user wants to validate that implementation is complete, correct, and coherent before archiving.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

# OpenSpec Verify Change

Verify that implementation matches OpenSpec artifacts.

## Routeprint Rules

- Run OpenSpec through `bin/openspec ...`; never use bare `openspec`.
- This skill produces an agentic report. Only OpenSpec validation, tests, and
  project gates from `docs/DEVELOPMENT.md` prove readiness.
- Stop on `workspace-planning`; this slice does not verify linked workspaces.
- For ambiguous, high-risk, first-time, or generator-drift cases, read
  `references/verify-change.md` before acting.

## Steps

1. Resolve the change name. If omitted or ambiguous, run
   `bin/openspec list --json` and ask the user to choose.
2. Run `bin/openspec status --change "<name>" --json`.
3. Run `bin/openspec instructions apply --change "<name>" --json`.
4. Read every artifact path in `contextFiles`.
5. Check completeness: task checkboxes, requirements, scenarios.
6. Map requirements and scenarios to code/spec evidence with targeted search.
7. Check design coherence and project pattern fit.
8. Record required mechanical proof:
   - `bin/openspec validate <change> --strict` or
     `bin/openspec validate --all --strict`
   - narrow specs/tests required by the change
   - applicable `docs/DEVELOPMENT.md` verification gate
9. Group findings as CRITICAL, WARNING, or SUGGESTION. Use CRITICAL only for
   objective artifact, task, spec, or gate blockers.

## Output

```text
Change:
Mechanical proof:
Completeness:
Agentic mapping:
Coherence:
Critical:
Warnings:
Suggestions:
Ready to archive: yes/no
```
