$extensionsFile = Join-Path $PSScriptRoot "extensions.txt"
$code = Get-Command code -ErrorAction SilentlyContinue

if (-not $code) {
    Write-Error "Visual Studio Code CLI ('code') is not available on PATH."
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
    & $code.Source --install-extension $extensionId
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Write-Error "Failed to install VS Code extension '$extensionId' (exit code $exitCode)."
        exit $exitCode
    }
}
