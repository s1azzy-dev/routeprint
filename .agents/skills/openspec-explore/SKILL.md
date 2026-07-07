---
name: openspec-explore
description: Enter explore mode - a thinking partner for exploring ideas, investigating problems, and clarifying requirements. Use when the user wants to think through something before or during a change.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

# OpenSpec Explore

Explore an OpenSpec-sized idea before artifacts or implementation.

## Routeprint Rules

- Run OpenSpec through `bin/openspec ...`; never use bare `openspec`.
- Explore mode may read and search, but must not edit application code.
- Do not create proposal/spec/design/tasks until the user confirms the explored
  direction, unless the user explicitly asks for artifact creation.
- Use project context from `docs/CONTEXT_MAP.md` and domain skills instead of a
  repository-wide scan.
- For ambiguous, high-risk, first-time, or generator-drift cases, read
  `references/explore.md` before acting.

## Steps

1. Run `bin/openspec list --json` when active changes could affect the topic.
2. If a change is named or clearly relevant, run
   `bin/openspec status --change "<name>" --json` and read existing artifacts
   from the returned paths.
3. Investigate only the narrow code/spec slice needed to clarify the decision.
4. Compare credible approaches when the choice is non-obvious.
5. Identify scope, non-goals, risks, unknowns, and required proof.
6. Ask one focused question at a time when user input is needed.
7. Summarize the recommended direction and ask for confirmation before
   proposal/apply work begins.

## Capture Map

| Discovery | Capture target |
| --- | --- |
| Requirement added or changed | Delta spec |
| Scope or non-goal changed | `proposal.md` |
| Durable design decision | `design.md` or ADR for Level 3 |
| Implementation task discovered | `tasks.md` |
| Assumption invalidated | Affected artifact before coding continues |

## Output

```text
Problem:
Relevant change:
Loaded:
Options:
Recommendation:
Risks:
Open question:
Ready for proposal: yes/no
```
