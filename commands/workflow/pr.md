---
description: "Push current branch and open a PR. Idempotent -- safe to re-run."
disable-model-invocation: true
argument-hint: "[--draft] [--title 'Custom title']"
allowed-tools: Bash(git *), Bash(gh *), Bash(curl *)
effort: low
---

## Context

- Remote URL: !`git remote get-url origin 2>/dev/null`
- Current branch: !`git branch --show-current`
- Default branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main"`
- Commits on this branch: !`DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main); git log origin/$DEFAULT..HEAD --oneline 2>/dev/null`

## Provider Detection

Detect from Remote URL: `github.com` → **GitHub** (use `gh`). Anything else → **Bitbucket DC** (use `curl` + `$BITBUCKET_TOKEN` + REST API v1.0).

## Arguments

`$ARGUMENTS`

## Task

### Step 1: Pre-flight

- **Auth**: GitHub → `gh auth status`. Bitbucket DC → check `$BITBUCKET_TOKEN` is set.
- Abort if on default branch.
- Check for existing open PR for this branch (GitHub: `gh pr list --head`, Bitbucket: `GET .../pull-requests?state=OPEN&at=refs/heads/{branch}`). If exists: report URL and stop.

### Step 2: Rebase and Push

1. `git fetch origin && git rebase origin/<default-branch>`
2. If conflict: `git rebase --abort`, report files, stop.
3. `git push --force-with-lease --force-if-includes -u origin HEAD`

### Step 3: Create PR

Parse branch/commits for issue refs (`#\d+`). Include `Closes #N` (GitHub) or reference in description (Bitbucket).

- **GitHub**: `gh pr create --fill` (add `--draft` / `--title` from `$ARGUMENTS`)
- **Bitbucket DC**: `POST /rest/api/1.0/projects/{proj}/repos/{repo}/pull-requests` with `title`, `description`, `fromRef`, `toRef`

Report the PR URL.
