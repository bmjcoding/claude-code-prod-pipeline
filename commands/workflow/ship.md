---
description: "Full ship: commit, push, open PR, optional auto-merge."
disable-model-invocation: true
argument-hint: "[--draft] [--auto-merge]"
allowed-tools: Bash(git *), Bash(gh *), Bash(curl *), Bash(sleep *)
effort: low
---

## Context

- Remote URL: !`git remote get-url origin 2>/dev/null`
- Current branch: !`git branch --show-current`
- Default branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main"`
- Git status: !`git status --short`
- Recent commits (for message style): !`git log --oneline -10`
- Commits on this branch not yet on default: !`DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main); git log origin/$DEFAULT..HEAD --oneline 2>/dev/null`
- Stale local branches (upstream gone): !`git fetch --prune 2>/dev/null; git branch -vv 2>/dev/null | grep ': gone]' | awk '{print $1}'`
- Worktrees: !`git worktree list 2>/dev/null`

## Provider Detection

Detect from Remote URL: `github.com` → **GitHub** (use `gh` CLI). Anything else → **Bitbucket Data Center** (use `curl` with `Authorization: Bearer $BITBUCKET_TOKEN` against REST API v1.0, parse project/repo from remote URL).

## Arguments

`$ARGUMENTS`

## Task

On any failure, stop and report the error so the user can resume.

**CRITICAL -- Performance**: Minimize tool calls. Each Bash call has round-trip overhead that dwarfs the actual command runtime. Batch independent commands into parallel Bash calls within a single message and chain dependent commands with `&&`. Target <=4 total tool calls for the entire flow.

### Call 1 (parallel batch -- all independent)

Run ALL of these as **separate parallel Bash calls in one message**:

1. **Auth + worktree prune**: `gh auth status && git worktree prune` (GitHub) or check `$BITBUCKET_TOKEN` (Bitbucket DC)
2. **Merged PRs + remote branches** (for cleanup): `MERGED=$(gh pr list --state merged --limit 200 --json headRefName --jq '.[].headRefName'); REMOTE=$(git branch -r | sed 's|origin/||' | sed 's/^[[:space:]]*//' | grep -v HEAD); echo "---MERGED---"; echo "$MERGED"; echo "---REMOTE---"; echo "$REMOTE"`
3. **Stale local branch cleanup**: For each stale local branch from context (upstream `gone`): **skip if it is the current branch**. Otherwise, if it has an associated worktree, remove the worktree (`git worktree remove --force <path>`), then delete the branch (`git branch -D <name>`). If none, skip.

After Call 1 returns: do pre-flight checks from the context data (branch validation, `$ARGUMENTS` checks, sensitive file scan). Compute the intersection of merged PRs and remote branches for cleanup.

### Call 2 (parallel batch)

Run as **parallel Bash calls in one message**:

1. **Delete stale remote branches** (if any from Call 1): `git push origin --delete <branch1> <branch2> ...` -- exclude default branch, current branch, `release/*`, `hotfix/*`. Skip if none.
2. **Commit** (skip if clean): `git add -u && git add . && git commit -m "<message>"` -- generate message matching repo style from context, append `Co-Authored-By: Claude <noreply@anthropic.com>`. Exclude sensitive files (`.env`, `*.key`, `*.pem`, `credentials.*`).

### Call 3 (sequential chain)

**Rebase + push + check existing PR** in one chain:
```
git fetch origin <default-branch> && git rebase origin/<default-branch> && git push --force-with-lease --force-if-includes -u origin HEAD && gh pr list --head <branch> --json number,url --jq '.[0]'
```
If rebase conflicts: `git rebase --abort`, report files, stop.

### Call 4 (if needed)

**Create PR** (skip if Call 3 found existing):
- Parse branch/commits for issue refs (`#\d+`). Include `Closes #N` (GitHub) or reference in description (Bitbucket).
- **GitHub**: `gh pr create --fill` (add `--draft` if flagged)
- **Bitbucket DC**: `POST /rest/api/1.0/projects/{proj}/repos/{repo}/pull-requests` with `title`, `description`, `fromRef`, `toRef`, `reviewers: []`

**Auto-merge** (only if `--auto-merge` and not `--draft`):
- **GitHub**: Check `gh api repos/{owner}/{repo} --jq '.allow_auto_merge'`. If true: detect merge strategy, run `gh pr merge <number> --auto --<strategy>`.
- **Bitbucket DC**: Inform "Bitbucket DC does not support auto-merge natively."

### Report

- Commit SHA, PR URL, auto-merge status
- Branches pruned (if any)
- Next `/ship` will auto-clean this branch after merge.
