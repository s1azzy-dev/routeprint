---
name: openspec-update-change
description: Revise an existing OpenSpec change's planning artifacts and reconcile them after a decision or discovery. Use for plan revisions or coherence reviews. Integration refresh uses make openspec-update instead.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.16.0"
---

# OpenSpec Update Change

Reconcile an existing change's planning artifacts before resuming implementation.

## Routeprint Rules

- Run OpenSpec through `bin/openspec ...`; never use bare `openspec`.
- Edit planning artifacts only. Hand implementation to `$openspec-apply-change`.
- Reuse explicit authorization for the requested edits. Present coherence edits
  outside that scope for confirmation before writing.
- Start a new change when intent changes or added work can ship independently.
- Stop on `workspace-planning`; this skill does not revise linked workspaces.
- For ambiguous, high-risk, first-time, or generator-drift cases, read
  `references/update-change.md` before acting.

## Steps

1. Resolve the change from the request or current context. If ambiguous, run
   `bin/openspec list --json` and ask the user to choose.
2. Run `bin/openspec status --change "<name>" --json` and use its schema,
   planning root, artifact ids, and concrete `existingOutputPaths`.
3. Read the affected artifacts and their existing dependencies. Draft the
   requested revision and reconcile related artifacts in both directions.
4. Show the proposed edits and obtain any missing confirmation. Before a
   substantial rewrite, fetch that artifact's `instructions` and rules.
5. Edit concrete existing paths. Leave skipped and wholly unstarted artifacts
   untouched. For a missing companion of a partly populated glob artifact, use
   the reference's instruction, path, confirmation, and exclusive-create checks.
6. Preserve completed tasks that still hold. Reopen invalidated work and name
   verification that must be rerun. Validate the revised change with
   `bin/openspec validate "<name>" --strict` and show its requirement diff.
7. Report revisions, deferred artifacts, and the next applicable workflow.
   A plan revision alone authorizes no application-code changes.

## Output

```text
Change:
Revised artifacts:
Deferred:
Verification to rerun:
Validation:
Next step:
```
