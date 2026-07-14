# AGENTS.md

## Purpose

This is the always-loaded Codex control plane for Routeprint. Keep it short.
Use it to choose the right source of truth, permission level, and verification
path. Do not duplicate detailed project rules here.

## Source Map

| Need | Read |
| --- | --- |
| Context loading by task area | `docs/CONTEXT_MAP.md` |
| Agent workflow, commands, permissions, verification | `docs/DEVELOPMENT.md` |
| Product scope, architecture, domain, database, PostGIS | `docs/FOUNDATIONS.md` |
| Security, testing policy, CI and merge gates | `docs/QUALITY_SECURITY.md` |
| Feature intent, acceptance behavior, active changes | `openspec/specs/`, `openspec/changes/` |
| Known unimplemented work | `docs/TODO.md` |
| Durable architecture decisions | `docs/adr/` |
| Frontend design workflow and UI composition | `docs/frontend/DESIGN_GUIDE.md` |

Load only the documents needed for the active task. Do not create extra feature
docs unless explicitly requested.

## Always-On Rules

- Start every repository task with the Fast Path in `docs/DEVELOPMENT.md`; use
  the routed SDD skill only when level, risk, scope, or handoff requires it.
- Inspect neighboring files before editing and follow the local pattern.
- Read the related baseline spec before changing established behavior.
- Behavior-changing work uses red test, minimal code, green test.
- Keep MVP user-facing behavior flight-first.
- Put business use cases in `app/interactors` as explicit, fail-fast `yabi`
  pipelines; use the routed project skill for the detailed style contract.
- Require explicit authorization for every user-owned travel resource.
- Treat Inertia props as a public response surface.
- Never edit `db/structure.sql` by hand.
- Run app/runtime commands through Make/container targets; use the host shell
  only for file search, git inspection, editing, Docker orchestration, and
  documented host-only tooling.
- For frontend formatting, use `make agent-frontend-format` for checks and
  `make agent-frontend-format-fix FILES='path/to/file.tsx ...'` for explicit
  fixes. Never run raw `prettier --write` commands.
- Use RTK-backed host commands and `make agent-*` targets first for broad
  search, logs, diffs, and diagnostics.
- Keep `CHANGES.md` current for meaningful behavior, schema, dependency,
  process/harness, or user-facing changes; do not add entries for every typo or
  micro-edit.

## Hard Stops

- Do not push to `main`.
- Do not store or log secrets, credentials, passwords, reset tokens, signed blob
  tokens, raw import payload secrets, or booking references.
- Do not disable CSRF.
- Do not skip authorization on user-owned resources.
- Do not add gems, external services, new architecture patterns, triggers,
  stored procedures, or broad future-mode abstractions without approval.
- Do not build AI, offline-first, native mobile, public API, live tracking, or
  real-time MVP features without explicit approval.

## Done

A task is done only after the applicable verification from
`docs/DEVELOPMENT.md` has passed or the remaining failure is clearly explained.
