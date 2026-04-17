---
name: vojta-act
description: Make Claude default to implementing changes rather than just suggesting them. Use when the model keeps proposing edits instead of applying them, or when you want a bias toward action in an agentic coding context.
---

# Default to action

Claude will sometimes return suggestions when you wanted implementation — especially for prompts like "can you suggest some changes." Use explicit action verbs ("change", "make these edits", "fix") or inject the snippet below.

## Prompt to inject

```
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed, using tools to discover any missing details instead of guessing. Try to infer the user's intent about whether a tool call (e.g., file edit or read) is intended or not, and act accordingly.
</default_to_action>
```

## Also effective

Phrase requests as imperatives:
- "Change this function to improve performance" (not "can you suggest changes")
- "Make these edits to the auth flow" (not "what should change here")

## Don't overdo it

Opus 4.5+ is already more responsive to system prompts. Avoid "CRITICAL: you MUST..." framing — use normal language. Aggressive wording causes overtriggering, not better compliance.
