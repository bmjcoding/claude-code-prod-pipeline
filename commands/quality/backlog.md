Manage the pipeline backlog at `.claude/backlog.md`. Scope resolution and autonomy rules are defined in CLAUDE.md.

## Default action (no arguments)

Read and display `.claude/backlog.md`. If it doesn't exist, report "No backlog items."

## Arguments

`$ARGUMENTS`

- **No args**: display the backlog
- **`--resolve <item number>`**: mark item as resolved and remove it
- **`--retriage`**: re-check all Agent Actionable items against the current codebase. If an item has already been fixed (code changed, dep removed, endpoint added), mark it resolved. Report what changed.
- **`--clear-resolved`**: remove all resolved items from the file
- **`--agent`**: show only Agent Actionable items (for autonomous sessions)
- **`--human`**: show only Needs Human Decision items

## Backlog format

The backlog file uses this structure:

```markdown
# Backlog — Prod Readiness

Last updated: YYYY-MM-DD HH:MM

## Needs Human Decision
| # | Severity | File | Item | Phase | Added |
|---|----------|------|------|-------|-------|

## Agent Actionable
| # | Severity | File | Item | Phase | Added |
|---|----------|------|------|-------|-------|
```

## Classification rules

**Needs Human Decision**: the fix requires external context the agent does not have. Credentials, infrastructure choices, stakeholder sign-off, production configs, compliance decisions, API strategy, auth strategy.

**Agent Actionable**: the fix is pure code work with no external dependencies. Adding stubs, installing/configuring tooling, adding middleware, writing tests, removing unused deps, fixing lint violations.
