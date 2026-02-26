---
description: "Start a PRD-driven ralph loop"
argument-hint: "[init]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/ralph-prd/scripts/*:*)", "Read", "Write"]
---

# Ralph PRD Loop

Start an autonomous ralph loop that works through stories in prd.json.

## If argument is "init" or no prd.json exists:

Scaffold a new PRD interactively. Ask the user ONE AT A TIME:

1. **Project name** — "What's the project called?"
2. **Stories** — "Describe the first story (what needs to be built)."
   - After each story: "Add another story? (describe it, or say 'done')"
   - For each story, generate: id, title, prompt (detailed implementation instructions), priority, skills (suggest relevant ones from available skills)

Then run prd-init.sh with the collected data:

```bash
${CLAUDE_PLUGIN_ROOT}/ralph-prd/scripts/prd-init.sh "<project>" '<stories_json>'
```

Ask: "Start the loop now?"

## If prd.json exists:

Show current status by running:

```bash
${CLAUDE_PLUGIN_ROOT}/ralph-prd/scripts/prd-next.sh
```

Then create the ralph loop state file for PRD mode. Write this file to `.claude/ralph-loop.local.md`:

```
---
active: true
iteration: 1
max_iterations: 50
completion_promise: "STORY DONE"
started_at: "<current UTC timestamp>"
recipe: "prd"
skills: ""
---

PRD-driven loop. Stories managed by prd.json.
```

Then begin working on the first pending story immediately.

## Story completion

When you complete a story's requirements and tests pass, output:

```
<promise>STORY DONE</promise>
```

The stop hook will mark the story done and feed you the next one.
