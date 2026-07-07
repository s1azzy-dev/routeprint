# Apply Change Detailed Workflow

Use this reference only when the compact skill is not enough: first execution in
this repo, ambiguous change selection, unusual OpenSpec status JSON,
workspace-planning, or implementation that changes approved intent.

## Selection

- If the user names a standalone OpenSpec store, or the work clearly lives in
  one, run `bin/openspec store list --json` and pass `--store <id>` to commands
  that read or write specs and changes.
- If the user names a change, use it.
- If conversation context clearly names one change, use it and state the name.
- If multiple active changes could match, run `bin/openspec list --json` and
  ask the user to choose.
- If only one active change exists, it is acceptable to select it, but state how
  to override.

## Status And Instructions

Run:

```bash
bin/openspec status --change "<name>" --json
bin/openspec instructions apply --change "<name>" --json
```

Read status fields as authority for:

- `schemaName`
- `planningHome`
- `changeRoot`
- `actionContext`
- task artifact identity

Read instruction fields as authority for:

- `contextFiles`
- task progress
- dynamic instruction
- blocked or all-done state

Stop if `actionContext.mode` is `workspace-planning` and there are no allowed
edit roots. Do not infer repo-local paths.

## Implementation Loop

- Read every path listed in `contextFiles` before editing.
- Work one pending task at a time.
- Keep each task minimal and scoped.
- Mark `- [ ]` to `- [x]` immediately after the task is complete.
- If implementation disproves an artifact assumption, pause and update the
  affected artifact before divergent coding continues.
- If approval is required by Routeprint permissions, stop before mutation.

## Completion

Report completed tasks, total progress, remaining tasks, verification already
run, and next safe action. Suggest archive only after all tasks and required
mechanical checks are complete.
