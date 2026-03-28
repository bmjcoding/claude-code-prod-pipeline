# Architecture

## Design Principles

### Separation of Concerns

The pipeline is split into two independent command sets:

- **Quality commands** (`/lint`, `/audit`, `/test`, `/git-verify`, `/prod-readiness`): answer "is this code ready to ship?"
- **Workflow commands** (`/ship`, `/pr`, `/merge`, `/cleanup`): answer "how do I ship it?"

These are independently usable. You can adopt just the quality pipeline, just the workflow, or both.

### Thin Orchestrator

`/prod-readiness` is a thin orchestrator that references the standalone commands rather than duplicating their logic. Each phase says "run the equivalent of `/lint`" rather than re-specifying every agent and dimension. This eliminates drift: update `/lint` once, and `/prod-readiness` stays in sync.

### Fail-fast Ordering

The 7 phases are ordered by cost and value:

1. **Build** (seconds, binary pass/fail) - if it doesn't compile, nothing else matters
2. **Lint** (seconds, mostly deterministic) - cheap fixes before expensive analysis
3. **Audit** (minutes, LLM-driven) - deep analysis after mechanical issues are resolved
4. **Test** (minutes, LLM + execution) - coverage after code quality is verified
5. **Simplify** (minutes, LLM-driven) - clean up after all other changes
6. **Validate** (seconds, re-run) - regression catch
7. **Git verify** (seconds, deterministic + LLM) - final safety gate

### Deterministic Before Heuristic

Secrets scanning uses deterministic tools (gitleaks, grep) before LLM-based analysis. Project linters run before LLM-based standards checks. The principle: use reliable tools first, then augment with AI for what tools cannot catch.

## Safety Rails

### Single Writer Per File

When parallel agents auto-fix code, they are partitioned by file ownership. No two agents modify the same file. If a finding spans multiple files, the agent owning the primary file handles it. This prevents merge conflicts and nondeterministic output.

### Protected Files

Certain file classes are never auto-modified:
- Lockfiles (`package-lock.json`, `uv.lock`)
- Migration files
- CI/CD configs
- Infrastructure code (Terraform, CloudFormation)
- Auth/security modules

Findings on these files are reported but require explicit user intent to change. This prevents well-intentioned fixes from breaking deployment pipelines or security boundaries.

### Baseline Test Integrity

When fixing failing tests during baseline checks, the system analyzes whether the code or the test is wrong. It never rewrites test assertions to match broken code. This prevents the most dangerous failure mode: tests that pass but validate the wrong behavior.

### Bounded Simplification

The simplify phase has two guards:
- If it would touch more than 10 files, remaining changes are deferred
- If it would change more than 200 net lines, remaining changes are deferred

Each changed file requires a "behavior preserved because..." note so the validation phase can verify intent.

### Deterministic Scope

All commands default to `git diff --name-only` against the base branch. This is deterministic and survives context compression, unlike "all code changed in this session" which depends on conversation state.

## Two-layer Security Model

### Layer 1: Pre-push Hook (Hard Gate)

A `PreToolUse` hook in `settings.json` intercepts every `git push`. It runs gitleaks (if installed) or a grep-based regex scan against the diff. If secrets are found, the push is denied. This is enforced by the Claude Code harness, not by Claude's compliance with a directive. It cannot be bypassed.

### Layer 2: /git-verify and /prod-readiness (Soft Gate)

The `/git-verify` command and Phase 7 of `/prod-readiness` perform deeper analysis including LLM-based credential detection, sensitive file scanning, and commit quality checks. These are behavioral (Claude executes them) rather than deterministic (harness enforces them).

The two layers complement each other: the hook catches the obvious patterns with zero false negatives on known formats, the LLM catches subtle or novel patterns that regex misses.

## Verdict System

The ship verdict has two tiers to match how teams actually operate:

**Blocking (NO-SHIP)**: conditions that must never reach production. Build failure, test regression, secrets, unfixed Critical findings.

**Warning (SHIP WITH CAUTION)**: conditions worth knowing about but where the developer's judgment applies. High findings that may be acceptable in context, CVEs with no available fix, coverage gaps on config-only files.

This avoids the common failure mode of quality gates: if everything is a hard block, developers learn to bypass the system. Advisory warnings with clear rationale build trust.

## CI Integration (Recommended)

This pipeline is designed as a local pre-push quality gate: the fast feedback loop. The same checks should be promoted to CI as the authoritative backstop:

- Local: advisory verdict, developer makes the final call
- CI: hard block on merge, no override without approval

The commands are markdown files that Claude Code interprets. To run them in CI, use:

```bash
claude -p "/prod-readiness" --allowedTools "Edit,Write,Bash" --output-format text
```

The exit behavior and verdict can be parsed from the output to set CI pass/fail status.
