# dev-setup

Minimal, reproducible setup for my Windows development environment.

The goal is to keep development machines replaceable. Persistent configuration
and recovery instructions should live in versioned repositories or cloud
services rather than on a specific computer.

## Base tools

This setup currently assumes a Windows development machine with:

- Windows Terminal
- PowerShell 7
- Git for Windows
- GitHub CLI
- Visual Studio Code
- OpenAI Codex

WinGet is used when possible to install and update these tools.

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
- `vscode/extensions-legacy-2026-08-08.txt` — snapshot of legacy VS Code extensions before cleaning up the environment.

## Security

This repository must never contain passwords, access tokens, API keys,
authentication files, cookies, or other secrets.
