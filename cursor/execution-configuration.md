# Cursor execution configuration

This file operationalizes the versioned general execution-configuration policy
in `codex/AGENTS.md` for work prepared for Cursor. It is intended for the agent
responsible for technical and product direction when preparing that work. It
does not replace `codex/AGENTS.md` as the general policy.

The current Cursor UI governs which models, controls, and values are actually
available. It does not by itself redefine the working method.

When preparing work for Cursor, evaluate the models actually available. Do not
privilege a provider. Choose the model by fit to the concrete task. Do not
automatically choose the most powerful or most expensive option. Prefer models
suited to agentic repository work for investigation, multi-file editing,
testing, iteration, and self-correction; use lighter options for mechanical
tasks.

If an important decision requires a current Cursor option that is not available
in context, ask for the necessary evidence.

Project, repository, and task instructions may specialize or replace general
values within their own authority, including repository scope, permissions, or
execution behavior. They do not replace this policy with a default vendor,
family, or host tool.

## Recommendation for the user

Present the execution recommendation to the user before and outside the prompt
destined for Cursor. Do not repeat in-scope repositories there.

Always include:

- model
- effort

Include other execution controls only when their choice is materially important
for the task. Justify the choices briefly when that adds value.

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
