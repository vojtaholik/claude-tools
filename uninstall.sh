#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$HOME/.claude/plugins/local"
LINK_NAME="claude-tools"

if [[ -L "$PLUGIN_DIR/$LINK_NAME" ]]; then
  rm "$PLUGIN_DIR/$LINK_NAME"
  echo "claude-tools uninstalled"
else
  echo "claude-tools not installed (no symlink at $PLUGIN_DIR/$LINK_NAME)"
fi
