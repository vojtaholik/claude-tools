---
name: vojta-frontend-design
description: Build distinctive, non-generic frontends. Use when designing web UIs, landing pages, marketing sites, portfolios, or any visual frontend where the default "AI slop" aesthetic (Inter/Roboto fonts, purple gradients, generic cards) should be avoided.
---

# Frontend design — escape AI slop

When building frontends, inject the snippet below into your working context and follow its guidance. Opus 4.7 has strong design instincts but defaults to a consistent house style (cream backgrounds, serif display, terracotta accents) that reads off for dashboards, dev tools, fintech, healthcare, or enterprise apps.

## Guidance to apply

```
<frontend_aesthetics>
NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white or dark backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character. Use unique fonts, cohesive colors and themes, and animations for effects and micro-interactions.
</frontend_aesthetics>
```

## Techniques for breaking defaults

1. **Specify a concrete alternative.** The model follows explicit palette/typography specs precisely. Give hex ranges, type systems, border radii, transition timings.

2. **Propose options before building.** For open-ended briefs, offer 4 distinct visual directions (bg hex / accent hex / typeface + one-line rationale), have the user pick, then implement only that direction. This replaces what `temperature` used to do for design variety.

## Checklist when implementing

- Typography: distinctive fonts; avoid Inter, Roboto, Arial, system fonts, Space Grotesk
- Color: cohesive palette via CSS variables; dominant color with sharp accents beats evenly distributed palettes
- Motion: CSS-only for HTML, Motion library for React; staggered page load reveals via `animation-delay` over scattered micro-interactions
- Backgrounds: layered gradients, geometric patterns, contextual atmosphere — not flat solids
- Vary between light/dark themes and different aesthetics across runs; do not converge on the same safe choice
