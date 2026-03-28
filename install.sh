#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

echo "Installing Claude Code Production Pipeline..."
echo ""

# Create directories
mkdir -p "$COMMANDS_DIR"

# Copy quality commands
echo "Copying quality commands..."
for file in "$REPO_DIR/commands/quality/"*.md; do
  filename=$(basename "$file")
  cp "$file" "$COMMANDS_DIR/$filename"
  echo "  $filename"
done

# Copy workflow commands
echo "Copying workflow commands..."
for file in "$REPO_DIR/commands/workflow/"*.md; do
  filename=$(basename "$file")
  cp "$file" "$COMMANDS_DIR/$filename"
  echo "  $filename"
done

# Append CLAUDE.md rules (if not already present)
echo ""
echo "Updating CLAUDE.md..."
if [ -f "$CLAUDE_MD" ]; then
  if grep -q "## Command Scope Resolution" "$CLAUDE_MD"; then
    echo "  Pipeline rules already present in CLAUDE.md. Skipping."
  else
    echo "" >> "$CLAUDE_MD"
    cat "$REPO_DIR/config/CLAUDE.md" >> "$CLAUDE_MD"
    echo "  Appended pipeline rules to existing CLAUDE.md"
  fi
else
  cp "$REPO_DIR/config/CLAUDE.md" "$CLAUDE_MD"
  echo "  Created CLAUDE.md with pipeline rules"
fi

# Merge hook into settings.json
echo ""
echo "Configuring pre-push secrets hook..."
if [ -f "$SETTINGS_FILE" ]; then
  if command -v jq >/dev/null 2>&1; then
    if jq -e '.hooks.PreToolUse' "$SETTINGS_FILE" >/dev/null 2>&1; then
      # Check if our hook already exists
      if jq -e '.hooks.PreToolUse[] | select(.hooks[].if == "Bash(git push*)")' "$SETTINGS_FILE" >/dev/null 2>&1; then
        echo "  Pre-push secrets hook already configured. Skipping."
      else
        # Merge our hook into existing PreToolUse array
        jq --slurpfile hook "$REPO_DIR/hooks/pre-push-secrets.json" \
          '.hooks.PreToolUse += $hook[0].hooks.PreToolUse' \
          "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
        echo "  Added pre-push secrets hook to existing hooks."
      fi
    else
      # No hooks.PreToolUse yet, add the whole hooks block
      jq --slurpfile hook "$REPO_DIR/hooks/pre-push-secrets.json" \
        '. + {hooks: $hook[0].hooks}' \
        "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
      echo "  Added hooks block to settings.json"
    fi
  else
    echo "  WARNING: jq not installed. Cannot merge hook automatically."
    echo "  Manually merge hooks/pre-push-secrets.json into $SETTINGS_FILE"
  fi
else
  echo "  No settings.json found at $SETTINGS_FILE"
  echo "  Copy hooks/pre-push-secrets.json content into your settings.json manually."
fi

echo ""
echo "Installation complete. Available commands:"
echo ""
echo "  Quality pipeline:"
echo "    /lint              Linters + standards + CVEs"
echo "    /audit             14-dimension code review"
echo "    /test              Coverage with flaky detection"
echo "    /git-verify        Secrets, files, commits, branch"
echo "    /prod-readiness    Full pipeline with ship verdict"
echo ""
echo "  Git workflow:"
echo "    /ship              Commit, push, PR, auto-merge"
echo "    /pr                Push + open PR"
echo "    /merge             Enable auto-merge"
echo "    /cleanup           Remove worktree + branch"
echo ""
echo "  One-command flow:"
echo "    /prod-readiness --ship --auto-merge"
echo ""
echo "  Optional: install gitleaks for deeper secrets scanning:"
echo "    brew install gitleaks"
