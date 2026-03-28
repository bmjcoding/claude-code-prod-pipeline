Perform a comprehensive audit of the code in scope. Use parallel agents to maximize speed. Cover every dimension below and report findings in a single table grouped by severity (Critical > High > Medium > Low). Scope resolution, autonomy, and `--dry-run` rules are defined in CLAUDE.md.

## Audit dimensions

1. **Correctness** -- edge cases, null/undefined paths, race conditions, stale closures, missing useEffect cleanup
2. **Error handling** -- loading/error/empty states on all async ops; no silent swallows
3. **Security** -- XSS, injection, SSRF, open redirects, unsanitized external data
4. **Accessibility** -- ARIA on interactive patterns, focus management, keyboard nav, screen reader support
5. **Type safety** -- `any` types, unsafe casts, duplicated types, loose prop types
6. **Redundancy** -- dead code, unused imports, duplicated logic, re-implemented stdlib
7. **Over-engineering** -- unnecessary abstractions, speculative generality, wrapper components adding no value
8. **Simplicity** -- convoluted control flow, nested ternaries, anything expressible more directly
9. **Responsive** -- overflow handling, touch targets, viewport layouts
10. **Mock data / test coverage** -- mock/reference mismatches, untested critical paths
11. **Config / env** -- hardcoded values, missing env var types, port/URL assumptions
12. **API contract consistency** -- frontend types vs backend models; schema drift between layers
13. **Observability** -- errors reported not just handled; global error boundaries; flag silent catch blocks and endpoints with no error logging
14. **Operational resilience** -- explicit timeouts on external calls, retries with backoff, graceful degradation when deps are down, meaningful health checks, dependency call instrumentation, actionable error messages

## Output format

Single markdown table: #, Severity, File, Issue, Suggested Fix. Grouped by severity. Flag regressions from recent changes first.

## After reporting

Fix everything possible in parallel using agents grouped by file ownership. Do not ask for confirmation.
