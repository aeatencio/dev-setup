$missingCount = 0
$reviewCount = 0

function Invoke-NativeText {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    foreach ($argument in $ArgumentList) { $null = $startInfo.ArgumentList.Add($argument) }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        $null = $process.Start()
        $errorRead = $process.StandardError.ReadToEndAsync()
        $output = $process.StandardOutput.ReadToEnd()
        $process.WaitForExit()
        $null = $errorRead.Result

        [pscustomobject]@{
            Output = $output.TrimEnd("`r", "`n")
            ExitCode = $process.ExitCode
        }
    } finally {
        $process.Dispose()
    }
}

function Write-Check {
    param(
        [ValidateSet("OK", "MISSING", "REVIEW")]
        [string]$Status,
        [string]$Message,
        [string]$Detail
    )

    if ($Status -eq "MISSING") { $script:missingCount++ }
    if ($Status -eq "REVIEW") { $script:reviewCount++ }

    Write-Host "[$Status] $Message"
    if ($Detail) { Write-Host "     $Detail" }
}

function Get-InstalledEditorExtensions {
    param(
        [string]$ExtensionsRoot,
        [string]$ReviewLabel
    )

    $installed = @{}
    if (-not (Test-Path -LiteralPath $ExtensionsRoot -PathType Container)) {
        Write-Check REVIEW "$ReviewLabel extension directory could not be found" $ExtensionsRoot
        return $installed
    }

    Get-ChildItem -LiteralPath $ExtensionsRoot -Directory | ForEach-Object {
        $manifestPath = Join-Path $_.FullName "package.json"
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            try {
                $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
                $extensionId = "$($manifest.publisher).$($manifest.name)".ToLowerInvariant()
                $installed[$extensionId] = $_.FullName
            } catch {
                Write-Check REVIEW "Could not read $ReviewLabel extension manifest" $manifestPath
            }
        }
    }

    return $installed
}

function Find-EditorExecutable {
    param(
        [string]$CliPath,
        [string]$ExecutableName
    )

    $directory = Split-Path -Path $CliPath -Parent
    while ($directory) {
        $candidate = Join-Path $directory $ExecutableName
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
        $parent = Split-Path -Path $directory -Parent
        if (-not $parent -or $parent -eq $directory) {
            break
        }
        $directory = $parent
    }

    return $null
}

$repoRoot = $PSScriptRoot
$extensionsFile = Join-Path $repoRoot "vscode\extensions.txt"
$cursorExtensionsFile = Join-Path $repoRoot "cursor\extensions.txt"
$codexInstructionsSource = Join-Path $repoRoot "codex\AGENTS.md"
$codexInstructionsDestination = Join-Path $HOME ".codex\AGENTS.md"
$codexInstructionsOverride = Join-Path $HOME ".codex\AGENTS.override.md"
$codexConfigSource = Join-Path $repoRoot "codex\config.toml"
$codexConfigUtilities = Join-Path $repoRoot "codex\config-utils.ps1"
$codexConfigDestination = Join-Path $HOME ".codex\config.toml"
$minimumNodeMajorVersion = 24

if ($IsWindows) {
    try {
        $windows = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $build = "$($windows.CurrentBuild).$($windows.UBR)"
        Write-Check OK "Windows $($windows.DisplayVersion)" "Build $build"
    } catch {
        Write-Check OK "Windows" $null
        Write-Check REVIEW "Windows version could not be read" $null
    }
} else {
    Write-Check MISSING "This script must run on Windows" $null
}

$winget = Get-Command winget -ErrorAction SilentlyContinue
if ($winget) {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Stop"
        $wingetVersion = & $winget.Source --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $wingetVersion) {
            Write-Check OK "WinGet $wingetVersion" $null
        } else {
            Write-Check REVIEW "WinGet is available, but its version could not be read" $null
        }
    } catch {
        Write-Check REVIEW "WinGet is available, but its version could not be read" $null
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
} else {
    Write-Check MISSING "WinGet command is not available" $null
}

$node = Get-Command node -CommandType Application -ErrorAction SilentlyContinue
if ($node) {
    try {
        $nodeVersionResult = Invoke-NativeText $node.Source @("--version")
        if ($nodeVersionResult.ExitCode -eq 0 -and $nodeVersionResult.Output -match '^v(?<version>\d+\.\d+\.\d+)$') {
            $nodeVersion = [version]$Matches.version
            Write-Check OK "Node.js $($nodeVersionResult.Output)" $node.Source
            if ($nodeVersion.Major -ge $minimumNodeMajorVersion) {
                Write-Check OK "Node.js meets the minimum major version $minimumNodeMajorVersion" $null
            } else {
                Write-Check REVIEW "Node.js is older than the minimum major version $minimumNodeMajorVersion" $nodeVersionResult.Output
            }
        } else {
            Write-Check REVIEW "Node.js is available, but its version could not be read" $node.Source
        }
    } catch {
        Write-Check REVIEW "Node.js is available, but its version could not be read" $_.Exception.Message
    }

    try {
        $nodeReleaseResult = Invoke-NativeText $node.Source @("-p", "JSON.stringify(process.release)")
        if ($nodeReleaseResult.ExitCode -eq 0 -and $nodeReleaseResult.Output) {
            $nodeRelease = $nodeReleaseResult.Output | ConvertFrom-Json
            if ($nodeRelease.lts -is [string] -and $nodeRelease.lts) {
                Write-Check OK "Node.js is an LTS release ($($nodeRelease.lts))" $null
            } else {
                Write-Check REVIEW "Node.js is not an LTS release" $node.Source
            }
        } else {
            Write-Check REVIEW "Node.js LTS status could not be read" $node.Source
        }
    } catch {
        Write-Check REVIEW "Node.js LTS status could not be interpreted" $_.Exception.Message
    }

    $expectedNodePath = "C:\Program Files\nodejs\node.exe"
    if ($node.Source -ieq $expectedNodePath) {
        Write-Check OK "Node.js executable is in the expected WinGet location" $node.Source
    } else {
        Write-Check REVIEW "Node.js executable is in an unexpected location" "Expected $expectedNodePath; found $($node.Source)"
    }
} else {
    Write-Check MISSING "Node.js command is not available" $null
}

$npm = Get-Command npm -ErrorAction SilentlyContinue
if ($npm) {
    try {
        $npmVersion = & $npm.Source --version 2>$null
        $npmExitCode = $LASTEXITCODE
        if ($npmExitCode -eq 0 -and $npmVersion -match '^\d+\.\d+\.\d+$') {
            Write-Check OK "npm $npmVersion" $npm.Source
        } else {
            Write-Check REVIEW "npm is available, but its version could not be read" $npm.Source
        }
    } catch {
        Write-Check REVIEW "npm is available, but its version could not be read" $npm.Source
    }

    $expectedNpmRoot = "C:\Program Files\nodejs"
    if ((Split-Path $npm.Source -Parent) -ieq $expectedNpmRoot) {
        Write-Check OK "npm is in the expected Node.js installation" $npm.Source
    } else {
        Write-Check REVIEW "npm is in an unexpected location" "Expected $expectedNpmRoot; found $($npm.Source)"
    }
} else {
    Write-Check MISSING "npm command is not available" $null
}

if (Get-Command wt -ErrorAction SilentlyContinue) {
    Write-Check OK "Windows Terminal command is available" $null
} else {
    Write-Check MISSING "Windows Terminal command is not available" $null
}

$expectedPowerShellPath = "C:\Program Files\PowerShell\7\pwsh.exe"
$powerShellVersion = $PSVersionTable.PSVersion.ToString()
$powerShellPath = (Get-Process -Id $PID).Path
if ($PSVersionTable.PSVersion.Major -eq 7) {
    Write-Check OK "PowerShell $powerShellVersion" $powerShellPath
} else {
    Write-Check MISSING "PowerShell version is $powerShellVersion; expected PowerShell 7" $powerShellPath
}
if ($powerShellPath -ieq $expectedPowerShellPath) {
    Write-Check OK "PowerShell executable matches the MSI/WiX installation" $powerShellPath
} else {
    Write-Check MISSING "PowerShell executable does not match the MSI/WiX installation" "Expected $expectedPowerShellPath; found $powerShellPath"
}

$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    $gitVersionResult = Invoke-NativeText $git.Source @("--version")
    if ($gitVersionResult.ExitCode -eq 0 -and $gitVersionResult.Output) {
        $gitVersion = $gitVersionResult.Output -replace '^git version ', ''
        Write-Check OK "Git $gitVersion" $git.Source
    } else {
        Write-Check REVIEW "Git is available, but its version could not be read" $git.Source
    }

    $expectedGitConfig = [ordered]@{
        "user.name" = "Andrés Atencio"
        "user.email" = "39921597+aeatencio@users.noreply.github.com"
        "init.defaultBranch" = "main"
        "core.autocrlf" = "input"
    }
    foreach ($key in $expectedGitConfig.Keys) {
        $configResult = Invoke-NativeText $git.Source @("config", "--global", "--get", $key)
        $actual = $configResult.Output
        if ($configResult.ExitCode -eq 1) {
            Write-Check MISSING "Git config: $key is not set" $null
        } elseif ($configResult.ExitCode -ne 0) {
            Write-Check REVIEW "Git config: $key could not be read" "Git exited with code $($configResult.ExitCode)"
        } elseif ($actual -ceq $expectedGitConfig[$key]) {
            Write-Check OK "Git config: $key=$actual" $null
        } else {
            Write-Check MISSING "Git config: $key is incorrect" "Expected '$($expectedGitConfig[$key])'; found '$actual'"
        }
    }
} else {
    Write-Check MISSING "Git command is not available" $null
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
    $ghVersionResult = Invoke-NativeText $gh.Source @("--version")
    if ($ghVersionResult.ExitCode -eq 0 -and $ghVersionResult.Output) {
        $ghVersion = ($ghVersionResult.Output -split "`r?`n")[0] -replace '^gh version ', ''
        Write-Check OK "GitHub CLI $ghVersion" $gh.Source
    } else {
        Write-Check REVIEW "GitHub CLI is available, but its version could not be read" $gh.Source
    }
    & $gh.Source auth status *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Check OK "GitHub CLI is authenticated" $null
    } else {
        Write-Check REVIEW "GitHub CLI authentication could not be confirmed" $null
    }
} else {
    Write-Check MISSING "GitHub CLI command is not available" $null
}

$code = Get-Command code -ErrorAction SilentlyContinue
$installedExtensions = @{}
if ($code) {
    $codeExe = Join-Path (Split-Path (Split-Path $code.Source -Parent) -Parent) "Code.exe"
    if (Test-Path -LiteralPath $codeExe -PathType Leaf) {
        $codeVersion = (Get-Item -LiteralPath $codeExe).VersionInfo.ProductVersion
        Write-Check OK "Visual Studio Code $codeVersion" $codeExe
    } else {
        Write-Check OK "Visual Studio Code command is available" $code.Source
        Write-Check REVIEW "Visual Studio Code version could not be read" $null
    }

    $installedExtensions = Get-InstalledEditorExtensions `
        -ExtensionsRoot (Join-Path $HOME ".vscode\extensions") `
        -ReviewLabel "VS Code"
} else {
    Write-Check MISSING "Visual Studio Code command is not available" $null
}

$requiredExtensions = @()
if (Test-Path -LiteralPath $extensionsFile -PathType Leaf) {
    $requiredExtensions = Get-Content -LiteralPath $extensionsFile |
        ForEach-Object { $_.Trim().ToLowerInvariant() } |
        Where-Object { $_ -and -not $_.StartsWith("#") }
    foreach ($extensionId in $requiredExtensions) {
        if ($installedExtensions.ContainsKey($extensionId)) {
            Write-Check OK "VS Code extension: $extensionId" $null
        } else {
            Write-Check MISSING "VS Code extension: $extensionId" $null
        }
    }
} else {
    Write-Check MISSING "VS Code extension inventory is missing" $extensionsFile
}

$cursor = Get-Command cursor -ErrorAction SilentlyContinue
$installedCursorExtensions = @{}
if ($cursor) {
    $cursorExe = Find-EditorExecutable -CliPath $cursor.Source -ExecutableName "Cursor.exe"
    if ($cursorExe) {
        $cursorVersion = (Get-Item -LiteralPath $cursorExe).VersionInfo.ProductVersion
        Write-Check OK "Cursor $cursorVersion" $cursorExe
    } else {
        Write-Check OK "Cursor command is available" $cursor.Source
        Write-Check REVIEW "Cursor version could not be read" $null
    }

    $installedCursorExtensions = Get-InstalledEditorExtensions `
        -ExtensionsRoot (Join-Path $HOME ".cursor\extensions") `
        -ReviewLabel "Cursor"
} else {
    Write-Check MISSING "Cursor command is not available" $null
}

$requiredCursorExtensions = @()
if (Test-Path -LiteralPath $cursorExtensionsFile -PathType Leaf) {
    $requiredCursorExtensions = Get-Content -LiteralPath $cursorExtensionsFile |
        ForEach-Object { $_.Trim().ToLowerInvariant() } |
        Where-Object { $_ -and -not $_.StartsWith("#") }
    foreach ($extensionId in $requiredCursorExtensions) {
        if ($installedCursorExtensions.ContainsKey($extensionId)) {
            Write-Check OK "Cursor extension: $extensionId" $null
        } else {
            Write-Check MISSING "Cursor extension: $extensionId" $null
        }
    }
} else {
    Write-Check MISSING "Cursor extension inventory is missing" $cursorExtensionsFile
}

if ($installedExtensions.ContainsKey("openai.chatgpt")) {
    $codexExe = Get-ChildItem -LiteralPath $installedExtensions["openai.chatgpt"] -Recurse -File -Filter "codex.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($codexExe) {
        Write-Check OK "Bundled Codex CLI is present" $codexExe.FullName
    } else {
        Write-Check MISSING "Bundled Codex CLI was not found in openai.chatgpt" $null
    }
}

if (-not (Test-Path -LiteralPath $codexInstructionsSource -PathType Leaf)) {
    Write-Check MISSING "Canonical Codex instructions are missing" $codexInstructionsSource
} elseif (-not (Test-Path -LiteralPath $codexInstructionsDestination -PathType Leaf)) {
    Write-Check MISSING "Global Codex instructions are not installed" $codexInstructionsDestination
} else {
    try {
        $sourceHash = (Get-FileHash -LiteralPath $codexInstructionsSource -Algorithm SHA256).Hash
        $destinationHash = (Get-FileHash -LiteralPath $codexInstructionsDestination -Algorithm SHA256).Hash
        if ($sourceHash -eq $destinationHash) {
            Write-Check OK "Global Codex instructions match the canonical source" $codexInstructionsDestination
        } else {
            Write-Check REVIEW "Global Codex instructions differ from the canonical source" $codexInstructionsDestination
        }
    } catch {
        Write-Check REVIEW "Codex instructions could not be compared reliably" $_.Exception.Message
    }
}

if (Test-Path -LiteralPath $codexInstructionsOverride) {
    Write-Check REVIEW "A global Codex instructions override is present" $codexInstructionsOverride
} else {
    Write-Check OK "No global Codex instructions override is present" $null
}

if (-not (Test-Path -LiteralPath $codexConfigSource -PathType Leaf)) {
    Write-Check MISSING "Canonical Codex configuration is missing" $codexConfigSource
} elseif (-not (Test-Path -LiteralPath $codexConfigUtilities -PathType Leaf)) {
    Write-Check MISSING "Codex configuration verifier is missing" $codexConfigUtilities
} else {
    try {
        . $codexConfigUtilities
        $configPlan = Get-CodexConfigPlan -SourcePath $codexConfigSource -DestinationPath $codexConfigDestination
        switch ($configPlan.Status) {
            "SourceMissing" {
                Write-Check MISSING "Canonical Codex configuration is missing" $codexConfigSource
            }
            "SourceInvalid" {
                Write-Check REVIEW "Canonical Codex configuration could not be interpreted reliably" ($configPlan.Errors -join " ")
            }
            "Create" {
                Write-Check MISSING "Global Codex configuration is not installed" $codexConfigDestination
            }
            "Update" {
                foreach ($key in $script:ManagedCodexConfigKeys) {
                    if ($configPlan.Missing -contains $key) {
                        Write-Check MISSING "Codex config: $key is not set" $codexConfigDestination
                    } else {
                        Write-Check OK "Codex config: $key=$($configPlan.Expected[$key])" $null
                    }
                }
            }
            "Current" {
                foreach ($key in $script:ManagedCodexConfigKeys) {
                    Write-Check OK "Codex config: $key=$($configPlan.Expected[$key])" $null
                }
            }
            default {
                Write-Check REVIEW "Global Codex configuration requires review" ($configPlan.Errors -join " ")
            }
        }
    } catch {
        Write-Check REVIEW "Codex configuration could not be interpreted reliably" $_.Exception.Message
    }
}

if ($git) {
    $repositoryResult = Invoke-NativeText $git.Source @("-C", $repoRoot, "rev-parse", "--is-inside-work-tree")
    if ($repositoryResult.ExitCode -ne 0) {
        Write-Check REVIEW "Repository status could not be confirmed" $repoRoot
    } elseif ($repositoryResult.Output -eq "true") {
        Write-Check OK "Repository root" $repoRoot
        $workingTreeResult = Invoke-NativeText $git.Source @("-C", $repoRoot, "status", "--porcelain")
        if ($workingTreeResult.ExitCode -ne 0) {
            Write-Check REVIEW "Repository working tree status could not be read" $repoRoot
        } elseif ($workingTreeResult.Output) {
            Write-Check REVIEW "Repository has local changes" $null
        } else {
            Write-Check OK "Repository working tree is clean" $null
        }
    } else {
        Write-Check MISSING "dev-setup is not a Git repository" $repoRoot
    }
} else {
    Write-Check MISSING "dev-setup is not a Git repository" $repoRoot
}

Write-Host ""
Write-Host "Summary: $missingCount missing, $reviewCount review."
if ($missingCount -gt 0) { exit 1 }
exit 0
