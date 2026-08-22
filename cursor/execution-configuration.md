# Cursor execution configuration

This file documents the operational contract for work prepared for Cursor. It
does not define model-selection policy.

The normative policy for how ChatGPT evaluates available models and recommends
model, effort, and other execution controls lives in ChatGPT Custom
Instructions. The versioned projection in this repository is
[`chatgpt/custom-instructions.es.md`](../chatgpt/custom-instructions.es.md).
Copy its complete contents into ChatGPT (`Settings > Personalization > Custom
Instructions`). That projection is the recoverable source for the Custom
Instructions field; this file is not a parallel authority and must not diverge
from it on model selection.

## Authority chain

```
ChatGPT Custom Instructions (runtime; projected in custom-instructions.es.md)
        │
        │ ChatGPT prepares work for Cursor
        ▼
ChatGPT recommends model + effort (+ other controls when material)
        │
        │ presented to the user before and outside the operational prompt
        ▼
User configures Cursor
        │
        ▼
Cursor receives the operational prompt and executes
```

Cursor does not autonomously choose the executor configuration as policy. The
current Cursor UI governs which models, controls, and values are actually
available; it does not by itself redefine the working method.

## Recommendation for the user

Before and outside the prompt pasted into Cursor, ChatGPT presents an execution
recommendation to the user. That recommendation must always include model and
effort. Include other execution controls only when materially important for the
task.

The recommendation is not part of the operational prompt. Do not repeat
in-scope repositories in the recommendation.

## Prompt destined for Cursor

The prompt pasted into Cursor must not include the execution recommendation.

Include as applicable:

- in-scope repositories
- authority over each repository
- objective
- decisions already taken
- limits
- verifications
- close-out

Project, repository, and task instructions may specialize or replace general
values within their own authority, including repository scope, permissions, or
execution behavior. They do not establish a parallel model-selection policy
that competes with ChatGPT Custom Instructions.
