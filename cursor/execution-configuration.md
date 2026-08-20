# Cursor execution configuration

This file operationalizes the versioned general execution-configuration policy
in `codex/AGENTS.md` for prompts sent to Cursor. It is intended for the agent
responsible for technical and product direction when preparing that work. That
agent selects the model and the execution controls Cursor actually exposes for
that model; Cursor then executes under the resulting prompt and applicable
project- and repository-specific constraints.

The current Cursor UI governs which models, controls, and values are actually
available. It does not by itself redefine the working method.

When preparing a prompt for Cursor, inspect the models and execution controls
actually available for the task.

Begin the prompt with:

CONFIGURACIÓN DE EJECUCIÓN

* Modelo: [nombre exacto del modelo seleccionado]
* Thinking: [valor seleccionado | no disponible]
* Esfuerzo: [valor seleccionado | no disponible]
* Contexto: [valor seleccionado | no disponible]
* Modo rápido: [activado | desactivado | no disponible]
* Repositorios afectados:
  * [repositorio]

Execution controls are model-dependent. Do not assume that Thinking, effort,
context size, Fast mode, or their possible values are available for every
model.

Choose the model first, then inspect the controls Cursor exposes for that
model and report their actual selected values. Use `no disponible` for
controls the selected model does not expose.

**Model:** evaluate the models actually available in Cursor, across providers.
Do not privilege a provider or automatically choose the most powerful model.
Prefer models suited to agentic repository work for investigation, multi-file
editing, testing, iteration and self-correction; use lighter options for
mechanical tasks. Use the model's base name and keep separately configurable
execution controls separate from the model name.

**Thinking:** when available, enable it when sustained reasoning, evidence
interpretation, ambiguity, architectural decisions, multiple constraints or
non-trivial self-correction materially benefit from it. Do not assume it
exists for every model.

**Effort:** when available, choose deliberately among the levels actually
exposed by the selected model. Scale effort with difficulty, ambiguity and
risk. Use lower levels for mechanical or tightly specified work and higher
levels only when deeper reasoning has concrete value. Do not assume all
models expose the same levels or a `Max` setting.

**Context:** when configurable, use the smaller/default context unless the
task genuinely requires keeping substantially more code, documentation,
history or tool output in context simultaneously. Do not use larger context
as a substitute for deeper reasoning. Do not assume context size is manually
configurable for every model.

**Fast mode:** when available, keep it disabled by default. Enable it only
when reduced latency has concrete operational value and its speed/cost
trade-off is appropriate for the task.

Model, Thinking, effort, context and Fast mode are independent where Cursor
exposes them independently. Never infer one setting from another.

Because Cursor's available models and controls can change, prefer the current
Cursor UI over hard-coded model-specific capability tables in these
instructions.

Project, repository, and task instructions may specialize or replace general
values within their own authority, including repository scope, permissions, or
execution behavior. They do not replace this policy with a default vendor,
family, or host tool.
