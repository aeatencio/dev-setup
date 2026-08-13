# dev-setup

Minimal, reproducible setup for my Windows development environment.

The goal is to keep development machines replaceable. Persistent configuration
and recovery instructions should live in versioned repositories or cloud
services rather than on a specific computer.

## Base tools

This setup currently assumes a Windows development machine with:

- Windows Terminal
- PowerShell 7.6.4 installed with the MSI/WiX package
- Git for Windows
- GitHub CLI
- Visual Studio Code
- OpenAI Codex

### Installation

Install the base tools with WinGet:

```powershell
winget install --id Microsoft.WindowsTerminal --exact --source winget
winget install --id Microsoft.PowerShell --exact --source winget --version 7.6.4.0 --installer-type wix
winget install --id Git.Git --exact --source winget
winget install --id GitHub.cli --exact --source winget
winget install --id Microsoft.VisualStudioCode --exact --source winget
```

PowerShell is the only exception: its version and MSI/WiX installer are pinned
as a compatibility workaround for Codex's Windows sandbox, not as a general
preference for MSI over MSIX. See
[`docs/decisions/001-powershell-msi-for-codex-windows.md`](docs/decisions/001-powershell-msi-for-codex-windows.md)
for the test results, scope, and review conditions.

Project-specific runtimes and tools — such as Node.js, Python, Docker, or
language SDKs — are installed only when a project requires them.

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
6. Install the base Visual Studio Code extensions by running `.\vscode\setup.ps1`.
7. Sign in to Visual Studio Code and enable Settings Sync.
8. Configure the general collaboration defaults:

   - Copy the complete contents of `codex\AGENTS.md` into ChatGPT at
     `Settings > Personalization > Custom Instructions`.
   - Install the behavior agreement and technical Codex settings by running
     `.\codex\setup.ps1`.
9. Authenticate Codex.
10. Clone the repository you want to work on.
11. Install any project-specific dependencies required by that repository.
12. Verify the reconstructed environment by running `.\verify.ps1`.

`codex\AGENTS.md` contains general behavior values. `codex\config.toml` contains
the user-level sandbox and approval defaults: workspace writes are allowed,
escalations can be requested, and eligible requests go to automatic review.
Project instructions and configuration may specialize these defaults; the
concrete task always defines the current objective and authority. ChatGPT Custom
Instructions are account configuration, remain manual, and cannot be checked by
`verify.ps1`. Authentication, cookies, session data, and other sensitive state
must remain outside this repository.

`codex\setup.ps1` creates `$HOME\.codex` when needed and is safe to run again
when the managed values are current. It does not overwrite different existing
instructions or conflicting technical values. When safe, it adds missing root
settings to `config.toml` while preserving unrelated options and sections. A
global `AGENTS.override.md` is preserved and reported because it may displace
the general agreement.

## Verification

`verify.ps1` is a read-only check of the documented base environment. It does
not install or repair tools, change configuration, or cover project-specific
runtimes and tools. Tool versions are normally reported for information; only
explicit compatibility decisions, such as the pinned PowerShell version and
MSI/WiX installation, are enforced.

`[OK]` means a check completed successfully, `[MISSING]` means a required part
of the base environment is absent or incorrect, and `[REVIEW]` means a check
could not be confirmed reliably or deserves attention. Only `[MISSING]` causes
a nonzero exit code. The VS Code extension inventory defines a required minimum,
so additional extensions are allowed. Local changes in `dev-setup` are reported
as `[REVIEW]` because the local definition differs from the last committed
state, not because the environment is broken.

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
- `codex/AGENTS.md` — canonical general collaboration agreement for ChatGPT and
  Codex.
- `codex/config.toml` — canonical user-level Codex sandbox and approval values.
- `codex/setup.ps1` — safely installs the agreement and managed Codex settings.
- `git/setup.ps1` — global Git preferences shared across my development machines.
- `docs/decisions/001-powershell-msi-for-codex-windows.md` — rationale for using
  the PowerShell MSI/WiX package with Codex on Windows.
- `vscode/setup.ps1` — installs the base extensions defined in
  `vscode/extensions.txt`.
- `vscode/extensions.txt` — current base VS Code extensions.
- `vscode/extensions-legacy-2026-08-08.txt` — historical snapshot from before
  cleaning up the environment.

## Security

This repository must never contain passwords, access tokens, API keys,
authentication files, cookies, or other secrets.
