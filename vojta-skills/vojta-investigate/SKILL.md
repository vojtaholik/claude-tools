---
name: vojta-investigate
description: Force Claude to read referenced files before answering — eliminates hallucinated claims about code. Use in agentic coding, code review, or any Q&A over a codebase where accuracy matters more than speed.
---

# Investigate before answering

Stops the model from speculating about code it hasn't opened. Cheapest and highest-leverage anti-hallucination prompt for codebase Q&A.

## Prompt to inject

```
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering. Make sure to investigate and read relevant files BEFORE answering questions about the codebase. Never make any claims about code before investigating unless you are certain of the correct answer - give grounded and hallucination-free answers.
</investigate_before_answering>
```

## When to use

- Code review / bug finding
- Explanations of existing code ("what does X do?")
- Migration planning where accurate file contents matter
- Any long-running agent where errors compound
