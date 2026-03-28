# Claude Code Production Pipeline

A complete production-readiness pipeline for [Claude Code](https://claude.ai/claude-code). Nine slash commands, one pre-push hook, and a set of safety rails that take code from "I think this is done" to "verified ready to ship."

## Quick Start

```bash
git clone https://github.com/bmjcoding/claude-code-prod-pipeline.git
cd claude-code-prod-pipeline
chmod +x install.sh
./install.sh
```

The installer copies commands to `~/.claude/commands/`, appends pipeline rules to `~/.claude/CLAUDE.md`, and merges the pre-push secrets hook into `~/.claude/settings.json`.

## The Pipeline

```
/prod-readiness --ship --auto-merge

Phase 1: Build         fail-fast gate, captures bundle size vs main
Phase 2: Lint          linters + structured logging + complexity + CVEs
Phase 3: Audit         14 dimensions (correctness to operational resilience)
Phase 4: Test          green baseline, coverage gaps, flaky quarantine
Phase 5: Simplify      bounded refactoring, behavior-preserved
Phase 6: Validate      full regression catch after all fixes
Phase 7: Git verify    deterministic + LLM secrets scan, files, commits

Ship Verdict:          NO-SHIP / SHIP WITH CAUTION / CLEAR TO SHIP

/ship                  commit, rebase, push, PR, auto-merge, branch cleanup
Pre-push hook          gitleaks or grep secrets gate (blocks push, cannot bypass)
```

## Commands

### Quality Pipeline

| Command | What it does |
|---------|-------------|
| `/lint` | Project linters with auto-fix, then 4 parallel agents: logging standards (structured JSON, correlation IDs), cyclomatic complexity, naming/exports, dependency hygiene and CVE scanning |
| `/audit` | 14-dimension code review: correctness, error handling, security, accessibility, type safety, redundancy, over-engineering, simplicity, responsiveness, mock data, config/env, API contract consistency, observability, operational resilience |
| `/test` | Green baseline check, parallel reconnaissance (coverage gaps + convention scan), write tests matching project patterns, flaky test detection and quarantine |
| `/git-verify` | Deterministic secrets scan (gitleaks/trufflehog), agent-level credential analysis, sensitive files, large binaries, commit message quality, branch state |
| `/prod-readiness` | 7-phase orchestrator chaining all quality commands with a ship verdict |

### Git Workflow

| Command | What it does |
|---------|-------------|
| `/ship` | Full ship flow in 4 tool calls: stale branch cleanup, commit, rebase + push, PR creation. Optional `--auto-merge` and `--draft` flags. Supports GitHub and Bitbucket Data Center. |
| `/pr` | Push and open PR. Idempotent: safe to re-run. |
| `/merge` | Enable auto-merge on the current branch's open PR. |
| `/cleanup` | Remove current worktree and delete its local branch. |

### Usage Patterns

```bash
# Full ceremony, one command
/prod-readiness --ship

# Full ceremony, two commands (more control)
/prod-readiness
/ship

# Quality check only, no shipping
/prod-readiness

# Dry run: see what would be found without changing anything
/prod-readiness --dry-run

# Ship with draft PR and auto-merge
/prod-readiness --ship --draft
/prod-readiness --ship --auto-merge

# Individual commands
/lint src/components/
/audit --dry-run
/test src/api/
/git-verify
```

## Quality Gates

### Blocking (NO-SHIP)
- Build must compile
- Test suite must be green (flaky tests excluded)
- Coverage must not decrease from baseline
- Zero secrets or credentials found
- Zero unfixed Critical audit findings

### Warning (SHIP WITH CAUTION)
- Unfixed High audit findings
- Critical/high severity CVEs in dependencies
- New/changed files with less than 80% line coverage
- Bundle size growth exceeding 10% vs base branch

## Safety Rails

These apply globally across all commands:

- **Single writer per file**: parallel agents are partitioned by file ownership to prevent conflicting edits
- **Protected file classes**: lockfiles, CI/CD configs, migration files, infrastructure code, and auth/security modules are never auto-modified. Findings are reported but require explicit intent.
- **Baseline test integrity**: the system never rewrites test assertions to match broken code. It analyzes whether the code or the test is wrong.
- **Simplify is bounded**: if simplification would touch more than 10 files or 200 lines, the remainder is deferred to a follow-up pass
- **Scope is deterministic**: all commands default to `git diff` against the base branch, not session-dependent state

## Pre-push Secrets Hook

A `PreToolUse` hook in `settings.json` intercepts every `git push`:

1. If **gitleaks** is installed, it runs a full scan. Blocks push if secrets are found.
2. If gitleaks is not available, a **grep-based fallback** scans the diff for AWS keys, API tokens (sk-), private keys, GitHub PATs, Slack tokens, GitLab tokens, and JWTs. Blocks push if patterns match.

This is the one layer that cannot be bypassed, even if you skip `/prod-readiness` and push directly.

Optional: `brew install gitleaks` for deeper scanning with 700+ patterns and entropy analysis.

## Audit Dimensions

The `/audit` command (and Phase 3 of `/prod-readiness`) covers 14 dimensions:

1. **Correctness** - edge cases, null paths, race conditions, stale closures
2. **Error handling** - loading/error/empty states on async ops, no silent swallows
3. **Security** - XSS, injection, SSRF, open redirects, unsanitized data
4. **Accessibility** - ARIA, focus management, keyboard nav, screen reader
5. **Type safety** - any types, unsafe casts, duplicated types, loose props
6. **Redundancy** - dead code, unused imports, duplicated logic
7. **Over-engineering** - unnecessary abstractions, speculative generality
8. **Simplicity** - convoluted flow, nested ternaries
9. **Responsive** - overflow, touch targets, viewport layouts
10. **Mock data / test coverage** - mock mismatches, untested critical paths
11. **Config / env** - hardcoded values, missing env var types
12. **API contract consistency** - frontend types vs backend models, schema drift
13. **Observability** - errors reported not just caught, error boundaries, silent catches
14. **Operational resilience** - timeouts, retries with backoff, graceful degradation, health checks, dependency instrumentation, actionable error messages

## Provider Support

Git workflow commands (`/ship`, `/pr`, `/merge`, `/cleanup`) auto-detect the provider from the remote URL:

| Provider | Detection | API | Auth |
|----------|-----------|-----|------|
| GitHub | `github.com` in remote | `gh` CLI | `gh auth login` |
| Bitbucket DC | Anything else | REST API v1.0 via `curl` | `$BITBUCKET_TOKEN` |

## File Structure

```
commands/
  quality/
    audit.md            14-dimension code review
    lint.md             Linters + standards + CVEs
    test.md             Coverage with flaky detection
    git-verify.md       Secrets, files, commits, branch
    prod-readiness.md   7-phase orchestrator + verdict
  workflow/
    ship.md             Commit, push, PR, auto-merge
    pr.md               Push + open PR
    merge.md            Enable auto-merge
    cleanup.md          Remove worktree + branch
hooks/
  pre-push-secrets.json Hook config for settings.json
config/
  CLAUDE.md             Global pipeline rules
docs/
  commands.md           Detailed command reference
  customization.md      Tuning thresholds and adding dimensions
  architecture.md       Design decisions and safety rails
install.sh              One-command installer
```

## Customization

See [docs/customization.md](docs/customization.md) for:
- Tuning thresholds (complexity, coverage, bundle size)
- Adding or removing audit dimensions
- Modifying protected file classes
- Adjusting the ship verdict gates

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI
- `git`
- `jq` (for install script and Bitbucket DC API parsing)
- `gh` CLI (GitHub projects only)
- `gitleaks` (optional, recommended: `brew install gitleaks`)

## License

MIT
