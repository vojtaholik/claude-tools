---
name: vojta-deep-research
description: Structured, hypothesis-driven research across large corpora. Use for complex research tasks, literature reviews, competitive analysis, or anywhere Claude needs to synthesize information from many sources with tracked confidence.
---

# Deep research — hypothesis-driven

Cheap way to upgrade ad-hoc searching into a systematic research loop.

## Prompt to inject

```
Search for this information in a structured way. As you gather data, develop several competing hypotheses. Track your confidence levels in your progress notes to improve calibration. Regularly self-critique your approach and plan. Update a hypothesis tree or research notes file to persist information and provide transparency. Break down this complex research task systematically.
```

## Companion setup

Before starting, define:
- **Success criteria**: what constitutes a complete answer
- **Verification policy**: e.g. "cross-check every non-trivial claim against at least two independent sources"
- **Output format**: e.g. hypothesis tree, annotated bibliography, executive summary + appendix

## Why it works

Hypothesis tracking forces the model out of the "one linear search path" trap and into branching exploration with self-critique. Confidence tracking gives you a dial for filtering findings later.
