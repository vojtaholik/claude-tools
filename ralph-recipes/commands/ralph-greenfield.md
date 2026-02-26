---
description: "Start a greenfield ralph loop"
argument-hint: ""
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/ralph-recipes/scripts/start-recipe.sh:*)"]
---

# Ralph Greenfield Loop

Start a greenfield development ralph loop for building something from scratch.

Ask the user these questions ONE AT A TIME:

1. **Target** — "What are you building? Describe it."
2. **Scope** — "Any constraints? (e.g. tech stack, no external deps, specific patterns)"
3. **Done criteria** — "How will I know it's done? What's the acceptance criteria?"

Then run:

```bash
${CLAUDE_PLUGIN_ROOT}/ralph-recipes/scripts/start-recipe.sh greenfield "<target>" "<scope>" "<done_criteria>"
```

After the script runs, tell the user the loop is active and begin scaffolding.
