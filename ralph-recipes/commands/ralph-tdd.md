---
description: "Start a TDD ralph loop"
argument-hint: ""
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/ralph-recipes/scripts/start-recipe.sh:*)"]
---

# Ralph TDD Loop

Start a test-driven development ralph loop.

Ask the user these questions ONE AT A TIME:

1. **Target** — "What file, module, or feature should I write tests for?"
2. **Scope** — "Any constraints? (e.g. skip integration tests, focus on edge cases, specific test framework)"

Then run:

```bash
${CLAUDE_PLUGIN_ROOT}/ralph-recipes/scripts/start-recipe.sh tdd "<target>" "<scope>"
```

After the script runs, tell the user the loop is active and begin working on the first test.
