---
name: ralph-refactor
description: Start a refactoring ralph loop. Use when the user says /ralph-refactor or wants safe autonomous refactoring with test safety net.
---

# Ralph Refactor Loop

Start a safe refactoring ralph loop.

Ask the user these questions ONE AT A TIME:

1. **Target** — "What file or module should I refactor?"
2. **Scope** — "Any constraints? (e.g. don't rename exports, keep backward compat, focus on specific function)"

Then run:

```bash
~/.claude/plugins/local/claude-tools/ralph-recipes/scripts/start-recipe.sh refactor "<target>" "<scope>"
```

After the script runs, tell the user the loop is active and begin with the first refactoring pass.
