---
name: vojta-no-hardcode
description: Prevent Claude from gaming tests — no hard-coded values, no helper-script workarounds, no solutions that only pass the specific test cases. Use when tests are involved and you want real, generalizable implementations.
---

# No hard-coding, no test-gaming

Claude sometimes focuses too narrowly on making tests pass, or reaches for helper scripts instead of solving the actual problem. This prompt keeps the solution principled.

## Prompt to inject

```
Please write a high-quality, general-purpose solution using the standard tools available. Do not create helper scripts or workarounds to accomplish the task more efficiently. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs. Instead, implement the actual logic that solves the problem generally.

Focus on understanding the problem requirements and implementing the correct algorithm. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices and software design principles.

If the task is unreasonable or infeasible, or if any of the tests are incorrect, please inform me rather than working around them. The solution should be robust, maintainable, and extendable.
```

## Signal to watch for

If Claude starts writing one-off scripts, branching on specific fixture values, or inlining test expectations — it's optimizing for the test, not the problem. Re-inject this snippet.
