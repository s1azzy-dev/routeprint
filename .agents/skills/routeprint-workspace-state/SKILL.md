---
name: routeprint-workspace-state
description: Use when resuming, publishing, reviewing, or orienting inside the Routeprint repository before deciding what changed, what branch or PR is active, which files are staged or unstaged, and which verification results can be reused instead of repeated.
---

# Routeprint Workspace State

## Purpose

Create a cheap, factual workspace snapshot so the agent does not repeat the
same git, PR, diff, and verification discovery throughout a task.

Use this skill as a state reader, not as an implementation workflow. It does
not replace `routeprint-sdd-intake-gate`.

## Read Snapshot

Prefer this order and stop as soon as the task is oriented:

1. `git status -sb --untracked-files=all`
2. `git branch --show-current`
3. `git log -1 --oneline`
4. `git diff --stat` and `git diff --name-status` only when unstaged changes
   exist.
5. `git diff --cached --stat` and `git diff --cached --name-status` only when
   staged changes exist.
6. `gh pr view --json number,title,url,isDraft,headRefName,baseRefName` only
   when a PR matters and the branch appears pushed or tracking a remote.

Do not run broad history commands, full diffs, or GitHub checks unless the user
asked for them or the cheap snapshot leaves an ambiguity that affects the next
action.

## Output

Keep the snapshot compact:

```text
Branch:
Upstream:
Last commit:
PR:
Working tree:
Staged:
Unstaged:
Untracked:
Known verification:
Reusable evidence:
Needs fresh check:
Next safe action:
```

## Reuse Rules

- Reuse a verification result when it was run on the same branch after the
  touched files changed.
- Re-run a check when the command failed, the relevant files changed after the
  check, dependencies changed, the branch rebased, or the result came from a
  different checkout.
- Report known blockers exactly; do not hide them behind a new status query.
- Do not push, stage, commit, or edit files from this skill. Hand back to the
  active workflow after the snapshot.

## Gotchas

- `git diff --stat` omits untracked files. Pair it with `git status -sb
  --untracked-files=all` when new files matter.
- Staged renames plus unstaged edits can look like duplicate changes. Compare
  cached and working-tree name-status before staging again.
- Local branch state is not enough for stacked or already-open PRs. Check the
  PR metadata when publishing or rewriting an existing branch.
