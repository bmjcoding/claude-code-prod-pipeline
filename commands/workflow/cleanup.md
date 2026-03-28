---
description: "Remove the current worktree and delete its local branch."
disable-model-invocation: true
argument-hint: "[--force]"
allowed-tools: Bash(git *), Bash(gh *), Bash(curl *), Bash(lsof *), Bash(kill *), Bash(xargs *)
effort: low
---

## Context

- Remote URL: !`git remote get-url origin 2>/dev/null`
- Current directory: !`pwd`
- Current branch: !`git branch --show-current`
- Worktree list: !`git worktree list`
- Main repo path: !`git rev-parse --git-common-dir 2>/dev/null | sed 's|/.git.*||'`

## Provider Detection

Detect from Remote URL: `github.com` → **GitHub** (use `gh`). Anything else → **Bitbucket DC** (use `curl` + `$BITBUCKET_TOKEN`).

## Arguments

`$ARGUMENTS`

## Task

### Step 1: Validate

- If current directory is the main checkout (not a worktree): abort "Navigate to a worktree first."
- Record worktree path, branch name, main repo path.

### Step 2: Check PR status (skip if `--force`)

Check if PR for this branch is merged:
- **GitHub**: `gh pr list --head <branch> --state merged --json number --jq '.[0]'`
- **Bitbucket DC**: `GET .../pull-requests?state=MERGED&at=refs/heads/{branch}`

If not merged and no `--force`: warn and stop. If no PR and no `--force`: warn and stop.

### Step 3: Kill processes and remove

1. `lsof +D <worktree_path> 2>/dev/null | awk 'NR>1{print $2}' | sort -u | xargs kill 2>/dev/null || true`
2. Sleep 1 second.
3. `cd <main_repo_path>`
4. `git worktree remove <path>` (fall back to `--force`)
5. `git branch -D <branch>`
6. `git worktree prune`

Report what was removed and remaining worktrees.
