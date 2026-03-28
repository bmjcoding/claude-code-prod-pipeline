Write tests to cover gaps in the code in scope. Target: maintain or improve baseline coverage, and achieve >=80% line coverage on new/changed files. Use parallel agents to maximize speed. Scope resolution, autonomy, auto-fix safety, and `--dry-run` rules are defined in CLAUDE.md.

## Phase 0: Baseline

Run the existing test suite. If tests fail, analyze whether the code or the test is wrong. Fix pre-existing failures (up to 2 attempts per file) before writing new tests. **Never rewrite test assertions to match broken code** -- if the code is wrong, fix the code; if the test is outdated, update the test; if unclear, flag for the user. A green baseline is required before new test results are meaningful.

## Phase 1: Reconnaissance (parallel agents)

**Agent A -- Coverage gaps**: Identify all untested components, modules, hooks, utilities, and endpoints in scope. Produce a gap list sorted by criticality (user-facing > business logic > utilities > types/config).

**Agent B -- Convention scan**: Read 2-3 existing test files to extract conventions (runner, naming, mock patterns, render approach, setup/teardown).

## Phase 2: Write tests

For each gap, write tests following conventions from Agent B. Prioritize: components > hooks > API endpoints > utilities > integration paths.

Rules:
- One test file per source file, matching project naming convention
- Test behavior, not implementation. Mock external deps only.
- No snapshot tests unless project already uses them
- Use project's existing test utilities/helpers

## Phase 3: Run and iterate

1. Run full test suite. Fix failures and re-run (up to 3 iterations per file).
2. **Flaky detection**: if a test fails then passes with no code changes, flag as flaky. Report separately, exclude from reliable coverage.
3. Run coverage if configured. Report final numbers.

## Output

| File | Tests Written | Status | Notes |
|------|--------------|--------|-------|

Coverage, flaky tests, and untestable files listed below the table.
