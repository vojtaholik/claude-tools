#!/usr/bin/env bash
# Grind mode stop hook — auto-continue with no-op detection.
#
# When grind mode is active:
#   1. Check if agent signaled GRIND DONE → deactivate, allow stop
#   2. Check for no-op turns → increment counter, auto-stop after max
#   3. Otherwise → block stop and re-feed continue prompt
#
# Defers to ralph loop stop hook when a ralph loop is active.
set -euo pipefail

STATE_FILE=".claude/grind-mode.local.json"
RALPH_STATE=".claude/ralph-loop.local.md"

# Not active — don't block
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

ACTIVE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('active', False))" 2>/dev/null || echo "False")
if [[ "$ACTIVE" != "True" ]]; then
  exit 0
fi

# Defer to ralph loop if one is active (ralph's stop hook handles that)
if [[ -f "$RALPH_STATE" ]]; then
  exit 0
fi

# Config
MAX_NOOPS="${GRIND_MAX_NOOPS:-3}"
CONTINUE_PROMPT="${GRIND_CONTINUE_PROMPT:-Continue with the next step. If you're done with the original task, output <promise>GRIND DONE</promise>.}"

# Read stdin (Claude Code passes JSON with transcript_path)
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null || echo "")

# Extract last assistant message
LAST_TEXT=""
TOOL_CALL_COUNT=0
if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
  LAST_ASSISTANT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 || echo "")
  if [[ -n "$LAST_ASSISTANT" ]]; then
    LAST_TEXT=$(echo "$LAST_ASSISTANT" | python3 -c "
import json, sys
msg = json.load(sys.stdin)
parts = msg.get('message',{}).get('content',[])
print('\n'.join(p.get('text','') for p in parts if p.get('type')=='text'))
" 2>/dev/null || echo "")
    TOOL_CALL_COUNT=$(echo "$LAST_ASSISTANT" | python3 -c "
import json, sys
msg = json.load(sys.stdin)
parts = msg.get('message',{}).get('content',[])
print(sum(1 for p in parts if p.get('type')=='tool_use'))
" 2>/dev/null || echo "0")
  fi
fi

# Read current state
NOOP_COUNT=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('noop_count', 0))" 2>/dev/null || echo "0")
TOTAL_TURNS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('total_turns', 0))" 2>/dev/null || echo "0")

# Increment total turns
TOTAL_TURNS=$((TOTAL_TURNS + 1))

# Check for GRIND DONE promise
if echo "$LAST_TEXT" | grep -q '<promise>GRIND DONE</promise>'; then
  rm "$STATE_FILE"
  echo "Grind mode complete after ${TOTAL_TURNS} turns." >&2
  exit 0
fi

# No-op detection: no tool calls AND text < 10 chars
TEXT_LEN=${#LAST_TEXT}
IS_NOOP=false
if [[ "$TOOL_CALL_COUNT" -eq 0 ]] && [[ "$TEXT_LEN" -lt 10 ]]; then
  IS_NOOP=true
  NOOP_COUNT=$((NOOP_COUNT + 1))
else
  NOOP_COUNT=0
fi

# Auto-stop after too many no-ops
if [[ "$NOOP_COUNT" -ge "$MAX_NOOPS" ]]; then
  rm "$STATE_FILE"
  echo "Grind mode: auto-stopped after ${NOOP_COUNT} consecutive no-op turns (${TOTAL_TURNS} total turns)." >&2
  exit 0
fi

# Update state
python3 -c "
import json
state = json.load(open('$STATE_FILE'))
state['noop_count'] = $NOOP_COUNT
state['total_turns'] = $TOTAL_TURNS
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
"

# Block the stop and re-feed
ESCAPED_PROMPT=$(echo "$CONTINUE_PROMPT" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))")

NOOP_NOTE=""
if [[ "$IS_NOOP" = true ]]; then
  NOOP_NOTE=" | no-op ${NOOP_COUNT}/${MAX_NOOPS}"
fi

cat <<HOOKJSON
{
  "decision": "block",
  "reason": ${ESCAPED_PROMPT},
  "systemMessage": "Grind mode turn ${TOTAL_TURNS}${NOOP_NOTE} | To stop: /grind off"
}
HOOKJSON
