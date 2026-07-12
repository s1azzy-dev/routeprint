# Routeprint Codex eval harness

This is a small, repository-specific benchmark for the Routeprint Codex
workflow. It measures workflow selection, safety boundaries, verification
discipline, diff scope, and human correction—not general model quality.

## Validate and inspect

```sh
bin/harness-eval validate
bin/harness-eval list --profile smoke
bin/harness-eval report
```

The registry in `harness/evals/cases.yml` contains 12 cases. Each case points
to a prompt, expected SDD/skill/approval behavior, required commands and gates,
forbidden changes, mechanical graders, and human rubrics.

## Run a case

`bin/harness-run` is intentionally opt-in. It creates a disposable worktree
under `tmp/harness-worktrees/`, invokes ephemeral `codex exec --json
--sandbox workspace-write`, applies a per-case timeout, stores the JSONL trace
and metadata under `tmp/harness-runs/`, grades the result, and records cleanup.
It never commits or pushes the worktree.

```sh
bin/harness-run --case auth-suspended-session --variant full-sdd
bin/harness-eval grade --case auth-suspended-session --run-dir tmp/harness-runs/<run-id>
bin/harness-eval review --run-dir tmp/harness-runs/<run-id> --reviewer alice \
  --task-success true --correctness 3 --minimality 3 --security 3 \
  --correction-minutes 4
```

Use the same case, base ref, model settings, sandbox, and verification policy
when comparing variants. Change one factor at a time, for example full SDD vs
short SDD, skill vs no skill, RTK vs raw output, or reviewer vs single agent.

## Results and review

Use the smoke profile for normal iteration; it contains three representative
cases. Full coverage is explicit and expensive. Append experiment rows to
`harness/experiments/results.csv` and human review rows to
`harness/experiments/reviews.csv`. The report includes mechanical/workflow/
behavior status, changed-file scope, command gate statuses, timeout state,
correction minutes, token fields, and source-stable hashes. Blank human metrics
render as `unknown`; the harness does not invent measurements.

Do not commit raw traces or worktrees. Do not place secrets, reset tokens,
credentials, booking references, or private payloads in prompts, traces,
rubrics, lessons, or result notes.

## Skill trigger registry

`harness/skills/cases.yml` records positive and negative examples for every
Routeprint-specific router or domain skill. The mechanical harness check keeps
skill IDs unique, requires both polarities, and rejects unknown or missing
skills. Generated OpenSpec command adapters are intentionally outside this
registry because their own tooling specs validate their command contract.

The project does not add a new skill until its workflow has repeated at least
three times, has clear positive and negative triggers, cannot be inferred from
neighboring code, and shows measurable benefit in an eval or lower error rate.
