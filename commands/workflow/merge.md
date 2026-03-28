---
description: "Enable auto-merge on the current branch's open PR."
disable-model-invocation: true
argument-hint: "[--squash | --rebase | --merge] [--pr-number N]"
allowed-tools: Bash(git *), Bash(gh *), Bash(curl *), Bash(sleep *)
effort: low
---

## Context

- Remote URL: !`git remote get-url origin 2>/dev/null`
- Current branch: !`git branch --show-current`

## Provider Detection

Detect from Remote URL: `github.com` → **GitHub** (use `gh`). Anything else → **Bitbucket DC** (use `curl` + `$BITBUCKET_TOKEN`).

## Arguments

`$ARGUMENTS`

## Task

### Step 1: Resolve the PR

- Use `--pr-number N` from `$ARGUMENTS` if provided.
- Otherwise find PR for current branch (GitHub: `gh pr list --head`, Bitbucket: `GET .../pull-requests?state=OPEN&at=refs/heads/{branch}`).
- If no open PR: abort "No open PR found. Run `/pr` first."

### Step 2: Enable auto-merge

- **GitHub**:
  1. Check `gh api repos/{owner}/{repo} --jq '.allow_auto_merge'`. If false: abort "Enable auto-merge in GitHub Settings > General."
  2. Detect strategy from `$ARGUMENTS` or repo settings (prefer squash).
  3. `gh pr merge <number> --auto --<strategy>`. On GraphQL error: retry once after 2s.
  4. Report: "Auto-merge enabled. PR will merge when all checks pass."

- **Bitbucket DC**: Report "Bitbucket DC does not support auto-merge natively. Merge manually when builds pass."
