#!/usr/bin/env bash
# Toggle grind mode on/off.
# Usage: grind-toggle.sh [on|off|status]
set -euo pipefail

STATE_FILE=".claude/grind-mode.local.json"
ACTION="${1:-toggle}"

read_state() {
  if [[ -f "$STATE_FILE" ]]; then
    python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d.get('active','false'))"
  else
    echo "false"
  fi
}

write_state() {
  local active="$1"
  mkdir -p .claude
  python3 -c "
import json, datetime
state = {'active': $active, 'noop_count': 0, 'total_turns': 0, 'started_at': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')}
try:
    with open('$STATE_FILE') as f:
        old = json.load(f)
    if $active:
        state['total_turns'] = old.get('total_turns', 0)
except: pass
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
"
}

case "$ACTION" in
  on)
    write_state "True"
    echo "Grind mode: ON"
    echo "Auto-continue is active. Claude will keep working until:"
    echo "  - You output <promise>GRIND DONE</promise>"
    echo "  - ${GRIND_MAX_NOOPS:-3} consecutive no-op turns are detected"
    echo "  - You manually run /grind off"
    ;;
  off)
    if [[ -f "$STATE_FILE" ]]; then
      TURNS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('total_turns',0))" 2>/dev/null || echo "?")
      rm "$STATE_FILE"
      echo "Grind mode: OFF (${TURNS} turns completed)"
    else
      echo "Grind mode was not active."
    fi
    ;;
  status)
    if [[ -f "$STATE_FILE" ]]; then
      ACTIVE=$(read_state)
      if [[ "$ACTIVE" = "True" ]]; then
        TURNS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('total_turns',0))" 2>/dev/null || echo "?")
        NOOPS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('noop_count',0))" 2>/dev/null || echo "0")
        echo "Grind mode: ON"
        echo "  Turns: $TURNS"
        echo "  Consecutive no-ops: $NOOPS / ${GRIND_MAX_NOOPS:-3}"
      else
        echo "Grind mode: OFF (state file exists but inactive)"
      fi
    else
      echo "Grind mode: OFF"
    fi
    ;;
  toggle)
    CURRENT=$(read_state)
    if [[ "$CURRENT" = "True" ]]; then
      "$0" off
    else
      "$0" on
    fi
    ;;
  *)
    echo "Usage: grind-toggle.sh [on|off|status|toggle]" >&2
    exit 1
    ;;
esac
