---
name: vojta-persist
description: Keep Claude working across long/autonomous sessions without stopping early due to context budget. Use for long-horizon agent loops, multi-context-window work, or tasks that should run to completion.
---

# Persist — don't stop early

Claude 4.5/4.6 have context awareness and may naturally wrap up work as they approach the budget. If your harness compacts or checkpoints, tell the model.

## Prompt to inject

```
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off. Therefore, do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state to memory before the context window refreshes. Always be as persistent and autonomous as possible and complete tasks fully, even if the end of your budget is approaching. Never artificially stop any task early regardless of the context remaining.
```

## Secondary encouragement

```
This is a very long task, so it may be beneficial to plan out your work clearly. It's encouraged to spend your entire output context working on the task - just make sure you don't run out of context with significant uncommitted work. Continue working systematically until you have completed this task.
```

## Multi-context-window setup

Pair with durable state files so a fresh context can pick up:

- `tests.json` — structured test status
- `progress.txt` — freeform notes
- `init.sh` — environment setup script
- Git log — checkpoint history

Tell the next context window: `pwd; review progress.txt, tests.json, and git log; run the integration test before implementing anything new.`
