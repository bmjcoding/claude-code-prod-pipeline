Execute all phases below. Scope resolution, autonomy, and `--dry-run` rules are defined in CLAUDE.md.

Lock the file list at the start. All phases operate on the same set (plus test files created in Phase 4).

**Hard rule: do not print the Ship Verdict until ALL phases have completed and ALL agent results have returned. No early verdicts.**

## Phase 0: Backlog check

Read `.claude/backlog.md` if it exists. Check whether any previously-deferred items have been resolved by changes in the current scope (file modified, dep removed, endpoint added). Mark resolved items and report them. Flag any unresolved Critical/High items as carry-forward findings in the final report.

---

## Phase 1: Build verification

**Fail-fast gate. If it doesn't build, stop.**

Detect project type and run the appropriate build:

- **Frontend**: build current branch, measure bundle size delta vs base branch
- **Backend with Dockerfile**: `docker build`, capture image size
- **Backend without Dockerfile**: type-check only (`tsc --noEmit`, `mypy`, `pyright`, or `py_compile`)

Fix build errors up to 2 iterations. If still broken, stop and report.

---

## Phase 2+3: Lint and Audit (parallel)

Lint and audit are independent. Run them in parallel:

- **Lint**: run the equivalent of `/lint`. Project linters with auto-fix, then parallel agents for logging standards (structured logging, correlation IDs), complexity, naming/exports, dependency hygiene/CVEs.
- **Audit**: run the equivalent of `/audit`. All 14 dimensions. Report as severity-grouped table.

**SYNCHRONIZATION GATE: You MUST wait for BOTH lint and audit to fully complete and return their findings before moving to any subsequent phase.** Do NOT proceed to Phase 3 while lint or audit agents are still running in the background. If you launched them as background agents, block here and collect all results. Apply fixes from both lint and audit in parallel, partitioned by file ownership. Only then move to Phase 3.

---

## Phase 3: Test

Run the equivalent of `/test`: green baseline, reconnaissance, write coverage gaps, run and iterate. Flag flaky tests separately.

---

## Phase 3.5: Integration test (if applicable)

If the project has integration points (multiple modules, IPC, filesystem protocols, config-driven behavior):

- Verify module interfaces by testing cross-module calls with real (not mocked) dependencies where feasible
- For orchestrator/CLI projects: test end-to-end flows with mocked external commands
- For API projects: test request→response chains through the actual handler stack

Skip if the project is a single-module library with no integration surfaces.

---

## Phase 4: Simplify

Review all code changed during this run for reuse, quality, and efficiency. Fix without changing behavior. Preserve test coverage. Cross-reference lint/audit findings for unused dependencies, dead exports, and redundant code that those phases flagged but did not remove.

**Guards**: if simplify would touch >10 files or >200 net lines changed, split remaining simplifications into a follow-up recommendation and report as "deferred to next pass." For each changed file, include a one-line "behavior preserved because..." note so Phase 5 can validate intent.

---

## Phase 5: Final validation

Re-run tests, linters, and build. Captures anything broken by audit fixes or simplification.

- Tests: fix and re-run up to 2 iterations
- Linters: confirm no regressions
- Build: confirm compiles, capture size delta vs Phase 1 (bundle or Docker image, matching project type)
- **Smoke test** (server projects only): start server, hit health check endpoint, confirm 2xx, shut down. For Docker projects, `docker run` with a short timeout.

---

## Phase 6: Git verification

Run the equivalent of `/git-verify`: deterministic scan first (gitleaks/trufflehog if available), then agent scan for secrets, sensitive files, large files, commit quality, branch state. **Secrets are a NO-SHIP condition, not a warning.**

---

## Final Report

| Phase | Key metrics |
|-------|------------|
| Build | PASS/FAIL, size metric (bundle or Docker image, delta if available) |
| Lint | Issues fixed, standards violations, CVEs found/fixed, unfixable |
| Audit | Found (by severity), fixed |
| Tests | Files covered, coverage %, flaky tests |
| Simplify | Changes made |
| Validation | Tests PASS/FAIL, Linter PASS/FAIL, Build PASS/FAIL, Smoke test PASS/FAIL/SKIPPED |
| Git | Secrets, sensitive files, large files, commit quality, branch state |

Remaining items: anything unresolved, with reason.

---

## Ship Verdict

### Blocking (NO-SHIP if any fail)
- Build must compile
- Test suite must be green (flaky excluded)
- Coverage must not decrease from baseline
- New/changed files must have >=80% line coverage (Warning if not, see below)
- Zero secrets found
- Zero unfixed Critical audit findings

### Warning (SHIP WITH CAUTION)
- Unfixed High audit findings
- >5 deferred High items across all phases
- Critical/high severity CVEs
- New/changed files with <80% line coverage
- Size metric >10% growth vs base branch (bundle or Docker image)

### Verdict format

```
VERDICT: NO-SHIP | SHIP WITH CAUTION | CLEAR TO SHIP
[reasons]
```

---

## Auto-ship (`--ship` flag)

If `$ARGUMENTS` contains `--ship` (or `--ship --draft`, `--ship --auto-merge`):

- **CLEAR TO SHIP**: automatically proceed to run `/ship` with any flags passed after `--ship`. Commit all changes from this run, push, and open PR.
- **SHIP WITH CAUTION**: print the warnings, then proceed to `/ship` (warnings are advisory, not blocking).
- **NO-SHIP**: stop. Do not ship. Print the blocking reasons and what must be fixed.

If `--ship` is not present, print the verdict and stop. The user runs `/ship` manually when ready.

---

## Backlog update

As the final step (after verdict, before auto-ship), write all deferred and unresolved items to `.claude/backlog.md`. Classify each item:

- **Needs Human Decision**: requires external context (credentials, infra choices, stakeholder input, compliance, auth strategy)
- **Agent Actionable**: pure code work (stubs, tooling config, middleware, tests, dep cleanup)

Each entry: severity, file, one-line description, which phase flagged it, date added. Merge with existing backlog items rather than overwriting. Do not duplicate items already present.
