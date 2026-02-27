#!/usr/bin/env bash
# Install claude-tools: plugin symlink + skill symlinks
set -euo pipefail

TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$HOME/.claude/plugins/local"
SKILLS_DIR="$HOME/.claude/skills"
LINK_NAME="claude-tools"

mkdir -p "$PLUGIN_DIR" "$SKILLS_DIR"

# Plugin symlink (for hooks)
if [[ -L "$PLUGIN_DIR/$LINK_NAME" ]]; then
  echo "Updating plugin symlink..."
  rm "$PLUGIN_DIR/$LINK_NAME"
elif [[ -e "$PLUGIN_DIR/$LINK_NAME" ]]; then
  echo "Error: $PLUGIN_DIR/$LINK_NAME exists and is not a symlink" >&2
  exit 1
fi
ln -s "$TOOL_DIR" "$PLUGIN_DIR/$LINK_NAME"

# Skill symlinks
SKILLS=(ralph-tdd ralph-refactor ralph-greenfield ralph-review ralph-prd autopsy)
for skill in "${SKILLS[@]}"; do
  target="$TOOL_DIR/skills/$skill"
  link="$SKILLS_DIR/$skill"
  if [[ -L "$link" ]]; then
    rm "$link"
  elif [[ -e "$link" ]]; then
    echo "Warning: $link exists and is not a symlink, skipping" >&2
    continue
  fi
  ln -s "$target" "$link"
  echo "   Linked skill: /$(echo "$skill")"
done

# Make scripts executable
find "$TOOL_DIR" -name "*.sh" -exec chmod +x {} \;

echo ""
echo "claude-tools installed"
echo "   Plugin: $PLUGIN_DIR/$LINK_NAME -> $TOOL_DIR"
echo ""
echo "Available commands:"
echo "   /ralph-tdd        TDD ralph loop"
echo "   /ralph-refactor   Refactoring ralph loop"
echo "   /ralph-greenfield Greenfield ralph loop"
echo "   /ralph-review     Code review ralph loop"
echo "   /ralph-prd        PRD-driven ralph loop"
echo "   /autopsy          Structured codebase analysis"
echo ""
echo "Session lifecycle hook auto-injects context on session start."
echo ""
echo "Restart Claude Code for changes to take effect."
