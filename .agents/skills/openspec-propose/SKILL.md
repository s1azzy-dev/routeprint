---
name: openspec-propose
description: Propose a new change with all artifacts generated in one step. Use when the user wants to quickly describe what they want to build and get a complete proposal with design, specs, and tasks ready for implementation.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.16.0"
---

# OpenSpec Propose

Create a confirmed OpenSpec change and its required artifacts.

## Routeprint Rules

- Run OpenSpec through `bin/openspec ...`; never use bare `openspec`.
- Use after the user confirms direction for Level 2 or 3 work. An explicit
  artifact request with an already confirmed scope needs no extra explore round.
- Keep `context` and `rules` from OpenSpec instructions as constraints for the
  agent, not text copied into artifacts.
- For ambiguous, high-risk, first-time, or generator-drift cases, read
  `references/propose.md` before acting.

## Steps

1. Resolve a kebab-case change name from the confirmed request. Ask if unclear.
2. If the change exists, ask whether to continue it or choose a new name.
3. Run `bin/openspec new change "<name>"`.
4. Run `bin/openspec status --change "<name>" --json`.
5. For each ready artifact, run
   `bin/openspec instructions <artifact-id> --change "<name>" --json`.
6. Read dependency artifacts, then write the artifact at `resolvedOutputPath`
   using the returned template and Routeprint context.
7. Re-run status after each artifact until all `applyRequires` artifacts are
   done.
8. Validate the change with `bin/openspec validate "<name>" --strict` and show
   `bin/openspec show <name> --diff`. Present artifacts for implementation review.

## Output

```text
Change:
Location:
Artifacts created:
Apply ready: yes/no
Needs review:
Next step:
```
