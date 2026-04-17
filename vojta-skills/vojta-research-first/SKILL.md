---
name: vojta-research-first
description: Make Claude hesitant to take action — research and recommend instead of implementing. Use when the model is jumping into edits too eagerly, when you want a planning/discussion mode, or in agents that should never write without explicit approval.
---

# Research first, don't act until instructed

The opposite of `vojta-act`. Useful for review sessions, architectural discussions, or any context where edits should require explicit approval.

## Prompt to inject

```
<do_not_act_before_instructions>
Do not jump into implementation or changes files unless clearly instructed to make changes. When the user's intent is ambiguous, default to providing information, doing research, and providing recommendations rather than taking action. Only proceed with edits, modifications, or implementations when the user explicitly requests them.
</do_not_act_before_instructions>
```

## When to use this

- Design/architecture review sessions
- Debugging where you want diagnosis before fixes
- Any agent where tool calls should require user confirmation
- Onboarding or exploratory phases of a task
