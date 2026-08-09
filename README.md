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

WinGet is used when possible to install and update these tools.

For the Windows and Codex configuration tested here, install PowerShell with the
MSI/WiX package explicitly:

```powershell
winget install --id Microsoft.PowerShell --exact --source winget --version 7.6.4.0 --installer-type wix
```

This is a compatibility workaround for Codex's Windows sandbox, not a general
preference for MSI over MSIX. See
[`docs/decisions/001-powershell-msi-for-codex-windows.md`](docs/decisions/001-powershell-msi-for-codex-windows.md)
for the test results, scope, and review conditions.

Project-specific runtimes and tools — such as Node.js, Python, Docker, or
language SDKs — are installed only when a project requires them.

## Recovery

1. Install the base tools listed above.
2. Authenticate with GitHub using `gh auth login`.
3. Clone this repository.
4. Apply the Git configuration by running `.\git\setup.ps1`.
5. Sign in to Visual Studio Code and enable Settings Sync.
6. Authenticate Codex.
7. Clone the repository you want to work on.
8. Install any project-specific dependencies required by that repository.

## Contents

- `git/setup.ps1` — global Git preferences shared across my development machines.
- `docs/decisions/001-powershell-msi-for-codex-windows.md` — rationale for using
  the PowerShell MSI/WiX package with Codex on Windows.
- `vscode/extensions.txt` — current base VS Code extensions.
- `vscode/extensions-legacy-2026-08-08.txt` — historical snapshot from before
  cleaning up the environment.

## Security

This repository must never contain passwords, access tokens, API keys,
authentication files, cookies, or other secrets.
