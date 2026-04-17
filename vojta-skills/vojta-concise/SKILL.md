---
name: vojta-concise
description: Make Claude's responses shorter and more focused. Use when the model is over-explaining, adding non-essential context, or producing verbose answers for simple lookups.
---

# Concise responses

Opus 4.7 calibrates response length to task complexity. If you want shorter output across the board, inject:

```
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

## Tips

- Positive examples of the desired concision outperform "don't do X" instructions.
- If the model over-explains in a specific way (e.g. recapping what it just did), add a targeted instruction for that pattern.
- If you want concision but also visibility into tool use, pair with: "After completing a task that involves tool use, provide a quick summary of the work you've done."
