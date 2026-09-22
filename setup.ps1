[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $PSCommandPath
$banner = @'
+---------------------------------------+
|          CODEX ORCHESTRATOR           |
|       Plan with Sol High.             |
|       Execute with Luna Max.          |
|       Review with Sol High.           |
+---------------------------------------+
'@

[Console]::WriteLine($banner)
[Console]::WriteLine('Interactive setup for Windows')

function Read-Confirmation {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter(Mandatory)]
        [bool]$DefaultYes
    )

    $suffix = if ($DefaultYes) { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        [Console]::Write("$Prompt $suffix ")
        $answer = [Console]::In.ReadLine()
        if ($null -eq $answer) {
            throw 'Input ended before setup was complete.'
        }

        switch ($answer.Trim().ToLowerInvariant()) {
            'y' { return $true }
            'yes' { return $true }
            'n' { return $false }
            'no' { return $false }
            '' { return $DefaultYes }
            default { [Console]::WriteLine('Please answer yes or no.') }
        }
    }
}

function Read-Scope {
    [Console]::WriteLine('Installation scope')
    [Console]::WriteLine('  1) Global (recommended) - applies to every Codex project for this user')
    [Console]::WriteLine('  2) Project - installs only into one repository')
    while ($true) {
        [Console]::Write('Select scope [1-2] (default 1): ')
        $answer = [Console]::In.ReadLine()
        if ($null -eq $answer) { throw 'Input ended before installation scope was selected.' }
        switch ($answer.Trim().ToLowerInvariant()) {
            '1' { return 'global' }
            'global' { return 'global' }
            '' { return 'global' }
            '2' { return 'project' }
            'project' { return 'project' }
            default { [Console]::WriteLine('Please enter 1 (global) or 2 (project).') }
        }
    }
}

function Read-Plan {
    [Console]::WriteLine('Choose Profile to install')
    [Console]::WriteLine('  1) Pro (4 subagents) - GPT-6 Sol (high) orchestrates; GPT-6 Luna (max) implements; Sol (high) reviews')
    [Console]::WriteLine('  2) Plus (compatibility alias, 4 subagents) - GPT-6 Sol (high) orchestrates; GPT-6 Luna (max) implements; Sol (high) reviews')
    [Console]::WriteLine('  3) Pro (max 2 subagents) - GPT-6 Sol (high) orchestrates; GPT-6 Luna (max) implements; Sol (high) reviews')
    [Console]::WriteLine('  4) Plus (compatibility alias, max 2 subagents) - GPT-6 Sol (high) orchestrates; GPT-6 Luna (max) implements; Sol (high) reviews')

    while ($true) {
        [Console]::Write('Select plan [1-4] (default 1): ')
        $answer = [Console]::In.ReadLine()
        if ($null -eq $answer) {
            throw 'Input ended before setup was complete.'
        }

        switch ($answer.Trim().ToLowerInvariant()) {
            '1' { return 'pro' }
            'pro' { return 'pro' }
            '' { return 'pro' }
            '2' { return 'plus' }
            'plus' { return 'plus' }
            '3' { return 'pro-max-2-subagents' }
            'pro-max-2-subagents' { return 'pro-max-2-subagents' }
            '4' { return 'plus-max-2-subagents' }
            'plus-max-2-subagents' { return 'plus-max-2-subagents' }
            default { [Console]::WriteLine('Please enter a listed plan number or name.') }
        }
    }
}

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    foreach ($sourceChild in (Get-ChildItem -LiteralPath $Source -Force)) {
        $destinationChildPath = Join-Path $Destination $sourceChild.Name
        $destinationChild = Get-Item -LiteralPath $destinationChildPath -Force -ErrorAction SilentlyContinue

        if ($sourceChild.PSIsContainer) {
            if ($null -eq $destinationChild) {
                New-Item -ItemType Directory -Path $destinationChildPath | Out-Null
            }
            elseif (-not $destinationChild.PSIsContainer) {
                throw "Cannot merge directory over file: $destinationChildPath"
            }

            Copy-DirectoryContents -Source $sourceChild.FullName -Destination $destinationChildPath
        }
        else {
            if (($null -ne $destinationChild) -and $destinationChild.PSIsContainer) {
                throw "Cannot overwrite directory with file: $destinationChildPath"
            }

            Copy-Item -LiteralPath $sourceChild.FullName -Destination $destinationChildPath -Force
        }
    }
}

function Find-ReparsePoint {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    foreach ($child in (Get-ChildItem -LiteralPath $Path -Force)) {
        if (($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            return $child.FullName
        }
        if ($child.PSIsContainer) {
            $nestedLink = Find-ReparsePoint -Path $child.FullName
            if ($null -ne $nestedLink) {
                return $nestedLink
            }
        }
    }

    return $null
}

function Test-DirectoryMergeCompatible {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    foreach ($sourceChild in (Get-ChildItem -LiteralPath $Source -Force)) {
        $destinationChildPath = Join-Path $Destination $sourceChild.Name
        $destinationChild = Get-Item -LiteralPath $destinationChildPath -Force -ErrorAction SilentlyContinue
        if ($null -eq $destinationChild) {
            continue
        }
        if ($sourceChild.PSIsContainer -ne $destinationChild.PSIsContainer) {
            return $false
        }
        if ($sourceChild.PSIsContainer -and (-not (Test-DirectoryMergeCompatible -Source $sourceChild.FullName -Destination $destinationChildPath))) {
            return $false
        }
    }

    return $true
}

function Get-OverwritePaths {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Source,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not $Source.PSIsContainer) {
        if ($null -ne (Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue)) {
            return $Name
        }
        return
    }

    foreach ($sourceFile in (Get-ChildItem -LiteralPath $Source.FullName -File -Recurse -Force)) {
        $relativePath = $sourceFile.FullName.Substring($Source.FullName.Length + 1)
        $destinationFile = Join-Path $Destination $relativePath
        if ($null -ne (Get-Item -LiteralPath $destinationFile -Force -ErrorAction SilentlyContinue)) {
            $path = $Name + [IO.Path]::DirectorySeparatorChar + $relativePath
            Write-Output $path
        }
    }
}

function Show-OverwriteWarning {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Source,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $paths = @(Get-OverwritePaths -Source $Source -Destination $Destination -Name $Name)
    if ($paths.Count -eq 0) {
        return
    }

    [Console]::WriteLine('WARNING: the following existing files will be overwritten:')
    foreach ($path in $paths) {
        [Console]::WriteLine("  - $path")
    }
}

function Get-MergedInstructions {
    param([Parameter(Mandatory)][string]$Destination)
    $existing = [IO.File]::ReadAllText($Destination).Replace("`r`n", "`n")
    $replacement = [IO.File]::ReadAllText((Join-Path $scriptDir 'AGENTS.md')).Replace("`r`n", "`n")
    $legacy = [IO.File]::ReadAllText((Join-Path $scriptDir 'scripts/legacy-sol-AGENTS.md')).Replace("`r`n", "`n").TrimEnd("`n")
    $beginMarker = '<!-- codex-orchestrator:begin -->'
    $endMarker = '<!-- codex-orchestrator:end -->'
    $begins = [regex]::Matches($existing, '(?m)^' + [regex]::Escape($beginMarker) + '$')
    $ends = [regex]::Matches($existing, '(?m)^' + [regex]::Escape($endMarker) + '$')
    if ($begins.Count -ne $ends.Count -or $begins.Count -gt 1 -or
        ($begins.Count -eq 1 -and $begins[0].Index -ge $ends[0].Index)) {
        throw 'Invalid managed instruction markers. Follow guides/migration.md; no files changed.'
    }
    $pattern = '(?ms)^' + [regex]::Escape($beginMarker) + '\n.*?^' +
        [regex]::Escape($endMarker) + '(?:\n|$)|^' + [regex]::Escape($legacy) + '(?:\n|$)'
    $output = [Text.StringBuilder]::new()
    $residual = [Text.StringBuilder]::new()
    $cursor = 0
    $written = $false
    foreach ($match in [regex]::Matches($existing, $pattern)) {
        $before = $existing.Substring($cursor, $match.Index - $cursor)
        $null = $output.Append($before)
        $null = $residual.Append($before)
        if (-not $written) { $null = $output.Append($replacement); $written = $true }
        $cursor = $match.Index + $match.Length
    }
    $tail = $existing.Substring($cursor)
    $null = $output.Append($tail)
    $null = $residual.Append($tail)
    if ($residual.ToString().Contains('sol-orchestrator') -and $residual.ToString() -match '(?i)gpt-5[.]6') {
        throw 'Customized legacy instructions require manual reconciliation. Follow guides/migration.md; no files changed.'
    }
    if (-not $written) {
        if ($output.Length -gt 0) {
            if (-not $output.ToString().EndsWith("`n")) { $null = $output.Append("`n") }
            $null = $output.Append("`n")
        }
        $null = $output.Append($replacement)
    }
    $result = $output.ToString()
    if (-not $result.EndsWith("`n")) { $result += "`n" }
    return $result
}

function Test-Instructions {
    param([Parameter(Mandatory)][string]$Destination)
    foreach ($path in @($Destination, "$Destination.bak")) {
        $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if ($null -ne $item -and ($item.PSIsContainer -or
            ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
            throw "Instructions and backup must be regular files: $path"
        }
    }
    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        $null = Get-MergedInstructions -Destination $Destination
    }
}

function Install-Instructions {
    param([Parameter(Mandatory)][string]$Destination)
    Test-Instructions -Destination $Destination
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        Copy-Item -LiteralPath (Join-Path $scriptDir 'AGENTS.md') -Destination $Destination
        [Console]::WriteLine("Installed instructions: $Destination")
        return $true
    }
    $existing = [IO.File]::ReadAllText($Destination)
    $merged = Get-MergedInstructions -Destination $Destination
    if ([string]::Equals($existing, $merged, [StringComparison]::Ordinal)) {
        [Console]::WriteLine("Skipped instructions: already current in $Destination.")
        return $false
    }
    Copy-Item -LiteralPath $Destination -Destination "$Destination.bak" -Force
    [IO.File]::WriteAllText($Destination, $merged, [Text.UTF8Encoding]::new($false))
    [Console]::WriteLine("Updated managed instructions; other rules preserved. Backup: $Destination.bak")
    return $true
}

function Install-Component {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$TargetDirectory,

        [string]$SourcePath
    )

    if ([string]::IsNullOrEmpty($SourcePath)) {
        $SourcePath = Join-Path $scriptDir $Name
    }
    $sourcePath = $SourcePath
    $destinationPath = Join-Path $TargetDirectory $Name
    $sourceItem = Get-Item -LiteralPath $sourcePath -Force -ErrorAction SilentlyContinue
    if ($null -eq $sourceItem) {
        throw "Setup source is missing: $sourcePath"
    }

    $destinationItem = Get-Item -LiteralPath $destinationPath -Force -ErrorAction SilentlyContinue
    if ($null -ne $destinationItem) {
        if (($destinationItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            [Console]::Error.WriteLine("Skipped ${Name}: the existing target is a symbolic link or junction.")
            return $false
        }

        if ($sourceItem.PSIsContainer -and $destinationItem.PSIsContainer) {
            $linkedPath = Find-ReparsePoint -Path $destinationPath
            if ($null -ne $linkedPath) {
                [Console]::Error.WriteLine("Skipped ${Name}: the existing target contains a symbolic link or junction ($linkedPath).")
                return $false
            }
            if (-not (Test-DirectoryMergeCompatible -Source $sourcePath -Destination $destinationPath)) {
                [Console]::Error.WriteLine("Skipped ${Name}: source and target types are incompatible.")
                return $false
            }
        }
        elseif (($sourceItem.PSIsContainer -and (-not $destinationItem.PSIsContainer)) -or ((-not $sourceItem.PSIsContainer) -and $destinationItem.PSIsContainer)) {
            [Console]::Error.WriteLine("Skipped ${Name}: source and target types are incompatible.")
            return $false
        }

        if ($Name -eq 'AGENTS.md') {
            return (Install-Instructions -Destination $destinationPath)
        }

        Show-OverwriteWarning -Source $sourceItem -Destination $destinationPath -Name $Name

        if (-not (Read-Confirmation -Prompt "Update ${Name}? New files will be added; only paths listed above will be replaced." -DefaultYes $false)) {
            [Console]::WriteLine("Skipped $Name (existing target left unchanged).")
            return $false
        }

        if ($sourceItem.PSIsContainer -and $destinationItem.PSIsContainer) {
            Copy-DirectoryContents -Source $sourcePath -Destination $destinationPath
        }
        elseif ((-not $sourceItem.PSIsContainer) -and (-not $destinationItem.PSIsContainer)) {
            Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
        }
        else {
            [Console]::Error.WriteLine("Skipped ${Name}: source and target types are incompatible.")
            return $false
        }

        [Console]::WriteLine("Updated $Name.")
        return $true
    }

    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Recurse -Force
    [Console]::WriteLine("Installed $Name.")
    return $true
}

function Merge-GlobalConfig {
    param([Parameter(Mandatory)][string]$SourceConfig, [Parameter(Mandatory)][string]$DestinationConfig)
    $source = [IO.File]::ReadAllText($SourceConfig)
    if (-not (Test-Path -LiteralPath $DestinationConfig -PathType Leaf)) {
        [IO.File]::WriteAllText($DestinationConfig, $source, [Text.UTF8Encoding]::new($false))
        return
    }
    $existing = [IO.File]::ReadAllText($DestinationConfig)
    $backup = "$DestinationConfig.bak"
    Copy-Item -LiteralPath $DestinationConfig -Destination $backup -Force
    $rootValues = [ordered]@{
        model = 'model = "gpt-6-sol"'
        model_reasoning_effort = 'model_reasoning_effort = "high"'
        approval_policy = 'approval_policy = "on-request"'
        sandbox_mode = 'sandbox_mode = "workspace-write"'
    }
    $agentValues = [ordered]@{
        enabled = 'enabled = true'
        max_concurrent_threads_per_session = if ($source -match 'max_concurrent_threads_per_session\s*=\s*2') { 'max_concurrent_threads_per_session = 2' } else { 'max_concurrent_threads_per_session = 4' }
        default_subagent_model = 'default_subagent_model = "gpt-6-luna"'
        default_subagent_reasoning_effort = 'default_subagent_reasoning_effort = "max"'
    }
    $lines = @($existing -split "\r?\n")
    $output = [System.Collections.Generic.List[string]]::new()
    $section = ''
    $rootSeen = @{}
    $agentsSeen = @{}
    $agentsFound = $false
    foreach ($line in $lines) {
        if ($line -match '^\s*\[') {
            if ($section -eq 'agents') { foreach ($key in $agentValues.Keys) { if (-not $agentsSeen.ContainsKey($key)) { $output.Add($agentValues[$key]) } } }
            $section = if ($line -match '^\s*\[([^]]+)\]\s*(?:#.*)?$') { $Matches[1].Trim() } else { '__other__' }
            if ($section -eq 'agents') { $agentsFound = $true }
            $output.Add($line); continue
        }
        if ($section -eq '' -and $line -match '^\s*([A-Za-z0-9_-]+)\s*=') {
            $key = $Matches[1]
            if ($rootValues.Contains($key)) { $output.Add($rootValues[$key]); $rootSeen[$key] = $true; continue }
        }
        if ($section -eq 'agents' -and $line -match '^\s*([A-Za-z0-9_-]+)\s*=') {
            $key = $Matches[1]
            if ($key -eq 'max_threads') { continue }
            if ($agentValues.Contains($key)) { $output.Add($agentValues[$key]); $agentsSeen[$key] = $true; continue }
        }
        $output.Add($line)
    }
    $firstTable = $output.FindIndex([Predicate[string]]{ param($line) $line -match '^\s*\[' })
    if ($firstTable -lt 0) { $firstTable = $output.Count }
    foreach ($key in @($rootValues.Keys)) { if (-not $rootSeen.ContainsKey($key)) { $output.Insert($firstTable, $rootValues[$key]); $firstTable++ } }
    if ($agentsFound) {
        if ($section -eq 'agents') { foreach ($key in $agentValues.Keys) { if (-not $agentsSeen.ContainsKey($key)) { $output.Add($agentValues[$key]) } } }
    } else {
        $output.Add(''); $output.Add('[agents]')
        foreach ($key in $agentValues.Keys) { $output.Add($agentValues[$key]) }
    }
    $merged = ($output -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine
    [IO.File]::WriteAllText($DestinationConfig, $merged, [Text.UTF8Encoding]::new($false))
    [Console]::WriteLine("Merged global config. Backup: $backup")
}

function Install-Global {
    param([Parameter(Mandatory)][string]$ProfileDirectory)
    $codexHome = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) { Join-Path $HOME '.codex' } else { $env:CODEX_HOME }
    $agentsHome = Join-Path $HOME '.agents'
    $legacySkill = Join-Path $agentsHome 'skills/astra-orchestrator'
    $globalInstructions = Join-Path $codexHome 'AGENTS.md'
    $hasLegacyInstructions = (Test-Path -LiteralPath $globalInstructions -PathType Leaf) -and ([IO.File]::ReadAllText($globalInstructions).Contains('astra-orchestrator'))
    if ((Test-Path -LiteralPath $legacySkill) -or $hasLegacyInstructions) { throw 'Legacy global orchestration found. Follow guides/migration.md before installing; no files changed.' }
    Test-Instructions -Destination $globalInstructions
    New-Item -ItemType Directory -Path $codexHome -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $codexHome 'agents') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $agentsHome 'skills') -Force | Out-Null
    Merge-GlobalConfig -SourceConfig (Join-Path $ProfileDirectory 'codex/config.toml') -DestinationConfig (Join-Path $codexHome 'config.toml')
    Copy-DirectoryContents -Source (Join-Path $ProfileDirectory 'codex/agents') -Destination (Join-Path $codexHome 'agents')
    Copy-DirectoryContents -Source (Join-Path $ProfileDirectory 'agents/skills') -Destination (Join-Path $agentsHome 'skills')
    $null = Install-Instructions -Destination $globalInstructions
    if (Test-Path -LiteralPath (Join-Path $codexHome 'AGENTS.override.md') -PathType Leaf) { [Console]::WriteLine('WARNING: AGENTS.override.md exists in CODEX_HOME, so Codex will prefer it over the installed global AGENTS.md.') }
    [Console]::WriteLine("Global setup complete in $codexHome and $agentsHome.")
    [Console]::WriteLine('Restart Codex and invoke $sol-orchestrator. Project-level config can still override global settings.')
}

try {
    $scope = Read-Scope
    $plan = Read-Plan
    $profileDirectory = Join-Path $scriptDir "profiles/$plan"
    if ($scope -eq 'global') {
        if (Read-Confirmation -Prompt 'Install GPT-6 role routing globally for this user?' -DefaultYes $true) { Install-Global -ProfileDirectory $profileDirectory }
        else { [Console]::WriteLine('Global installation skipped.') }
        exit 0
    }
    [Console]::Write('Target repository path: ')
    $targetPath = [Console]::In.ReadLine()
    if ($null -eq $targetPath) { throw 'Input ended before a target repository was provided.' }
    if ([string]::IsNullOrWhiteSpace($targetPath)) { throw 'Target repository path cannot be empty.' }
    $targetItem = Get-Item -LiteralPath $targetPath -Force -ErrorAction SilentlyContinue
    if (($null -eq $targetItem) -or (-not $targetItem.PSIsContainer)) { throw "Target must be an existing directory: $targetPath" }
    $targetDirectory = $targetItem.FullName
    if ([string]::Equals($targetDirectory, $scriptDir, [StringComparison]::OrdinalIgnoreCase)) { throw 'Target repository must be different from the setup source directory.' }
    $legacySkill = Join-Path $targetDirectory '.agents/skills/astra-orchestrator'
    $targetInstructions = Join-Path $targetDirectory 'AGENTS.md'
    $hasLegacyInstructions = (Test-Path -LiteralPath $targetInstructions -PathType Leaf) -and ([IO.File]::ReadAllText($targetInstructions).Contains('astra-orchestrator'))
    if ((Test-Path -LiteralPath $legacySkill) -or $hasLegacyInstructions) { throw 'Legacy orchestration found. Follow guides/migration.md before installing; no files changed.' }
    Test-Instructions -Destination $targetInstructions
    $installed = 0
    foreach ($component in '.codex', '.agents', 'AGENTS.md') {
        if (Read-Confirmation -Prompt ("Install {0}?" -f $component) -DefaultYes $true) {
            $result = if ($component -eq '.codex') { Install-Component -Name $component -TargetDirectory $targetDirectory -SourcePath (Join-Path $profileDirectory "codex") }
            elseif ($component -eq '.agents') { Install-Component -Name $component -TargetDirectory $targetDirectory -SourcePath (Join-Path $profileDirectory "agents") }
            else { Install-Component -Name $component -TargetDirectory $targetDirectory }
            if ($result) { $installed++ }
        } else { [Console]::WriteLine("Skipped $component.") }
    }
    [Console]::WriteLine()
    [Console]::WriteLine("Setup complete. $installed component(s) installed in $targetDirectory (plan: $plan).")
    [Console]::WriteLine('Restart Codex in the trusted target project and invoke $sol-orchestrator. See guides/ for validation and migration.')
}
catch {
    [Console]::Error.WriteLine("Setup cancelled: $($_.Exception.Message)")
    exit 1
}
