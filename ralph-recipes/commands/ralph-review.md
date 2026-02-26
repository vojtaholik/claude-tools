---
description: "Start a code review ralph loop"
argument-hint: ""
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/ralph-recipes/scripts/start-recipe.sh:*)"]
---

# Ralph Review Loop

Start a code review and cleanup ralph loop.

Ask the user these questions ONE AT A TIME:

1. **Target** — "What file or module should I review?"
2. **Scope** — "Any constraints? (e.g. focus on security, ignore styling, only this directory)"

Then run:

```bash
${CLAUDE_PLUGIN_ROOT}/ralph-recipes/scripts/start-recipe.sh review "<target>" "<scope>"
```

After the script runs, tell the user the loop is active and begin with the validator pass.
