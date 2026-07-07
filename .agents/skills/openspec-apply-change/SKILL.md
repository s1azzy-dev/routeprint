---
name: openspec-apply-change
description: Implement tasks from an OpenSpec change. Use when the user wants to start implementing, continue implementation, or work through tasks.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

# OpenSpec Apply Change

Apply tasks from an approved OpenSpec change.

## Routeprint Rules

- Run OpenSpec through `bin/openspec ...`; never use bare `openspec`.
- Keep the SDD gate, permission matrix, red/green loop, domain skills, and Make
  verification from `docs/DEVELOPMENT.md`.
- Use paths returned by OpenSpec JSON. Do not assume repo-local paths when the
  status says `workspace-planning`.
- For ambiguous, high-risk, first-time, or generator-drift cases, read
  `references/apply-change.md` before acting.

## Steps

1. Resolve the change name from the request or current context. If ambiguous,
   run `bin/openspec list --json` and ask the user to choose.
2. Run `bin/openspec status --change "<name>" --json`; stop if workspace
   planning has no allowed edit roots.
3. Run `bin/openspec instructions apply --change "<name>" --json`.
4. Read every path in `contextFiles`.
5. Show schema and compact task progress.
6. Implement pending tasks one at a time, keeping edits focused.
7. Mark each completed task checkbox immediately.
8. Pause if a task is unclear, a design assumption fails, approval is required,
   or a blocker appears.

## Output

```text
Change:
Schema:
Progress:
Completed this session:
Paused because:
Next step:
Verification:
```

Mechanical checks, tests, and project gates are the readiness proof; agentic
task mapping is only advisory evidence.
