$extensionsFile = Join-Path $PSScriptRoot "extensions.txt"
$cursor = Get-Command cursor -ErrorAction SilentlyContinue

if (-not $cursor) {
    Write-Error "Cursor CLI ('cursor') is not available on PATH."
    exit 1
}

if (-not (Test-Path -LiteralPath $extensionsFile -PathType Leaf)) {
    Write-Error "Extension inventory not found: $extensionsFile"
    exit 1
}

$extensions = Get-Content -LiteralPath $extensionsFile |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith("#") }

foreach ($extensionId in $extensions) {
    & $cursor.Source --install-extension $extensionId
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Write-Error "Failed to install Cursor extension '$extensionId' (exit code $exitCode)."
        exit $exitCode
    }
}
