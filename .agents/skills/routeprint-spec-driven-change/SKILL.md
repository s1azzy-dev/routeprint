---
name: routeprint-spec-driven-change
description: Use for Routeprint Level 2-3 work, or when task size, risk, or scope is uncertain and may require feature discovery, an OpenSpec change, or an ADR. Do not invoke for clear Level 0-1 work.
---

# Routeprint Spec-Driven Change

## Purpose

Select the lightest correct workflow and keep OpenSpec on top of the existing
Routeprint harness. Do not replace `AGENTS.md`, project docs, domain skills,
RSpec, or Make verification.

The `DEVELOPMENT.md` Fast Path handles clear Level 0-1 work. This skill owns
discovery and confirmation only when Level 2-3 artifacts may be needed.

## Classify First

Read `AGENTS.md` and the classification rules in `docs/DEVELOPMENT.md`.

| Level | Use for | Workflow |
| --- | --- | --- |
| 0: Non-functional maintenance | Documentation, process rules, comments, formatting, skill text, or other edits that change no runtime behavior, product acceptance criteria, schema, dependencies, or security posture | Classify, edit the owning source of truth, verify with docs/style gate; no OpenSpec change or ADR |
| 1: Direct | Copy, visual polish, obvious narrow bugs, small contract-preserving refactors | Existing project loop only |
| 2: Specified feature | Meaningful behavior, interacting mechanisms, uncertain requirements, persistent acceptance criteria | Explore, approve, propose, apply, verify, archive |
| 3: Architectural feature | Level 2 plus a durable, cross-cutting, difficult-to-reverse decision | Level 2 plus ADR promotion |

State the selected level and reason. Level 0 and Level 1 create no OpenSpec
change and no ADR.

For Level 0, identify the owning document or skill, make the narrow text change,
update `CHANGES.md` when the process or agent harness changes, and run
`git diff --check`.

## Discover Level 2 And 3 Work

1. Load only context selected by `docs/CONTEXT_MAP.md`, then inspect the relevant
   main capability specs, code, and tests.
2. Use `docs/TODO.md` only when the request selects unimplemented work; do not
   treat TODO text as acceptance criteria.
3. Run `bin/openspec list --json` to find related active changes.
4. Use `$openspec-explore` as the thinking stance.
5. Ask one focused question at a time. Do not create artifacts yet.
6. Challenge assumptions. Identify scope, non-goals, unknowns, and applicable
   data, authorization/privacy, migration, retry/idempotency, PostGIS/
   performance, operational, observability, and rollback risks.
7. Compare two or three credible approaches when the choice is non-obvious.
8. Summarize the recommended direction and ask the user to confirm it.

Do not invoke `$openspec-propose` until the user confirms the explored
direction.

## Create And Implement

After confirmation:

1. Invoke `$openspec-propose`. Use `bin/openspec` in place of bare `openspec` in
   every generated skill command.
2. Review proposal, specs, design, and tasks with the user before implementation.
3. For Level 3, create an ADR only for the confirmed durable architecture
   decision. Keep feature behavior and task detail in OpenSpec.
4. Invoke `$openspec-apply-change`.
5. Preserve the project permission matrix, domain skills, red/green loop, and
   verification matrix while applying tasks.

If implementation disproves an assumption, pause. Update the relevant proposal,
spec, design, or tasks and obtain approval for changed intent or architecture
before divergent implementation continues.

## Finish

Before archive:

1. Invoke `$openspec-verify-change`.
2. Run `bin/openspec validate --all --strict`.
3. Run the narrow specs and the applicable `docs/DEVELOPMENT.md` verification
   command.
4. Resolve critical mismatches, then invoke `$openspec-archive-change`.

Agentic verification informs judgment; only mechanical validation, tests, and
project gates provide blocking proof.
