## Command Scope Resolution
For /lint, /audit, /test, /git-verify, and /prod-readiness commands, determine scope from $ARGUMENTS:
- If file or directory paths are given, use those
- If `--dry-run` is present, report findings without making any changes
- If no paths given, run `git diff --name-only $(git merge-base HEAD main)` to identify files changed on this branch. If already on main, use `git diff --name-only HEAD` for uncommitted changes

## Autonomous Execution
When running /lint, /audit, /test, /simplify, /git-verify, or /prod-readiness commands:
- Execute to completion without asking for confirmation between steps
- Fix errors inline rather than stopping to report them
- Only stop on unrecoverable failures after 2 fix attempts
- Use parallel agents wherever independent work can be parallelized

## Auto-fix Safety Rules
These rules apply to ALL commands that auto-fix code (/lint, /audit, /test, /simplify, /prod-readiness):
- **Single writer per file**: when parallel agents fix code, no two agents may modify the same file. Partition by file ownership. If a finding spans files, the agent owning the primary file takes it.
- **Protected files**: do not auto-modify lockfiles (package-lock.json, uv.lock), migration files, CI/CD configs, infrastructure code (Terraform, CloudFormation), or auth/security modules. Report findings on these files but require explicit user intent to change them.
- **Baseline test integrity**: when fixing failing tests in baseline checks, analyze whether the code or the test is wrong. Never rewrite test assertions to match broken code. If unclear, flag for the user rather than auto-fixing.

## Pre-push Gate
Secrets scanning before `git push` is enforced by a PreToolUse hook in settings.json (gitleaks or grep fallback, deterministic, cannot be bypassed). Before pushing, also run `/lint` on changed files. If lint finds unfixable issues, warn the user before pushing.
