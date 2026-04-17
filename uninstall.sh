#!/usr/bin/env bash
set -euo pipefail

TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$HOME/.claude/plugins/local"
SKILLS_DIR="$HOME/.claude/skills"
LINK_NAME="claude-tools"

# Remove plugin symlink
if [[ -L "$PLUGIN_DIR/$LINK_NAME" ]]; then
  rm "$PLUGIN_DIR/$LINK_NAME"
  echo "Removed plugin symlink"
else
  echo "Plugin symlink not found"
fi

# Remove skill symlinks (only if they point to our skills dir)
SKILLS=(ralph-tdd ralph-refactor ralph-greenfield ralph-review ralph-prd autopsy)
for skill in "${SKILLS[@]}"; do
  link="$SKILLS_DIR/$skill"
  if [[ -L "$link" ]] && [[ "$(readlink "$link")" == "$TOOL_DIR/skills/$skill" ]]; then
    rm "$link"
    echo "Removed skill: $skill"
  fi
done

VOJTA_SKILLS=(
  vojta-frontend-design
  vojta-concise
  vojta-act
  vojta-research-first
  vojta-parallel-tools
  vojta-bug-hunt
  vojta-minimal
  vojta-investigate
  vojta-persist
  vojta-no-hardcode
  vojta-confirm
  vojta-deep-research
  vojta-prose
  vojta-design-options
  vojta-cleanup
)
for skill in "${VOJTA_SKILLS[@]}"; do
  link="$SKILLS_DIR/$skill"
  if [[ -L "$link" ]] && [[ "$(readlink "$link")" == "$TOOL_DIR/vojta-skills/$skill" ]]; then
    rm "$link"
    echo "Removed skill: $skill"
  fi
done

echo "claude-tools uninstalled"
