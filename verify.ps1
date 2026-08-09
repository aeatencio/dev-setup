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

$repoRoot = $PSScriptRoot
$extensionsFile = Join-Path $repoRoot "vscode\extensions.txt"

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

if (Get-Command wt -ErrorAction SilentlyContinue) {
    Write-Check OK "Windows Terminal command is available" $null
} else {
    Write-Check MISSING "Windows Terminal command is not available" $null
}

$expectedPowerShellPath = "C:\Program Files\PowerShell\7\pwsh.exe"
$powerShellVersion = $PSVersionTable.PSVersion.ToString()
$powerShellPath = (Get-Process -Id $PID).Path
if ($powerShellVersion -eq "7.6.4") {
    Write-Check OK "PowerShell $powerShellVersion" $powerShellPath
} else {
    Write-Check MISSING "PowerShell version is $powerShellVersion; expected 7.6.4" $powerShellPath
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

    $extensionsRoot = Join-Path $HOME ".vscode\extensions"
    if (Test-Path -LiteralPath $extensionsRoot -PathType Container) {
        Get-ChildItem -LiteralPath $extensionsRoot -Directory | ForEach-Object {
            $manifestPath = Join-Path $_.FullName "package.json"
            if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
                try {
                    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
                    $extensionId = "$($manifest.publisher).$($manifest.name)".ToLowerInvariant()
                    $installedExtensions[$extensionId] = $_.FullName
                } catch {
                    Write-Check REVIEW "Could not read VS Code extension manifest" $manifestPath
                }
            }
        }
    } else {
        Write-Check REVIEW "VS Code extension directory could not be found" $extensionsRoot
    }
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

if ($installedExtensions.ContainsKey("openai.chatgpt")) {
    $codexExe = Get-ChildItem -LiteralPath $installedExtensions["openai.chatgpt"] -Recurse -File -Filter "codex.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($codexExe) {
        Write-Check OK "Bundled Codex CLI is present" $codexExe.FullName
    } else {
        Write-Check MISSING "Bundled Codex CLI was not found in openai.chatgpt" $null
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
