# dev-setup

Versioned, public record of my replaceable Windows development environment
and of the general development policy that should remain portable,
reproducible, auditable, or transparent outside a conversation.

The goal is to keep development machines replaceable and the working method
recoverable. Persistent configuration and general policy should live in
versioned repositories or cloud services rather than on a specific computer
or in a single conversation.

## Base tools

This setup currently assumes a Windows development machine with:

- Windows Terminal
- PowerShell 7 installed with the MSI/WiX package
- Git for Windows
- GitHub CLI
- Visual Studio Code
- Cursor
- Node.js LTS (including npm)
- ChatGPT
- OpenAI Codex

Visual Studio Code remains the verified ChatGPT and Codex editor surface,
including the bundled Codex CLI. Cursor is the primary implementation editor.
Each editor has its own extension inventory. Cursor currently requires only the
PowerShell extension; `openai.chatgpt` stays in Visual Studio Code and is not
duplicated in Cursor. Do not import a Visual Studio Code profile into Cursor.

### Installation

Install the base tools with WinGet:

```powershell
winget install --id Microsoft.WindowsTerminal --exact --source winget
winget install --id Microsoft.PowerShell --exact --source winget --installer-type wix
winget install --id Git.Git --exact --source winget
winget install --id GitHub.cli --exact --source winget
winget install --id Microsoft.VisualStudioCode --exact --source winget
winget install --id Anysphere.Cursor --exact --source winget
winget install --id OpenJS.NodeJS.LTS --exact --source winget
```

PowerShell is the only exception: the MSI/WiX installer is required as a
compatibility workaround for Codex's Windows sandbox, not as a general
preference for MSI over MSIX. The patch version is not pinned. See
[`docs/decisions/001-powershell-msi-for-codex-windows.md`](docs/decisions/001-powershell-msi-for-codex-windows.md)
for the test results, scope, and review conditions.

Node.js is maintained on its LTS channel as a general runtime; npm is included
with it. Python, Docker, other language SDKs, and project-specific tools are
installed only when a project requires them.

## Recovery

These instructions assume access to this repository and an Internet-connected
Windows installation with WinGet available.

1. Install the base tools listed above.
2. Close the shell used for installation, open Windows Terminal, set
   `PowerShell` as its default profile, and start a new PowerShell 7 session.
3. Create a local copy of this repository and enter it:

   ```powershell
   git clone https://github.com/aeatencio/dev-setup.git
   Set-Location .\dev-setup
   ```

4. Apply the Git configuration by running `.\git\setup.ps1`.
5. Authenticate with GitHub over HTTPS using `gh auth login --git-protocol https`.
6. Install or update Node.js LTS and its bundled npm by running
   `.\node\setup.ps1`.
7. Install the base Visual Studio Code extensions by running `.\vscode\setup.ps1`.
8. Sign in to Visual Studio Code and enable Settings Sync.
9. Install the base Cursor extensions by running `.\cursor\setup.ps1`.
10. Sign in to Cursor if an account is used. Do not import the Visual Studio
    Code profile into Cursor.
11. Configure the general collaboration defaults:

   - Apply the relevant general policy from `codex\AGENTS.md` as ChatGPT
     Custom Instructions (`Settings > Personalization > Custom Instructions`).
     That account field is a runtime projection: it may be in Spanish and may
     include ChatGPT-specific rules. It is not a literal copy of the file.
   - Materialize the agreement and technical Codex settings by running
     `.\codex\setup.ps1`.
12. Authenticate Codex.
13. Clone the repository you want to work on.
14. Install each project's npm dependencies locally in that project's
    repository. Each project declares its own Node.js compatibility; this setup
    does not install frameworks, build tools, or project npm packages globally.
15. Install any other project-specific dependencies required by that repository.
16. Verify the reconstructed environment by running `.\verify.ps1`.

`codex\AGENTS.md` is the versioned general collaboration policy.
`codex\config.toml` contains the user-level Codex sandbox and approval
defaults: workspace writes are allowed, escalations can be requested, and
eligible requests go to automatic review. `codex\setup.ps1` materializes those
files into `$HOME\.codex` when safe. ChatGPT Custom Instructions are a runtime
projection of the relevant general policy, currently maintained in Spanish, and
may include ChatGPT-specific rules; they remain manual and cannot be checked by
`verify.ps1`. Project, repository, and task instructions may specialize or
replace general values within their own authority. The concrete task defines
the current objective and authority. These layers are not interchangeable
sources of the same information. Authentication, cookies, session data, and
other sensitive state must remain outside this repository.

Reusable instructions for coordinating development in ChatGPT Projects are
documented in [`chatgpt/README.md`](chatgpt/README.md). They are copied into each
Project manually and are not installed or synchronized by this repository.

The policy for choosing Cursor models and execution controls when preparing
prompts is documented in
[`cursor/execution-configuration.md`](cursor/execution-configuration.md). It is
not installed or synchronized into Cursor. The current Cursor UI governs which
models, controls, and values are actually available; it does not by itself
redefine the working method.

`codex\setup.ps1` creates `$HOME\.codex` when needed and is safe to run again
when the managed values are current. It does not overwrite different existing
instructions or conflicting technical values. When safe, it adds missing root
settings to `config.toml` while preserving unrelated options and sections. A
global `AGENTS.override.md` is preserved and reported because it may displace
the general agreement.

## Verification

`verify.ps1` is a read-only, local check of the documented base environment. It
does not install or repair tools, change configuration, query online for newer
patches, or cover project-specific tools. Tool versions are normally reported
for information; only explicit compatibility decisions, such as PowerShell 7
and the MSI/WiX installation, are enforced.

`[OK]` means a check completed successfully, `[MISSING]` means a required part
of the base environment is absent or incorrect, and `[REVIEW]` means a check
could not be confirmed reliably or deserves attention. Only `[MISSING]` causes
a nonzero exit code. The VS Code and Cursor extension inventories define
required minima, so additional extensions are allowed. Local changes in
`dev-setup` are reported as `[REVIEW]` because the local definition differs
from the last committed state, not because the environment is broken.

Verification checks the canonical agreement and technical configuration, their
user-level installation, and whether an override or divergence deserves review.
It does not inspect ChatGPT account settings or guarantee the permissions of a
particular session: launch arguments, profiles, and project configuration may
have higher precedence.

## Possible future improvement

A future `bootstrap.ps1` may orchestrate the repeatable parts of Recovery,
providing a single entry point for rebuilding the base environment.

It should be added only after the documented Recovery process has been validated
on a clean Windows installation. Its purpose would be to reduce manual steps and
configuration drift, while keeping authentication, Settings Sync, and other
interactive or sensitive state outside the script.

## Contents

- `verify.ps1` — checks whether the machine meets the documented base setup.
- `chatgpt/README.md` — explains the manual use and maintenance of reusable
  ChatGPT Project instructions.
- `chatgpt/project-instructions/software-development.md` — canonical general
  coordination instructions for ChatGPT, Cursor, and Terminal in software
  development Projects.
- `codex/AGENTS.md` — versioned general collaboration agreement.
- `codex/config.toml` — canonical user-level Codex sandbox and approval values.
- `codex/setup.ps1` — materializes the agreement and managed Codex settings.
- `git/setup.ps1` — global Git preferences shared across my development machines.
- `node/setup.ps1` — installs or updates Node.js within the WinGet LTS channel;
  npm is bundled and no global npm packages are installed.
- `docs/decisions/001-powershell-msi-for-codex-windows.md` — rationale for using
  the PowerShell MSI/WiX package with Codex on Windows.
- `vscode/setup.ps1` — installs the base extensions defined in
  `vscode/extensions.txt`.
- `vscode/extensions.txt` — current base VS Code extensions.
- `vscode/extensions-legacy-2026-08-08.txt` — historical snapshot from before
  cleaning up the environment.
- `cursor/execution-configuration.md` — policy for choosing Cursor models and
  execution controls when preparing prompts.
- `cursor/setup.ps1` — installs the base extensions defined in
  `cursor/extensions.txt`.
- `cursor/extensions.txt` — current base Cursor extensions.

## Security

This repository must never contain passwords, access tokens, API keys,
authentication files, cookies, or other secrets.
