# Propose Detailed Workflow

Use this reference when creating a change for the first time, when generated
instructions are unfamiliar, or when artifact dependencies are non-obvious.

## Name And Scope

- If the user names a standalone OpenSpec store, or the work clearly lives in
  one, run `bin/openspec store list --json` and pass `--store <id>` to commands
  that create, read, or validate specs and changes.
- Require a clear user-confirmed direction.
- Derive a kebab-case change name from that direction.
- If a change with that name exists, ask whether to continue or rename.
- Do not use TODO text as acceptance criteria; turn confirmed intent into
  proposal/spec/design/tasks.

## Create And Inspect

Run:

```bash
bin/openspec new change "<name>"
bin/openspec status --change "<name>" --json
```

Use status JSON for `applyRequires`, artifact dependency order,
`planningHome`, `changeRoot`, `artifactPaths`, and `actionContext`.

## Artifact Loop

For each ready artifact:

```bash
bin/openspec instructions <artifact-id> --change "<name>" --json
```

- Treat `context` and `rules` as agent constraints, not artifact text.
- Use `template` for the artifact structure.
- Write to `resolvedOutputPath`.
- Read completed dependency artifacts before creating the next artifact.
- Re-run status after each artifact.
- Continue until all `applyRequires` artifacts are done.

## Quality Bar

Proposal explains what and why. Specs contain observable behavior and scenarios.
Design captures implementation approach and tradeoffs. Tasks are concrete,
ordered, and verifiable. Ask for review before implementation.
