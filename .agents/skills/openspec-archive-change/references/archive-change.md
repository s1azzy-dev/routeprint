# Archive Change Detailed Workflow

Use this reference when archive state is ambiguous, delta specs exist, artifacts
or tasks are incomplete, or the archive target may already exist.

## Preconditions

- Implementation has been verified against OpenSpec artifacts.
- `bin/openspec validate --all --strict` or the selected change validation has
  been recorded.
- Routeprint's selected project gate from `docs/DEVELOPMENT.md` has been
  recorded or the blocker is explicitly accepted.

## Selection And Status

If the user names a standalone OpenSpec store, or the work clearly lives in one,
run `bin/openspec store list --json` and pass `--store <id>` to commands that
read or write specs and changes.

Run:

```bash
bin/openspec list --json
bin/openspec status --change "<name>" --json
```

Use status JSON for `schemaName`, `planningHome`, `changeRoot`,
`artifactPaths`, `actionContext`, and artifact completion. Stop on
`workspace-planning`; this skill does not archive linked workspace work.

## Completion Warnings

- If any artifact is not done, list it and confirm before archive.
- If `tasks.md` has unchecked tasks, list the count and confirm before archive.
- If no task file exists, proceed without a task warning.

## Delta Spec Sync

- Use `artifactPaths.specs.existingOutputPaths` for delta specs.
- If none exist, archive without sync.
- If they exist, compare each delta with its main spec.
- Summarize adds, modifications, removals, and renames before prompting.
- If sync is chosen, use `$openspec-sync-specs` before archiving.

## Archive Operation

Archive to `planningHome.changesDir/archive/YYYY-MM-DD-<change-name>`.
Create the archive directory if needed. Do not overwrite an existing archive
target; stop and report the conflict.
