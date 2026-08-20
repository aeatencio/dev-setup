# ChatGPT Project instructions

This directory stores reusable instructions for coordinating software
development from a ChatGPT Project. The canonical general template is
[`project-instructions/software-development.md`](project-instructions/software-development.md).
Its contents establish how ChatGPT, Cursor, Terminal, and the user cooperate
without defining a particular project's data, architecture, or technical source
of truth.

## Configuration layers

- **`dev-setup`** holds the versioned general development policy and the
  recoverable environment configuration.
- **ChatGPT Custom Instructions** are a runtime projection of the general
  rules ChatGPT needs to apply. They are currently maintained in Spanish and
  may include ChatGPT-specific rules. They are not a literal copy of
  `codex/AGENTS.md`.
- **Project instructions** apply this general template to one ChatGPT Project
  and may add a product-specific supplement.
- **Repository instructions** are the local authority for that tree.
- **The concrete task** defines the current objective, scope, and authority.

A more specific layer may specialize or replace general values within its
authority. That does not make the layers interchangeable sources of the same
information. This template does not override a project's own documentation,
architecture decisions, data, or repository-specific rules.

`codex/AGENTS.md` is the versioned general collaboration agreement.
`codex/setup.ps1` can materialize it, together with `config.toml`, into the
local Codex configuration. Codex remains installed and verified in VS Code;
it is not the primary implementation path in this template. Cursor
execution policy for preparing prompts is in
[`cursor/execution-configuration.md`](../cursor/execution-configuration.md);
it is not installed into Cursor. The current UI of a tool governs which models
and controls are available; it does not by itself redefine the working method.

## Manual installation and updates

1. Open
   [`project-instructions/software-development.md`](project-instructions/software-development.md)
   and copy its complete contents.
2. Open the target Project in ChatGPT and paste the content into that Project's
   instructions field.
3. Add a clearly separated project-specific supplement when needed. Keep that
   supplement focused on the project's purpose, canonical sources, repository
   boundaries, terminology, constraints, and authority rules; do not edit the
   general template merely to store project-specific facts.
4. Review the combined instructions for conflicts and save them in ChatGPT.

There is no automatic synchronization between this repository and ChatGPT.
When the canonical file changes, compare it with the Project's current
instructions, copy the new complete canonical text manually, reapply or retain
the separate project-specific supplement, review the result, and save it.

Do not copy secrets, credentials, authentication material, or unnecessary
private information into Project instructions or this repository.
