# Verify Change Detailed Workflow

Use this reference when verification must decide archive readiness or when the
mapping from artifacts to code is uncertain.

## Proof Model

Agentic verification is advisory. Readiness is proven only by:

- strict OpenSpec validation
- narrow specs/tests required by the change
- the applicable Routeprint gate from `docs/DEVELOPMENT.md`
- exact reporting of unrelated blockers

## Inputs

If the user names a standalone OpenSpec store, or the work clearly lives in one,
run `bin/openspec store list --json` and pass `--store <id>` to commands that
read specs, changes, status, context, or validation.

Run:

```bash
bin/openspec status --change "<name>" --json
bin/openspec instructions apply --change "<name>" --json
```

Read every artifact path in `contextFiles`. Stop on `workspace-planning`.

## Report Dimensions

Completeness:

- task checkbox count
- requirements present
- scenarios present

Correctness:

- requirement-to-code mapping
- scenario-to-test mapping
- divergence from expected behavior

Coherence:

- design decisions followed or intentionally updated
- file locations and patterns match Routeprint conventions
- domain skills and permissions were applied

## Severity

- CRITICAL: incomplete tasks, missing mechanical proof, or mechanically proven
  missing implementation.
- WARNING: weak evidence, likely scenario gap, or spec/design divergence.
- SUGGESTION: pattern polish or maintainability improvement.

Every finding needs a concrete recommendation and file reference when possible.
