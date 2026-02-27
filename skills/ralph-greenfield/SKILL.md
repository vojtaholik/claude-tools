---
name: ralph-greenfield
description: Start a greenfield ralph loop. Use when the user says /ralph-greenfield or wants to build something from scratch with an autonomous loop.
---

# Ralph Greenfield Loop

Start a greenfield development ralph loop for building something from scratch.

Ask the user these questions ONE AT A TIME:

1. **Target** — "What are you building? Describe it."
2. **Scope** — "Any constraints? (e.g. tech stack, no external deps, specific patterns)"
3. **Done criteria** — "How will I know it's done? What's the acceptance criteria?"

Then run:

```bash
~/.claude/plugins/local/claude-tools/ralph-recipes/scripts/start-recipe.sh greenfield "<target>" "<scope>" "<done_criteria>"
```

After the script runs, tell the user the loop is active and begin scaffolding.
