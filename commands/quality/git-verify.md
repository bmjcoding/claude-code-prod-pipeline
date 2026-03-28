Verify git hygiene and commit safety before pushing. Use parallel agents to maximize speed. Scope resolution, autonomy, and `--dry-run` rules are defined in CLAUDE.md.

## Check 0: Deterministic scan

Before agent analysis, run deterministic tooling if available (`gitleaks detect --no-git` or `trufflehog filesystem`). These catch encoded/rotated credentials that LLM pattern matching may miss. If neither tool is installed, proceed with agent scan only but note the gap in the report.

## Check 1: Secrets scan (parallel agents)

**Agent A -- Source code**: Scan changed files for hardcoded credentials (API keys, tokens, passwords, private keys, JWTs, embedded credentials in URLs). Supplements deterministic scan findings.

**Agent B -- Sensitive files**: Check for .env files, key/cert files, credential files, and large binaries (>5MB) in the diff.

Severity: Critical for actual secrets, High for sensitive file patterns.

## Check 2: Large files

Binary files >1MB, any file >10MB, build artifacts or node_modules that should be gitignored.

## Check 3: Commit quality

- Flag meaningless messages ("WIP", "fix", "update", single-word)
- Flag commits touching 5+ files with no description
- Flag merge commits that could have been rebased

## Check 4: Branch state

Behind remote? Uncommitted changes? Untracked files that belong in the commit?

## Auto-fix

Unstage sensitive files, suggest .gitignore additions. Do NOT rewrite commit history. **Note**: if a secret was already committed locally, unstaging alone does not remove it from git history. In that case, flag as Critical and instruct the user to reset the commit (`git reset --soft HEAD~1`) before pushing.

## Output

| # | Check | File/Commit | Issue | Severity | Status |
|---|-------|-------------|-------|----------|--------|

**If any Critical findings exist (secrets, credentials), this is a NO-SHIP condition. Do not suggest pushing. Instruct the user to remediate first.**
