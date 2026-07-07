---
name: openspec-archive-change
description: Archive a completed change in the experimental workflow. Use when the user wants to finalize and archive a change after implementation is complete.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

# OpenSpec Archive Change

Archive a completed OpenSpec change.

## Routeprint Rules

- Run OpenSpec through `bin/openspec ...`; never use bare `openspec`.
- Archive only after implementation verification and the selected project gate
  are recorded.
- Stop on `workspace-planning`; this slice does not move linked workspaces.
- For ambiguous, high-risk, first-time, or generator-drift cases, read
  `references/archive-change.md` before acting.

## Steps

1. Resolve the change name. If omitted or ambiguous, run
   `bin/openspec list --json` and ask the user to choose.
2. Run `bin/openspec status --change "<name>" --json`.
3. Warn and confirm before proceeding with incomplete artifacts or tasks.
4. If delta specs exist, compare them with main specs and offer to sync before
   archiving.
5. Create the archive directory under `planningHome.changesDir`.
6. Move `changeRoot` to `archive/YYYY-MM-DD-<change-name>` only if that target
   does not already exist.
7. Summarize archive path, sync decision, warnings, and verification evidence.

## Output

```text
Change:
Schema:
Archived to:
Specs:
Warnings:
Verification:
```
