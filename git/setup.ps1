# Global Git configuration shared across my development machines.
# No credentials or secrets are stored here.

git config --global user.name "Andrés Atencio"
git config --global user.email "39921597+aeatencio@users.noreply.github.com"
git config --global init.defaultBranch main
git config --global core.autocrlf input

Write-Host ""
Write-Host "Git global configuration:"
git config --global --list
