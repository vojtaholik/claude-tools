#!/usr/bin/env bash
# PRD-aware stop hook for ralph loops.
# When a ralph-prd loop is active:
#   - Checks if current story's promise was met
#   - If yes: marks story done, picks next story
#   - If all stories done: exits loop
#   - If no: re-feeds same story prompt
#
# Falls through to normal ralph stop hook behavior for non-PRD loops.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../shared/utils.sh"

RALPH_STATE=".claude/ralph-loop.local.md"

# No active loop — don't block
if [[ ! -f "$RALPH_STATE" ]]; then
  exit 0
fi

RECIPE=$(parse_frontmatter "recipe" "$RALPH_STATE" 2>/dev/null || echo "")

# Not a PRD loop — let the standard stop hook handle it
if [[ "$RECIPE" != "prd" ]]; then
  exit 0
fi

# Read stdin (Claude Code passes JSON with transcript_path)
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null || echo "")

# Extract last assistant message
LAST_OUTPUT=""
if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
  LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 | python3 -c "
import json,sys
msg = json.load(sys.stdin)
parts = msg.get('message',{}).get('content',[])
print('\n'.join(p.get('text','') for p in parts if p.get('type')=='text'))
" 2>/dev/null || echo "")
fi

ITERATION=$(parse_frontmatter "iteration" "$RALPH_STATE")
MAX_ITERATIONS=$(parse_frontmatter "max_iterations" "$RALPH_STATE")
SKILLS=$(parse_frontmatter "skills" "$RALPH_STATE" 2>/dev/null || echo "")

# Check max iterations
if [[ -n "$MAX_ITERATIONS" ]] && [[ "$MAX_ITERATIONS" != "0" ]] && (( ITERATION >= MAX_ITERATIONS )); then
  echo "Ralph PRD loop: max iterations ($MAX_ITERATIONS) reached" >&2
  rm "$RALPH_STATE"
  exit 0
fi

# Get current story
NEXT_STORY=$("$SCRIPT_DIR/../scripts/prd-next.sh" 2>/dev/null || echo "ALL_STORIES_DONE")

if [[ "$NEXT_STORY" = "ALL_STORIES_DONE" ]]; then
  echo "Ralph PRD loop: all stories complete!" >&2
  rm "$RALPH_STATE"
  exit 0
fi

STORY_ID=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
STORY_TITLE=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['title'])" 2>/dev/null || echo "")
STORY_PROMPT=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['prompt'])" 2>/dev/null || echo "")
STORY_SKILLS=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(','.join(json.load(sys.stdin).get('skills',[])))" 2>/dev/null || echo "")

# Check if last output signals story completion
PROMISE_TEXT=""
if [[ -n "$LAST_OUTPUT" ]]; then
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")
fi

if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "STORY DONE" ]]; then
  # Mark current story done, get next
  "$SCRIPT_DIR/../scripts/prd-mark.sh" "$STORY_ID" 2>/dev/null
  NEXT_STORY=$("$SCRIPT_DIR/../scripts/prd-next.sh" 2>/dev/null || echo "ALL_STORIES_DONE")

  if [[ "$NEXT_STORY" = "ALL_STORIES_DONE" ]]; then
    echo "Ralph PRD loop: all stories complete!" >&2
    rm "$RALPH_STATE"
    exit 0
  fi

  STORY_ID=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
  STORY_TITLE=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['title'])" 2>/dev/null || echo "")
  STORY_PROMPT=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['prompt'])" 2>/dev/null || echo "")
  STORY_SKILLS=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(','.join(json.load(sys.stdin).get('skills',[])))" 2>/dev/null || echo "")
fi

# Increment iteration
NEW_ITERATION=$((ITERATION + 1))
update_frontmatter "iteration" "$NEW_ITERATION" "$RALPH_STATE"

# Build prompt with skill injection
PROMPT=""
ALL_SKILLS="${SKILLS}"
if [[ -n "$STORY_SKILLS" ]]; then
  if [[ -n "$ALL_SKILLS" ]]; then
    ALL_SKILLS="${ALL_SKILLS},${STORY_SKILLS}"
  else
    ALL_SKILLS="$STORY_SKILLS"
  fi
fi

if [[ -n "$ALL_SKILLS" ]]; then
  SKILL_CONTENT=$("$SCRIPT_DIR/../../skill-inject/scripts/inject-skills.sh" "$ALL_SKILLS" 2>/dev/null || echo "")
  if [[ -n "$SKILL_CONTENT" ]]; then
    PROMPT="${SKILL_CONTENT}\n\n---\n\n"
  fi
fi

PROMPT="${PROMPT}# Story: ${STORY_TITLE} (${STORY_ID})

${STORY_PROMPT}

When this story is fully implemented and tests pass, output: <promise>STORY DONE</promise>
Only output the promise when it is genuinely true."

# Block the stop and re-feed
ESCAPED_PROMPT=$(echo -e "$PROMPT" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))")

cat <<HOOKJSON
{
  "decision": "block",
  "reason": ${ESCAPED_PROMPT},
  "systemMessage": "Ralph PRD iteration ${NEW_ITERATION}/${MAX_ITERATIONS} | Story: ${STORY_TITLE} | To stop: /cancel-ralph"
}
HOOKJSON
