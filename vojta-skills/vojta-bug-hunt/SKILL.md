---
name: vojta-bug-hunt
description: Raise recall in code review — get Claude to report every bug it finds, including low-confidence ones. Use for code review harnesses, security audits, or any workflow where missing a real bug is worse than a few false positives.
---

# Bug hunt — coverage over precision

Opus 4.7 is a stronger bug-finder than prior models, but phrases like "only high-severity," "be conservative," or "don't nitpick" make it self-filter findings it investigated. Separate finding from filtering.

## Prompt to inject

```
Report every issue you find, including ones you are uncertain about or consider low-severity. Do not filter for importance or confidence at this stage - a separate verification step will do that. Your goal here is coverage: it is better to surface a finding that later gets filtered out than to silently drop a real bug. For each finding, include your confidence level and an estimated severity so a downstream filter can rank them.
```

## If you must single-pass self-filter

Be concrete about the bar, not qualitative:

> Report any bugs that could cause incorrect behavior, a test failure, or a misleading result; only omit nits like pure style or naming preferences.

## Harness tuning

If you have a downstream verification, dedup, or ranking stage, explicitly tell the model its job at the finding stage is coverage rather than filtering. Iterate against a held-out eval set to measure recall/F1.
