# Sync Specs Detailed Workflow

Use this reference when delta specs include modifications, removals, renames, or
overlap with existing main specs.

## Delta Sections

If the user names a standalone OpenSpec store, or the work clearly lives in one,
run `bin/openspec store list --json` and pass `--store <id>` to commands that
read or write specs and changes.

OpenSpec delta specs may contain:

- `## ADDED Requirements`
- `## MODIFIED Requirements`
- `## REMOVED Requirements`
- `## RENAMED Requirements`

Read the delta and the matching main spec before editing.

## Merge Rules

- ADDED: add absent requirements; if the requirement already exists, treat as
  MODIFIED.
- MODIFIED: update only the named requirement/scenarios and preserve everything
  not mentioned.
- REMOVED: remove the whole named requirement block.
- RENAMED: rename the matching requirement from FROM to TO without losing
  scenarios.

The delta expresses intent, not a wholesale replacement.

## Merge Plan

Before editing, record per requirement:

- capability
- delta section
- requirement name before
- requirement name after
- scenarios to add, modify, preserve, remove, or rename
- expected main-spec result

## Idempotency

After editing, re-read the main spec and mentally re-apply the same delta. If a
second pass would change anything, fix the merge before moving on. Summaries
must include `Idempotency: no second-pass changes`.
