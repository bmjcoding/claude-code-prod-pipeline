# Customization

All thresholds, dimensions, and rules are tunable. The defaults are production-reasonable starting points.

## Tuning Thresholds

### Complexity (lint.md, Agent B)
```
Default: cyclomatic >10, files >300 lines, functions >50 lines, nesting >3 levels
```
To adjust, edit the numbers in `commands/quality/lint.md` under Agent B. Lower values produce more findings, higher values are more permissive.

### Coverage (prod-readiness.md, Ship Verdict)
```
Default: baseline must not decrease, new/changed files >=80% line coverage (warning)
```
Edit the Ship Verdict section in `commands/quality/prod-readiness.md`. The 80% threshold is a warning, not a blocker. To make it blocking, move it to the "Blocking" section.

### Bundle Size (prod-readiness.md, Ship Verdict)
```
Default: >10% growth vs base branch (warning)
```
Adjust the percentage in the warning section. For projects where bundle size is critical, move it to blocking.

## Adding Audit Dimensions

Edit `commands/quality/audit.md` and add a new numbered dimension. Follow the pattern:

```
15. **Your dimension** -- concise description of what to check
```

Then update the dimension count reference in `commands/quality/prod-readiness.md` Phase 3.

## Removing Audit Dimensions

Delete the line from `commands/quality/audit.md` and renumber. Dimensions are independent; removing one does not affect others.

## Modifying Protected File Classes

Edit the "Auto-fix Safety Rules" section in `config/CLAUDE.md`:

```
- **Protected files**: do not auto-modify lockfiles (package-lock.json, uv.lock),
  migration files, CI/CD configs, infrastructure code (Terraform, CloudFormation),
  or auth/security modules.
```

Add or remove file patterns as needed. These files will still be analyzed and reported on; they just won't be auto-modified.

## Adjusting Ship Verdict Gates

The verdict in `commands/quality/prod-readiness.md` has two tiers:

**Blocking (NO-SHIP)**: hard stops. Must be resolved before shipping.
**Warning (SHIP WITH CAUTION)**: advisory. Developer decides.

To promote a warning to a blocker, move it from the Warning section to the Blocking section. To demote a blocker to a warning, move it the other direction.

## Adding New Lint Agents

Edit `commands/quality/lint.md` Phase 3. Add a new agent following the pattern:

```
**Agent E -- Your agent name**
- Bullet points describing what to check
```

## Changing the Secrets Hook

Edit `hooks/pre-push-secrets.json` to modify the grep patterns or add new ones. The patterns in the fallback scan are:

- `AKIA[0-9A-Z]{16}` - AWS access keys
- `sk-[a-zA-Z0-9]{20,}` - API secret keys
- `-----BEGIN ... PRIVATE KEY` - Private key files
- `ghp_[a-zA-Z0-9]{36}` - GitHub personal access tokens
- `xox[bsp]-[a-zA-Z0-9-]{10,}` - Slack tokens
- `glpat-[a-zA-Z0-9-]{20}` - GitLab personal access tokens
- `eyJ[a-zA-Z0-9_-]{20,}\.eyJ` - JWTs

To add a pattern, extend the grep regex in the `command` field. After editing, re-run `./install.sh` or manually merge the JSON into your `~/.claude/settings.json`.

## Per-project Overrides

For project-specific rules, create a `.claude/settings.json` in the project root. Settings merge: user > project > local. This lets you:

- Tighten thresholds for critical projects
- Relax thresholds for prototypes
- Add project-specific protected files
- Override audit dimensions
