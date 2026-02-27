---
name: ralph-review
description: Start a code review ralph loop. Use when the user says /ralph-review or wants autonomous 2-pass code review (validator + minifier).
---

# Ralph Review Loop

Start a code review and cleanup ralph loop.

Ask the user these questions ONE AT A TIME:

1. **Target** — "What file or module should I review?"
2. **Scope** — "Any constraints? (e.g. focus on security, ignore styling, only this directory)"

Then run:

```bash
~/.claude/plugins/local/claude-tools/ralph-recipes/scripts/start-recipe.sh review "<target>" "<scope>"
```

After the script runs, tell the user the loop is active and begin with the validator pass.
