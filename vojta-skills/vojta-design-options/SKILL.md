---
name: vojta-design-options
description: Get visual variety by having Claude propose multiple design directions before building. Use for open-ended design briefs, landing pages, brand work, or any frontend where you want to pick a direction rather than accept the default.
---

# Propose design options first

Opus 4.7 has a persistent default house style (warm cream backgrounds, serif display, terracotta accents). Generic rejection ("don't use cream, make it minimal") shifts it to a different fixed palette rather than producing variety. Two techniques reliably break the default: specifying a concrete alternative, or asking for options first.

## Prompt to inject

```
Before building, propose 4 distinct visual directions tailored to this brief (each as: bg hex / accent hex / typeface — one-line rationale). Ask the user to pick one, then implement only that direction.
```

## Why this replaces temperature

Previous design-variety workflows relied on temperature tweaks for variation across runs. That lever is gone with adaptive thinking / effort — ask for enumerated options instead. You get meaningfully different directions and the user keeps control.

## Pair with

- `vojta-frontend-design` — once a direction is picked, the aesthetics prompt keeps the implementation out of generic territory
