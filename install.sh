#!/usr/bin/env bash
# Install claude-tools by creating a symlink in ~/.claude/plugins/
set -euo pipefail

TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$HOME/.claude/plugins/local"
LINK_NAME="claude-tools"

mkdir -p "$PLUGIN_DIR"

# Create symlink
if [[ -L "$PLUGIN_DIR/$LINK_NAME" ]]; then
  echo "Updating existing symlink..."
  rm "$PLUGIN_DIR/$LINK_NAME"
elif [[ -e "$PLUGIN_DIR/$LINK_NAME" ]]; then
  echo "Error: $PLUGIN_DIR/$LINK_NAME exists and is not a symlink" >&2
  exit 1
fi

ln -s "$TOOL_DIR" "$PLUGIN_DIR/$LINK_NAME"

# Make scripts executable
find "$TOOL_DIR" -name "*.sh" -exec chmod +x {} \;

echo "claude-tools installed"
echo "   Symlink: $PLUGIN_DIR/$LINK_NAME -> $TOOL_DIR"
echo ""
echo "Available commands:"
echo "   /ralph-tdd        TDD ralph loop"
echo "   /ralph-refactor   Refactoring ralph loop"
echo "   /ralph-greenfield Greenfield ralph loop"
echo "   /ralph-review     Code review ralph loop"
echo "   /ralph-prd        PRD-driven ralph loop"
echo "   /autopsy          Structured codebase analysis"
echo ""
echo "Session lifecycle hook will auto-inject context on next session start."
echo ""
echo "Restart Claude Code for changes to take effect."
