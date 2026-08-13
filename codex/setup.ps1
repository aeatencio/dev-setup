param(
    [string]$CodexHome = (Join-Path $HOME ".codex")
)

$instructionsSource = Join-Path $PSScriptRoot "AGENTS.md"
$configSource = Join-Path $PSScriptRoot "config.toml"
$configUtilities = Join-Path $PSScriptRoot "config-utils.ps1"
$instructionsDestination = Join-Path $CodexHome "AGENTS.md"
$instructionsOverride = Join-Path $CodexHome "AGENTS.override.md"
$configDestination = Join-Path $CodexHome "config.toml"

if (-not (Test-Path -LiteralPath $configUtilities -PathType Leaf)) {
    Write-Error "Codex configuration utilities not found: $configUtilities"
    exit 1
}
. $configUtilities

if (-not (Test-Path -LiteralPath $instructionsSource -PathType Leaf)) {
    Write-Error "Canonical Codex instructions not found: $instructionsSource"
    exit 1
}
if (-not (Test-Path -LiteralPath $configSource -PathType Leaf)) {
    Write-Error "Canonical Codex configuration not found: $configSource"
    exit 1
}
if (Test-Path -LiteralPath $CodexHome -PathType Leaf) {
    Write-Error "Codex home path is a file: $CodexHome"
    exit 1
}

$installInstructions = $true
if (Test-Path -LiteralPath $instructionsDestination) {
    if (-not (Test-Path -LiteralPath $instructionsDestination -PathType Leaf)) {
        Write-Error "Codex instructions path is not a file: $instructionsDestination"
        exit 1
    }
    $sourceHash = (Get-FileHash -LiteralPath $instructionsSource -Algorithm SHA256 -ErrorAction Stop).Hash
    $destinationHash = (Get-FileHash -LiteralPath $instructionsDestination -Algorithm SHA256 -ErrorAction Stop).Hash
    if ($sourceHash -ne $destinationHash) {
        Write-Error "Different Codex instructions already exist at $instructionsDestination. Review them manually; nothing was overwritten."
        exit 1
    }
    $installInstructions = $false
}

$configPlan = Get-CodexConfigPlan -SourcePath $configSource -DestinationPath $configDestination
if ($configPlan.Status -in @("SourceMissing", "SourceInvalid", "Invalid", "Conflict")) {
    Write-Error "Codex configuration cannot be updated safely: $($configPlan.Errors -join ' ') Nothing was written."
    exit 1
}

if (-not (Test-Path -LiteralPath $CodexHome -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $CodexHome -ErrorAction Stop
}
if ($configPlan.Status -in @("Create", "Update")) {
    $temporaryConfig = Join-Path $CodexHome ("config.toml.tmp-" + [guid]::NewGuid())
    try {
        [System.IO.File]::WriteAllText($temporaryConfig, $configPlan.NewContent, [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $temporaryConfig -Destination $configDestination -Force -ErrorAction Stop
    } finally {
        if (Test-Path -LiteralPath $temporaryConfig) {
            Remove-Item -LiteralPath $temporaryConfig -Force
        }
    }
    Write-Host "Installed managed Codex configuration: $configDestination"
} else {
    Write-Host "Managed Codex configuration is already current: $configDestination"
}

if ($installInstructions) {
    Copy-Item -LiteralPath $instructionsSource -Destination $instructionsDestination -ErrorAction Stop
    Write-Host "Installed Codex instructions: $instructionsDestination"
} else {
    Write-Host "Codex instructions are already current: $instructionsDestination"
}

if (Test-Path -LiteralPath $instructionsOverride) {
    Write-Warning "A global override exists and may displace AGENTS.md: $instructionsOverride"
}
