# Global Git configuration shared across my development machines.
# No credentials or secrets are stored here.

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Error "Git command is not available."
    exit 1
}

$settings = [ordered]@{
    "user.name" = "Andrés Atencio"
    "user.email" = "39921597+aeatencio@users.noreply.github.com"
    "init.defaultBranch" = "main"
    "core.autocrlf" = "input"
}

foreach ($key in $settings.Keys) {
    & $git.Source config --global $key $settings[$key]
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Write-Error "Failed to configure Git setting '$key' (exit code $exitCode)."
        exit $exitCode
    }
}

Write-Host ""
Write-Host "Git global configuration:"
foreach ($key in $settings.Keys) {
    Write-Host "$key=$($settings[$key])"
}
