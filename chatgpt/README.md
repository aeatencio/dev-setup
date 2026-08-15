# ChatGPT Project instructions

This directory stores reusable instructions for coordinating software
development from a ChatGPT Project. The canonical general template is
[`project-instructions/software-development.md`](project-instructions/software-development.md).
Its contents establish how ChatGPT, Codex, Terminal, and the user cooperate
without defining a particular project's data, architecture, or technical source
of truth.

## Configuration layers

- **Project instructions** provide durable coordination rules for one ChatGPT
  Project and may include a project-specific supplement.
- **Personal instructions** express account-level preferences that apply across
  ChatGPT conversations.
- **`AGENTS.md`** files guide Codex: the global file supplies general defaults,
  while repository files can specialize them for their own trees.
- **`config.toml`** controls Codex's technical settings, such as sandbox and
  approval behavior.

These layers complement rather than replace one another. The canonical template
does not override a project's own documentation, architecture decisions, data,
or repository-specific rules.

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
