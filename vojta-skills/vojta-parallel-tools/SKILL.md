---
name: vojta-parallel-tools
description: Maximize parallel tool calls for faster execution. Use in agents that read many files, run many searches, or execute independent bash commands — anywhere serial tool use is bottlenecking throughput.
---

# Maximize parallel tool calling

Claude's latest models already parallelize well, but this prompt pushes the success rate toward ~100%.

## Prompt to inject

```
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool calls, make all of the independent tool calls in parallel. Prioritize calling tools simultaneously whenever the actions can be done in parallel rather than sequentially. For example, when reading 3 files, run 3 tool calls in parallel to read all 3 files into context at the same time. Maximize use of parallel tool calls where possible to increase speed and efficiency. However, if some tool calls depend on previous calls to inform dependent values like the parameters, do NOT call these tools in parallel and instead call them sequentially. Never use placeholders or guess missing parameters in tool calls.
</use_parallel_tool_calls>
```

## Inverse — reduce parallel execution

If parallel tool calling is causing instability (system overload, rate limits, ordering issues):

```
Execute operations sequentially with brief pauses between each step to ensure stability.
```
