---
description: "Toggle grind mode — auto-continue after every turn"
argument-hint: "[on|off|status]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/grind-mode/scripts/grind-toggle.sh:*)"]
---

# Grind Mode

Toggle autonomous grind mode. When active, Claude auto-continues after every turn until the task is done.

If the user provides an argument, use it directly: `on`, `off`, or `status`.
If no argument, toggle the current state.

Run:

```bash
${CLAUDE_PLUGIN_ROOT}/grind-mode/scripts/grind-toggle.sh <action>
```

Where `<action>` is one of: `on`, `off`, `status`, or `toggle` (default).

When grind mode activates, explain:
- You will keep working autonomously until you output `<promise>GRIND DONE</promise>`
- Auto-stops after 3 consecutive no-op turns (configurable via `GRIND_MAX_NOOPS`)
- User can stop anytime with `/grind off`
- Grind mode defers to ralph loops — if a ralph loop is running, it takes priority
