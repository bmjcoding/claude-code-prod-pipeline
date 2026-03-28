Run linting and standards compliance checks on the code in scope. Auto-fix everything possible. Use parallel agents to maximize speed. Scope resolution, autonomy, and `--dry-run` rules are defined in CLAUDE.md.

## Phase 1: Detect tooling

Identify configured linters from project config files (ESLint, Biome, Prettier, ruff, mypy, pyright, etc.). If none configured, flag it and proceed with manual checks.

## Phase 2: Run project linters

Run each with auto-fix enabled. Collect unfixable errors for the report.

## Phase 3: Standards compliance (parallel agents)

**Agent A -- Logging standards**
- No print/console.log/println -- must use language's proper logging facility
- Appropriate log levels (debug/info/warn/error)
- No sensitive data in log output
- Structured format (JSON/key-value) with consistent fields (level, timestamp, message, context IDs). Flag bare string interpolation in log calls.
- Request handlers must generate or propagate a correlation/trace ID

**Agent B -- Complexity and structure**
- Cyclomatic complexity >10, files >300 lines, functions >50 lines, nesting >3 levels

**Agent C -- Naming and exports**
- Consistent naming conventions per language, no vague names in broad scope, dead exports, unused barrel re-exports

**Agent D -- Dependency hygiene and vulnerabilities**
- Unused deps, dev/prod misplacement, duplicates
- `npm audit` / `pip audit` for known CVEs. Auto-fix with `npm audit fix` or dep upgrade where non-breaking.

## Phase 4: Auto-fix

Fix everything possible from Phase 3. Re-run linters after fixes to confirm nothing broke.

## Output

| # | Category | File | Issue | Status |
|---|----------|------|-------|--------|

Then list anything verified clean.
