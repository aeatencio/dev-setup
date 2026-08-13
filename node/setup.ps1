$packageId = "OpenJS.NodeJS.LTS"
$packageNotFoundExitCode = -1978335212 # 0x8A150014
$noApplicableUpdateExitCode = -1978335189 # 0x8A15002B

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Error "WinGet command is not available."
    exit 1
}

& $winget.Source list --id $packageId --exact --source winget --accept-source-agreements --disable-interactivity *> $null
$listExitCode = $LASTEXITCODE

if ($listExitCode -ne 0 -and $listExitCode -ne $packageNotFoundExitCode) {
    Write-Error "Failed to check whether $packageId is installed (exit code $listExitCode)."
    exit $listExitCode
}

$isInstalled = $listExitCode -eq 0

if (-not $isInstalled) {
    Write-Host "Installing Node.js LTS and bundled npm ($packageId)..."
    & $winget.Source install --id $packageId --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        Write-Error "Failed to install $packageId (exit code $exitCode)."
        exit $exitCode
    }
    Write-Host "Node.js LTS installation completed. Open a new shell if node is not yet on PATH."
    exit 0
}

Write-Host "Node.js LTS is installed; checking for an update within the LTS channel..."
& $winget.Source upgrade --id $packageId --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "Node.js LTS is current or was updated successfully."
    exit 0
}
if ($exitCode -eq $noApplicableUpdateExitCode) {
    Write-Host "Node.js LTS is already current; no applicable LTS update was found."
    exit 0
}

Write-Error "Failed to update $packageId (exit code $exitCode)."
exit $exitCode
