# 001: Use the PowerShell MSI/WiX package for Codex on Windows

- Date: 2026-08-08
- Status: Accepted (MSI/WiX workaround remains; exact 7.6.4 patch is not a
  general pin)
- Updated: 2026-08-19

## Context

This repository is used to rebuild a Windows development environment that runs
OpenAI Codex from the VS Code extension in "Ask for approval" mode. PowerShell
7.6.4 is available through both MSI/WiX and MSIX packages; WinGet selects MSIX by
default for PowerShell 7.6.x.

## Symptom

With the MSIX installation, Windows isolation blocked Codex's first local read
before the command ran. Codex then requested permission to repeat the repository
inspection outside the sandbox. That permission was deliberately denied.

## A/B comparison

The repository, VS Code, OpenAI extension, approval mode, PowerShell version, and
multi-file audit prompt were held constant.

- MSI/WiX: `C:\Program Files\PowerShell\7\pwsh.exe` could inspect the repository
  tree, run Git commands, and read multiple local files. The audit completed
  without requests to leave the sandbox.
- MSIX: `C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.4.0_x64__8wekyb3d8bbwe\pwsh.exe`
  was blocked by Windows isolation on the first read, before command execution.

The MSI/WiX installation is retained as the known working configuration.

The `codex sandbox windows` CLI subcommand also produced
`CreateProcessAsUserW` errors during diagnosis, including in conditions that did
not match Codex Chat behavior. It is therefore not the primary health check. The
relevant check is an actual multi-file repository operation from Codex Chat in
VS Code.

## Tested environment

- Windows 25H2, build 26200.8875
- PowerShell 7.6.4
- Visual Studio Code 1.132.0
- OpenAI VS Code extension 26.803.41515
- bundled Codex CLI 0.147.0-alpha.6.5

## Decision

Install PowerShell 7.6.4 explicitly with the MSI/WiX installer for this setup:

```powershell
winget install --id Microsoft.PowerShell --exact --source winget --version 7.6.4.0 --installer-type wix
```

Keep the Codex Windows sandbox enabled. Disabling or weakening it would trade
away an isolation boundary to accommodate a packaging-specific compatibility
problem, while MSI/WiX provides a working configuration without that tradeoff.

## Scope

This is a locally verified compatibility workaround for the versions and setup
described above. It is not a general claim that MSI is better than MSIX, nor a
claim about other PowerShell, Codex, editor, or Windows configurations.

## Review conditions

Revisit this decision when any of the following changes materially:

- the Codex or OpenAI VS Code extension version;
- Codex's Windows sandbox implementation;
- the PowerShell version or distribution; or
- an equivalent A/B test shows that MSIX works correctly.

## Update (2026-08-19)

The incompatibility confirmed on 2026-08-08 was the MSIX package versus
MSI/WiX. PowerShell 7.6.4 was held constant in that A/B test; it was the
tested snapshot, not an independent general requirement of the base
environment.

The standing requirement is PowerShell 7 installed with the MSI/WiX package
at `C:\Program Files\PowerShell\7\pwsh.exe`. Later 7.x patches such as 7.6.5
are accepted. The original install command with `--version 7.6.4.0` remains
the historically verified command; current recovery installs the current
PowerShell 7 MSI/WiX package without pinning that patch.
