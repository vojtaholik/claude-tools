---
name: vojta-prose
description: Reduce bullet-point and markdown formatting — produce flowing prose instead. Use for reports, technical writing, essays, user-facing documents, or any long-form text where fragmented bullets hurt readability.
---

# Prose over bullets

Claude tends toward bullet-point formatting. For narrative writing, this fragments ideas that should flow.

## Prompt to inject

```
<avoid_excessive_markdown_and_bullet_points>
When writing reports, documents, technical explanations, analyses, or any long-form content, write in clear, flowing prose using complete paragraphs and sentences. Use standard paragraph breaks for organization and reserve markdown primarily for `inline code`, code blocks (```...```), and simple headings (###, and ###). Avoid using **bold** and *italics*.

DO NOT use ordered lists (1. ...) or unordered lists (*) unless : a) you're presenting truly discrete items where a list format is the best option, or b) the user explicitly requests a list or ranking

Instead of listing items with bullets or numbers, incorporate them naturally into sentences. This guidance applies especially to technical writing. Using prose instead of excessive formatting will improve user satisfaction. NEVER output a series of overly short bullet points.

Your goal is readable, flowing text that guides the reader naturally through ideas rather than fragmenting information into isolated points.
</avoid_excessive_markdown_and_bullet_points>
```

## Supporting tactic

Match your own prompt style to the desired output — if you write in prose, Claude is more likely to respond in prose. Remove markdown from your prompt to reduce markdown in the response.

## Tell, don't un-tell

Prefer "respond in smoothly flowing prose" over "do not use markdown." Positive instructions steer better than negative ones.
