#!/usr/bin/env bash
# Gather session context: memory, git history, active loops, daily log.
# Output: formatted brief to stdout.
# Must complete in <5 seconds. Failures skip silently.
set -euo pipefail

BRIEF="## Session Brief — $(date '+%Y-%m-%d %H:%M')\n"

# Project detection
PROJECT_NAME=""
PROJECT_PATH="$PWD"
if [[ -f "package.json" ]]; then
  PROJECT_NAME=$(python3 -c "import json; print(json.load(open('package.json')).get('name',''))" 2>/dev/null || echo "")
fi
if [[ -z "$PROJECT_NAME" ]] && [[ -d ".git" ]]; then
  PROJECT_NAME=$(basename "$PWD")
fi
if [[ -n "$PROJECT_NAME" ]]; then
  BRIEF="${BRIEF}\n**Project:** ${PROJECT_NAME} (${PROJECT_PATH})\n"
fi

# Recent git commits
if git rev-parse --git-dir > /dev/null 2>&1; then
  COMMITS=$(git log --oneline --format="  %h  %s (%cr)" -5 2>/dev/null || echo "")
  if [[ -n "$COMMITS" ]]; then
    BRIEF="${BRIEF}\n**Recent work:**\n${COMMITS}\n"
  fi
fi

# Active ralph loops
RALPH_STATE=".claude/ralph-loop.local.md"
if [[ -f "$RALPH_STATE" ]]; then
  ITERATION=$(sed -n 's/^iteration: *//p' "$RALPH_STATE" 2>/dev/null || echo "?")
  MAX=$(sed -n 's/^max_iterations: *//p' "$RALPH_STATE" 2>/dev/null || echo "?")
  RECIPE=$(sed -n 's/^recipe: *"*\([^"]*\)"*/\1/p' "$RALPH_STATE" 2>/dev/null || echo "prompt")
  BRIEF="${BRIEF}\n**Active loop:** ralph-${RECIPE} iteration ${ITERATION}/${MAX}\n"
fi

# Memory file (project-specific)
SAFE_PATH=$(echo "$PROJECT_PATH" | sed 's|/|-|g' | sed 's|^-||')
MEMORY_FILE="$HOME/.claude/projects/${SAFE_PATH}/memory/MEMORY.md"
if [[ -f "$MEMORY_FILE" ]]; then
  NOTES=$(grep -v '^#' "$MEMORY_FILE" | grep -v '^$' | head -10 2>/dev/null || echo "")
  if [[ -n "$NOTES" ]]; then
    BRIEF="${BRIEF}\n**Memory notes:**\n${NOTES}\n"
  fi
fi

# Daily log (opt-in, set CLAUDE_TOOLS_DAILY_DIR to enable)
DAILY_DIR="${CLAUDE_TOOLS_DAILY_DIR:-}"
DAILY_FILE="${DAILY_DIR:+$DAILY_DIR/$(date '+%Y-%m-%d').md}"
if [[ -f "$DAILY_FILE" ]]; then
  DAILY=$(tail -5 "$DAILY_FILE" 2>/dev/null || echo "")
  if [[ -n "$DAILY" ]]; then
    BRIEF="${BRIEF}\n**Today's log:**\n${DAILY}\n"
  fi
fi

echo -e "$BRIEF"
