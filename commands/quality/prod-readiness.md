Execute all phases below in sequence. Each phase builds on the previous one's artifacts. Scope resolution, autonomy, and `--dry-run` rules are defined in CLAUDE.md.

Lock the file list at the start. All phases operate on the same set (plus test files created in Phase 4).

---

## Phase 1: Build verification

**Fail-fast gate. If it doesn't build, stop.**

Detect project type and run the appropriate build:

- **Frontend (JS/TS with build script)**: measure base branch bundle size (`git stash && npm run build` on main, record size, `git stash pop`), then build current branch. Capture bundle size delta.
- **Backend (server app with Dockerfile)**: run `docker build` to verify the image builds. Capture image size as the metric (not bundle size). If no Dockerfile, fall back to `tsc --noEmit` or `uv run python -m py_compile`.
- **Backend (no Dockerfile)**: type-check only (`tsc --noEmit`, `mypy`, `pyright`, or `py_compile`).

Fix compilation/build errors up to 2 iterations. If still broken, stop and report.

---

## Phase 2: Lint

Run the equivalent of `/lint`: project linters with auto-fix, then parallel agents for logging standards (structured logging, correlation IDs), complexity, naming/exports, dependency hygiene/CVEs.

---

## Phase 3: Audit

Run the equivalent of `/audit`: all 14 dimensions. Report as severity-grouped table, then fix everything possible in parallel.

---

## Phase 4: Test

Run the equivalent of `/test`: green baseline, reconnaissance, write coverage gaps, run and iterate. Flag flaky tests separately.

---

## Phase 5: Simplify

Review all code changed during this run for reuse, quality, and efficiency. Fix without changing behavior. Preserve test coverage.

**Guards**: if simplify would touch >10 files or >200 net lines changed, split remaining simplifications into a follow-up recommendation and report as "deferred to next pass." For each changed file, include a one-line "behavior preserved because..." note so Phase 6 can validate intent.

---

## Phase 6: Final validation

Re-run tests, linters, and build. Captures anything broken by audit fixes or simplification.

- Tests: fix and re-run up to 2 iterations
- Linters: confirm no regressions
- Build: confirm compiles, capture size delta vs Phase 1 (bundle or Docker image, matching project type)
- **Smoke test** (if the project has a runnable server): start the server, hit the health check endpoint (or `/` if no health check), confirm a 2xx response, then shut down. For Docker projects, `docker run` with a short timeout. This catches "builds but won't start" failures that unit tests miss.

---

## Phase 7: Git verification

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
