# Command Reference

## Quality Commands

All quality commands support:
- **Scope from arguments**: `/lint src/components/` targets specific paths
- **Dry run**: `/audit --dry-run` reports findings without changing files
- **Default scope**: when no arguments, uses `git diff --name-only` against the base branch

### /lint

Runs in 4 phases:

1. **Detect tooling**: finds ESLint, Biome, Prettier, ruff, mypy, pyright from project config
2. **Run project linters**: auto-fix enabled, collects unfixable errors
3. **Standards compliance** (4 parallel agents):
   - Agent A: logging standards (structured JSON, proper levels, no PII, correlation IDs)
   - Agent B: complexity (cyclomatic >10, files >300 lines, functions >50 lines, nesting >3)
   - Agent C: naming and exports (conventions, vague names, dead exports)
   - Agent D: dependency hygiene and CVEs (`npm audit` / `pip audit`, auto-fix where safe)
4. **Auto-fix**: applies fixes from Phase 3, re-runs linters to confirm

### /audit

14-dimension code review. Each finding is assigned a severity (Critical, High, Medium, Low) and reported in a grouped table. After reporting, fixes are applied in parallel with agents partitioned by file ownership.

### /test

Phases:
- **Phase 0 (Baseline)**: runs existing tests. Fixes pre-existing failures but never rewrites assertions to match broken code.
- **Phase 1 (Reconnaissance)**: two parallel agents identify coverage gaps and scan existing test conventions
- **Phase 2 (Write)**: tests written per gap, matching project patterns. Prioritizes components > hooks > API endpoints > utilities > integration paths.
- **Phase 3 (Iterate)**: runs suite, fixes failures (up to 3 iterations), detects flaky tests, reports coverage

### /git-verify

Checks:
- **Check 0**: deterministic scan via gitleaks/trufflehog (if installed)
- **Check 1**: parallel agent scan for secrets in source code and sensitive files in diff
- **Check 2**: large files (>1MB binary, >10MB any, build artifacts)
- **Check 3**: commit message quality
- **Check 4**: branch state (behind remote, uncommitted changes)

Secrets are a NO-SHIP condition. Committed secrets require `git reset --soft HEAD~1` before pushing.

### /prod-readiness

7 phases in sequence: Build > Lint > Audit > Test > Simplify > Validate > Git Verify.

Flags:
- `--dry-run`: report everything without making changes
- `--ship`: auto-continue to `/ship` if verdict is CLEAR TO SHIP or SHIP WITH CAUTION
- `--ship --draft`: ship as draft PR
- `--ship --auto-merge`: ship and enable auto-merge

## Workflow Commands

### /ship

Full ship flow targeting 4 or fewer tool calls:

1. Auth check + worktree prune + stale local branch cleanup (parallel)
2. Delete stale remote branches + commit (parallel)
3. Rebase + push + check for existing PR (sequential chain)
4. Create PR + optional auto-merge (if needed)

Flags: `--draft`, `--auto-merge`

Supports GitHub (`gh` CLI) and Bitbucket Data Center (`curl` + `$BITBUCKET_TOKEN`).

### /pr

Push current branch and open a PR. Idempotent: if PR already exists, reports URL and stops. Rebases onto default branch before pushing.

Flags: `--draft`, `--title "Custom title"`

### /merge

Enables auto-merge on the current branch's open PR. Detects merge strategy from repo settings (prefers squash).

Flags: `--squash`, `--rebase`, `--merge`, `--pr-number N`

### /cleanup

Removes the current worktree and deletes its local branch. Validates the PR is merged before removing (skip with `--force`). Kills any processes using the worktree directory.

Flags: `--force`
