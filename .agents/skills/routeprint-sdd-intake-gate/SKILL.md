---
name: routeprint-sdd-intake-gate
description: Use for Routeprint tasks with unclear level, data/security/schema risk, likely Level 2-3 scope, or a compaction handoff. Do not invoke for clear Level 0-1 work covered by the DEVELOPMENT.md Fast Path.
---

# Routeprint SDD Intake Gate

## Purpose

Run the project intake gate when the Fast Path cannot safely route the task.
This skill does not implement the task and does not replace project docs; it
turns an uncertain request into a short, auditable packet and routes it to the
correct workflow.

## Load The Control Plane

If not already loaded in this turn:

1. Read `AGENTS.md`.
2. Read the `Fast Path` heading in `docs/DEVELOPMENT.md` and classify the task.
3. For Level 0, read only the owning source of truth and the named check. For
   Level 1, read one relevant workflow section plus the task-specific row from
   `docs/CONTEXT_MAP.md`. For Level 2–3, load the full sections and artifacts
   required by the spec-driven lifecycle.
4. Read only the relevant rows from `docs/CONTEXT_MAP.md` after classifying the
   task area.

Do not scan the whole repository unless the user asked for repository-wide work
or classification cannot be resolved from the owning docs and neighboring files.

## Budget Context

Before reading more files or running repeated checks, set a small budget:

```text
Context budget: tiny | normal | broad
Already loaded:
Do not reload:
Already checked:
Skip now because:
```

- Use `tiny` for Level 0, copy, small docs/process, or one-file questions.
- Use `normal` for bounded implementation or review in one feature area.
- Use `broad` only for repository-wide analysis, security scans, architecture
  discovery, or explicit audits.

Do not re-read a file, re-run a search, or re-run a verification command when a
fresh result is already in the active turn or compaction handoff. Reuse the
recorded evidence unless the file changed, the branch changed, the command was
invalidated, or the user asks for a fresh run.

## Classify Before Action

Before tests, implementation edits, generated artifacts, or task-specific app
commands, classify the request:

| Level | Use for | OpenSpec/ADR |
| --- | --- | --- |
| 0: Non-functional maintenance | Documentation, process rules, comments, formatting, skill text, or other edits that do not change runtime behavior, product acceptance criteria, schema, dependencies, or security posture | none |
| 1: Direct | Copy, visual polish, obvious narrow bugs, small contract-preserving refactors, evidence-backed baseline corrections | none |
| 2: Specified feature | Meaningful behavior, interacting mechanisms, uncertain requirements, persistent acceptance criteria | OpenSpec change |
| 3: Architectural feature | Level 2 plus a durable, cross-cutting, difficult-to-reverse decision | OpenSpec change plus ADR for the confirmed architecture decision |

If the user explicitly opts out of SDD or OpenSpec, record that as a scoped
exception for this task only. Do not treat it as a new default.

## Emit The Task Packet

Use the smallest packet that preserves the decision and verification path:

- Level 0: keep `Level 0 | no behavior | no approval | git diff --check`
  internal; do not emit a packet to the user.
- Level 1: emit only `Goal`, `Behavior change`, `Approval`, and `Verification`.
- Level 2–3: emit the full packet below.

For Level 2–3, state this packet before mutation. Keep it factual and compact.

```text
Task:
Task type:
SDD level: 2 | 3
OpenSpec change: change-name
ADR: none | required | path
Behavior change: yes/no
Risk class: low | medium | high
Context budget: normal | broad
Docs loaded:
Context map entries used:
Neighboring files to inspect:
Already loaded:
Do not reload:
Already checked:
Skip now because:
Red test required: yes/no
Approval required: yes/no
Planned verification:
Done condition:
```

Use the packet as the handoff shape after compaction, approval waits, or long
tool runs.

## Route The Work

Use project-local skills and docs before global role skills. Do not layer broad
generic planning, delivery, coding, review, or frontend-design skills on top of
this gate for ordinary Routeprint work; route through the SDD level, context
map, and the narrow project skill instead.

- **Level 0:** use the Fast Path directly. Edit the owning source of truth and
  run `git diff --check`; update `CHANGES.md` only for meaningful process or
  harness behavior.
- **Level 1:** inspect neighboring files and existing specs, keep the change
  narrow, use a red test when runtime behavior changes, and run the matching
  verification from `docs/DEVELOPMENT.md`.
- **Level 2:** invoke `$routeprint-spec-driven-change` for explore, confirmed
  proposal, apply, verify, and archive. Do not create OpenSpec artifacts before
  the user confirms the explored direction.
- **Level 3:** follow Level 2 and create or update an ADR only for the confirmed
  durable architecture decision. Keep feature behavior and task lists in
  OpenSpec.

When implementation learning changes approved intent, pause. Update the
affected OpenSpec artifact or ADR and obtain approval before divergent coding
continues.

## Choose Commands Up Front

Select the command environment before running task-specific commands:

- Use the host shell for `rg`, `sed`, git inspection, file reads, `apply_patch`,
  Docker orchestration, and project-local OpenSpec wrappers.
- Use documented RTK-backed host commands and `make agent-*` targets first for
  broad discovery, noisy search, orientation diffs, git history, Docker logs,
  and compact runtime feedback. Use raw output only after narrowing the scope or
  when exact evidence is needed.
- Use Make/container targets for Rails, Ruby, Bundler, RSpec, RuboCop, security
  checks, frontend install/build/test/audit, migrations, imports, and dependency
  freshness.
- Use `bin/openspec ...` or documented Make OpenSpec targets inside this
  checkout; do not use a bare `openspec` command.
- Do not try raw host `bundle`, `rails`, `rspec`, `rubocop`, `brakeman`,
  `bundler-audit`, `npm`, `npx`, `vite`, or `tsc` for app work.
- If a command returns truncated output, an `Original token count` warning, or
  broad unrelated matches, stop and narrow the next command instead of reading
  more raw output.

If a command requires approval under the permission matrix, stop and ask before
running it.

## Approval Stops

Ask before:

- adding a gem, package, external service, or runtime dependency;
- introducing a new architecture pattern or broad future abstraction;
- changing authentication, authorization, session, cookie, upload, secret, or
  user-owned-resource behavior;
- creating triggers, stored procedures, or non-obvious database constraints;
- running destructive cleanup;
- pushing, publishing, or opening a PR unless the user explicitly requested it.

Hard stops from `AGENTS.md` and `docs/DEVELOPMENT.md` still apply even when the
user asks for speed.

## Finish

Before claiming completion:

1. Run the planned verification or report the exact blocker.
2. Do not re-run a green check only to have fresh-looking output; re-run only
   when touched files or dependencies invalidated it.
3. Check whether `CHANGES.md` is required.
4. Summarize files changed, verification commands and results, remaining
   failures or skipped checks, and branch/PR details when applicable.

Do not present heuristic inspection as mechanical proof. Tests, strict
OpenSpec validation, and project gates are the readiness proof.
