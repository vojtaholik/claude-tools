---
name: vojta-cleanup
description: Stop Claude from leaving behind temporary scripts, scratch files, and iteration helpers after a task. Use when you want a clean workspace — no extra files beyond the requested deliverables.
---

# Cleanup — no leftover scratch files

Claude sometimes creates temporary files (especially Python scripts) as a scratchpad during iteration. These can be useful mid-task but clutter the workspace after.

## Prompt to inject

```
If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task.
```

## When this matters

- Agentic coding sessions that produce PRs
- Any workflow where leftover files would pollute git status
- Notebooks/environments where scratch artifacts confuse later readers

## When to skip this

If you actually want the scratchpad artifacts (debug logs, intermediate data), don't use this skill — or pair a retention instruction alongside.
