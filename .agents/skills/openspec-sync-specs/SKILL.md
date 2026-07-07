---
name: openspec-sync-specs
description: Sync delta specs from a change to main specs. Use when the user wants to update main specs with changes from a delta spec, without archiving the change.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

# OpenSpec Sync Specs

Sync delta specs from an active change into main specs.

## Routeprint Rules

- Run OpenSpec through `bin/openspec ...`; never use bare `openspec`.
- This is an agent-driven merge, not a blind copy.
- Preserve main-spec content not mentioned by the delta.
- Stop on `workspace-planning`; this slice does not sync linked workspaces.
- For ambiguous, high-risk, first-time, or generator-drift cases, read
  `references/sync-specs.md` before acting.

## Steps

1. Resolve the change name. If omitted or ambiguous, run
   `bin/openspec list --json` and ask the user to choose.
2. Run `bin/openspec status --change "<name>" --json`.
3. Use `artifactPaths.specs.existingOutputPaths` as the delta spec list.
4. For each delta spec, read the delta and matching main spec at
   `openspec/specs/<capability>/spec.md`.
5. Write a compact merge plan per requirement before editing:
   ADDED, MODIFIED, REMOVED, or RENAMED; before state; after state; preserved
   scenarios.
6. Apply only the intended requirement/scenario changes.
7. Re-read the main spec and verify the same delta would make no second-pass
   changes.
8. Summarize updated capabilities and idempotency.

## Output

```text
Change:
Capabilities:
Requirement changes:
Preserved:
Idempotency:
Next step:
```
