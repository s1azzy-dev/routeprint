# Explore Detailed Workflow

Use this reference when discovery is broad, product risk is unclear, or a
pending OpenSpec change may already own the decision.

## Stance

- Explore, do not implement.
- Ask questions that reduce product, security, data, or architecture risk.
- Ground discussion in the smallest useful code/spec slice.
- Compare options only when there is a real choice.
- Do not force artifacts before the user confirms direction.

## Existing Change Context

If the user names a standalone OpenSpec store, or the work clearly lives in one,
run `bin/openspec store list --json` and pass `--store <id>` to commands that
read specs, changes, status, context, or validation.

Run `bin/openspec list --json` when active changes could affect the topic. If a
change is named or likely relevant, run:

```bash
bin/openspec status --change "<name>" --json
```

Read existing artifact paths returned by status. Reference those artifacts in
conversation instead of relying on memory.

## Investigation

- Start from `docs/CONTEXT_MAP.md`.
- Read related main capability specs before changing established behavior.
- Inspect active changes before creating a new one.
- Search narrowly for integration points, current tests, and ownership
  boundaries.
- Surface unknowns around auth, privacy, migrations, retries, PostGIS,
  performance, operations, rollback, and verification.

## Capture Decisions

- Requirement change: delta spec.
- Scope or non-goal: `proposal.md`.
- Design decision: `design.md`.
- Durable Level 3 architecture: ADR after confirmation.
- New implementation work: `tasks.md`.
- Invalidated assumption: affected artifact before coding continues.

End with problem, recommendation, risks, open question, and whether the idea is
ready for proposal.
