---
name: routeprint-sdd-intake-gate
description: Use only when Routeprint task level, risk, scope, or handoff is unclear; clear Level 0-1 work stays on the Fast Path.
---

# Routeprint SDD Intake Gate

Use this router only when the Fast Path in `docs/DEVELOPMENT.md` cannot safely
classify the task. It does not implement work or replace project docs.

Do not invoke for clear Level 0-1 work.

## Load

If not already loaded:

1. Read `AGENTS.md`.
2. Read the `Fast Path` heading and classification rules in
   `docs/DEVELOPMENT.md`.
3. Read only the relevant row in `docs/CONTEXT_MAP.md`.
4. For Level 2–3 uncertainty, inspect active OpenSpec changes and the required
   capability or domain artifacts.

Use a small context budget:

```text
Context budget: tiny | normal | broad
Already loaded:
Do not reload:
Already checked:
Skip now because:
```

Reuse fresh evidence from the active turn or compaction handoff unless the
file, branch, dependency set, or requested proof changed.

## Classify

| Level | Use for | Route |
| --- | --- | --- |
| 0 | Docs, process, comments, formatting, harness-only maintenance | Fast Path; no OpenSpec |
| 1 | Narrow copy, visual polish, obvious bug, contract-preserving refactor | Fast Path; no OpenSpec |
| 2 | Meaningful behavior, interacting mechanisms, uncertain acceptance | Spec-driven change; OpenSpec |
| 3 | Level 2 plus durable cross-cutting architecture | Spec-driven change plus ADR |

Ask one focused question only when a wrong assumption would create product,
security, data, schema, or architecture risk. Record a user opt-out of SDD or
OpenSpec as a task-local exception.

## Packet

Keep Level 0–1 internal. For Level 2–3, emit:

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
Neighboring files to inspect:
Red test required: yes/no
Approval required: yes/no
Planned verification:
Done condition:
```

## Route

- Level 0: edit the owning source and run `git diff --check`.
- Level 1: inspect neighbors, use the narrow gate, and add a red test only
  when runtime behavior changes.
- Level 2: explore and confirm direction before `$openspec-propose`, then use
  `$openspec-apply-change` and `$openspec-verify-change`.
- Level 3: follow Level 2 and promote only the confirmed architecture decision
  to an ADR.
- Add a domain skill only when the context map routes one; do not layer generic
  planning or delivery skills onto ordinary Routeprint work.

If implementation disproves approved intent, update the affected OpenSpec or
ADR and obtain approval before continuing with divergent behavior.

## Approval

Ask before adding dependencies or services, introducing architecture, changing
auth/session/authorization/upload/secret behavior, adding database procedures
or non-obvious constraints, destructive cleanup, or publishing.

Hard stops from `AGENTS.md` and `docs/DEVELOPMENT.md` still apply.

## Finish

Run the selected proof, check whether `CHANGES.md` is required, and report
changed files, checks, blockers, and skipped work. Never claim heuristic
inspection as mechanical proof.
