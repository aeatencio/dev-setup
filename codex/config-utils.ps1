$script:ManagedCodexConfigKeys = @(
    "approval_policy"
    "approvals_reviewer"
    "sandbox_mode"
)

function Test-SimpleTomlValue {
    param([string]$Value)

    $valueWithoutComment = $Value -replace '\s+#.*$', ''
    $trimmed = $valueWithoutComment.Trim()
    if (-not $trimmed) { return $false }
    if ($trimmed -match '^"(?:[^"\\]|\\.)*"$') { return $true }
    if ($trimmed -match "^'[^']*'$") { return $true }
    if ($trimmed -match '^(true|false)$') { return $true }
    if ($trimmed -match '^[+-]?(?:\d[\d_]*)(?:\.\d[\d_]*)?(?:[eE][+-]?\d[\d_]*)?$') { return $true }
    if ($trimmed -match '^\d{4}-\d{2}-\d{2}(?:[Tt ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:[Zz]|[+-]\d{2}:\d{2})?)?$') { return $true }
    if ($trimmed -match '^\[(?:[^\[\]"'']|"(?:[^"\\]|\\.)*"|''[^'']*'')*\]$') { return $true }
    if ($trimmed -match '^\{(?:[^\{\}"'']|"(?:[^"\\]|\\.)*"|''[^'']*'')*\}$') { return $true }
    return $false
}

function Read-CodexRootConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $content = [System.IO.File]::ReadAllText($Path)
    $lines = [regex]::Split($content, "\r\n|\n|\r")
    $values = @{}
    $counts = @{}
    foreach ($key in $script:ManagedCodexConfigKeys) { $counts[$key] = 0 }

    $errors = [System.Collections.Generic.List[string]]::new()
    $firstTableLine = -1
    $inRoot = $true
    $scope = "<root>"
    $assignments = @{}
    $standardTables = @{}
    $rootKeys = [System.Collections.Generic.List[string]]::new()

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith("#")) { continue }

        if ($trimmed.StartsWith("[")) {
            $isTable = $trimmed -match '^\[[^\[\]\r\n]+\]\s*(?:#.*)?$'
            $isTableArray = $trimmed -match '^\[\[[^\[\]\r\n]+\]\]\s*(?:#.*)?$'
            if (-not $isTable -and -not $isTableArray) {
                $errors.Add("Line $($index + 1) has an unsupported or malformed table header.")
            } elseif ($isTableArray) {
                $scope = "array:$($trimmed -replace '\s+#.*$', '')@$index"
            } else {
                $scope = $trimmed -replace '\s+#.*$', ''
                if ($standardTables.ContainsKey($scope)) {
                    $errors.Add("Standard table '$scope' is duplicated.")
                }
                $standardTables[$scope] = $true
            }
            if ($firstTableLine -lt 0) { $firstTableLine = $index }
            $inRoot = $false
            continue
        }

        if (-not $inRoot) {
            if ($trimmed -notmatch '^(?<key>[A-Za-z0-9_.\-"'']+)\s*=\s*(?<value>\S.*)$') {
                $errors.Add("Line $($index + 1) inside a table is not a simple assignment that can be preserved safely.")
            } else {
                $identity = "$scope::$($Matches.key)"
                if ($assignments.ContainsKey($identity)) {
                    $errors.Add("Key '$($Matches.key)' is duplicated in $scope.")
                }
                $assignments[$identity] = $true
                if (-not (Test-SimpleTomlValue $Matches.value)) {
                    $errors.Add("Line $($index + 1) has a value that cannot be interpreted safely.")
                }
            }
            continue
        }

        if ($trimmed -notmatch '=') {
            $errors.Add("Line $($index + 1) is not a root assignment that can be interpreted safely.")
            $errors.Add("Line $($index + 1) is not a supported root assignment.")
            continue
        }

        if ($trimmed -match '^(?<key>[A-Za-z0-9_-]+)\s*=\s*(?<value>.*)$') {
            $key = $Matches.key
            $rootKeys.Add($key)
            $identity = "<root>::$key"
            if ($assignments.ContainsKey($identity)) {
                $errors.Add("Root key '$key' is duplicated.")
            }
            $assignments[$identity] = $true
            if ($key -eq "default_permissions") {
                $errors.Add("Root key 'default_permissions' cannot be combined with managed sandbox_mode.")
                continue
            }
            if ($script:ManagedCodexConfigKeys -contains $key) {
                $counts[$key]++
                $valueText = $Matches.value
                if ($valueText -match '^"(?<value>[^"\r\n]*)"\s*(?:#.*)?$') {
                    $values[$key] = $Matches.value
                } else {
                    $errors.Add("Root key '$key' on line $($index + 1) does not use an unambiguous string value.")
                }
            } elseif (-not (Test-SimpleTomlValue $Matches.value)) {
                $errors.Add("Line $($index + 1) has a value that cannot be interpreted safely.")
            }
            continue
        }

        foreach ($key in $script:ManagedCodexConfigKeys) {
            if ($trimmed -match [regex]::Escape($key)) {
                $errors.Add("Line $($index + 1) uses an ambiguous form of managed key '$key'.")
            }
        }
        if ($trimmed -match 'default_permissions') {
            $errors.Add("Line $($index + 1) uses an ambiguous form of incompatible key 'default_permissions'.")
        }
        $errors.Add("Line $($index + 1) is not a supported root assignment.")
    }

    foreach ($key in $script:ManagedCodexConfigKeys) {
        if ($counts[$key] -gt 1) {
            $errors.Add("Root key '$key' is duplicated.")
        }
    }

    [pscustomobject]@{
        Content = $content
        Lines = $lines
        Values = $values
        Counts = $counts
        RootKeys = @($rootKeys)
        Errors = @($errors)
        FirstTableLine = $firstTableLine
    }
}

function Get-CodexConfigPlan {
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,
        [Parameter(Mandatory)]
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        return [pscustomobject]@{ Status = "SourceMissing"; Errors = @("Canonical Codex configuration is missing.") }
    }

    try {
        $source = Read-CodexRootConfig -Path $SourcePath
    } catch {
        return [pscustomobject]@{ Status = "SourceInvalid"; Errors = @($_.Exception.Message) }
    }

    $sourceErrors = [System.Collections.Generic.List[string]]::new()
    foreach ($errorMessage in $source.Errors) { $sourceErrors.Add($errorMessage) }
    foreach ($key in $script:ManagedCodexConfigKeys) {
        if ($source.Counts[$key] -ne 1) {
            $sourceErrors.Add("Canonical configuration must define root key '$key' exactly once.")
        }
    }
    foreach ($key in $source.RootKeys) {
        if ($script:ManagedCodexConfigKeys -notcontains $key) {
            $sourceErrors.Add("Canonical configuration contains unmanaged root key '$key'.")
        }
    }
    if ($source.FirstTableLine -ge 0) {
        $sourceErrors.Add("Canonical configuration must contain only managed root keys.")
    }
    if ($sourceErrors.Count -gt 0) {
        return [pscustomobject]@{ Status = "SourceInvalid"; Errors = @($sourceErrors) }
    }

    $expected = $source.Values
    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        return [pscustomobject]@{
            Status = "Create"
            Expected = $expected
            Missing = @($script:ManagedCodexConfigKeys)
            NewContent = $source.Content
            Errors = @()
        }
    }
    if (-not (Test-Path -LiteralPath $DestinationPath -PathType Leaf)) {
        return [pscustomobject]@{ Status = "Invalid"; Errors = @("Codex configuration path is not a file.") }
    }

    try {
        $destination = Read-CodexRootConfig -Path $DestinationPath
    } catch {
        return [pscustomobject]@{ Status = "Invalid"; Errors = @($_.Exception.Message) }
    }
    if ($destination.Errors.Count -gt 0) {
        return [pscustomobject]@{ Status = "Invalid"; Errors = $destination.Errors }
    }

    $missing = [System.Collections.Generic.List[string]]::new()
    $conflicts = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $script:ManagedCodexConfigKeys) {
        if ($destination.Counts[$key] -eq 0) {
            $missing.Add($key)
        } elseif ($destination.Values[$key] -cne $expected[$key]) {
            $conflicts.Add("Root key '$key' has a different value.")
        }
    }
    if ($conflicts.Count -gt 0) {
        return [pscustomobject]@{ Status = "Conflict"; Errors = @($conflicts); Expected = $expected }
    }
    if ($missing.Count -eq 0) {
        return [pscustomobject]@{ Status = "Current"; Errors = @(); Expected = $expected; Missing = @() }
    }

    $newline = if ($destination.Content.Contains("`r`n")) { "`r`n" } else { "`n" }
    $managedLines = @($missing | ForEach-Object { "$_ = `"$($expected[$_])`"" })
    $insertAt = $destination.FirstTableLine
    if ($insertAt -lt 0) { $insertAt = $destination.Lines.Count }
    $before = @($destination.Lines[0..($insertAt - 1)])
    if ($insertAt -eq 0) { $before = @() }
    $after = @($destination.Lines[$insertAt..($destination.Lines.Count - 1)])
    if ($insertAt -ge $destination.Lines.Count) { $after = @() }

    $newLines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $before) { $newLines.Add($line) }
    if ($newLines.Count -gt 0 -and $newLines[$newLines.Count - 1] -ne "") { $newLines.Add("") }
    foreach ($line in $managedLines) { $newLines.Add($line) }
    if ($after.Count -gt 0 -and $after[0] -ne "") { $newLines.Add("") }
    foreach ($line in $after) { $newLines.Add($line) }

    [pscustomobject]@{
        Status = "Update"
        Expected = $expected
        Missing = @($missing)
        NewContent = [string]::Join($newline, $newLines)
        Errors = @()
    }
}
