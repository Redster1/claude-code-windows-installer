# Claude Code Installer - NSIS-Safe Progress Tracking Module
# Contains only minimal wrapper functions with NO restricted characters
# All complex progress logic delegated to separate script files

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Module-level variables - NO restricted characters
$script:ScriptRoot = $PSScriptRoot
$script:InternalScriptsPath = Join-Path (Split-Path $script:ScriptRoot -Parent) "internal"

#region NSIS-Safe Progress Functions

function Initialize-ProgressSystem {
    <#
    .SYNOPSIS
    Initializes progress tracking system
    #>
    
    param(
        [Parameter(Mandatory)]
        [int]$TotalSteps
    )
    
    $progressScript = Join-Path $script:InternalScriptsPath "ProgressSystem.ps1"
    
    if (-not (Test-Path $progressScript)) {
        return $false
    }
    
    try {
        $result = . $progressScript -Action "Initialize" -TotalSteps $TotalSteps
        return $result
    }
    catch {
        return $false
    }
}

function Update-ProgressStep {
    <#
    .SYNOPSIS
    Updates installation progress
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$StepName,
        [Parameter(Mandatory)]
        [ValidateSet('starting', 'in_progress', 'completed', 'failed', 'skipped')]
        [string]$Status
    )
    
    if (-not $PSCmdlet.ShouldProcess("Progress Step: $StepName", "Update Status to $Status")) {
        return
    }
    
    $progressScript = Join-Path $script:InternalScriptsPath "ProgressSystem.ps1"
    
    if (-not (Test-Path $progressScript)) {
        return $null
    }
    
    try {
        $result = . $progressScript -Action "Update" -StepName $StepName -Status $Status
        return $result
    }
    catch {
        return $null
    }
}

function Start-InstallPhase {
    <#
    .SYNOPSIS
    Starts a new installation phase
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$PhaseName,
        [int]$PhaseSteps = $null
    )
    
    if (-not $PSCmdlet.ShouldProcess("Installation Phase: $PhaseName", "Start Phase")) {
        return
    }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Output "$timestamp-Starting-Phase-$PhaseName"
    
    if ($PhaseSteps) {
        Write-Output "$timestamp-Expected-steps-$PhaseSteps"
    }
    
    return Update-ProgressStep -StepName "Starting-$PhaseName" -Status 'starting'
}

function Complete-InstallPhase {
    <#
    .SYNOPSIS
    Completes an installation phase
    #>
    
    param(
        [Parameter(Mandatory)]
        [string]$PhaseName
    )
    
    $result = Update-ProgressStep -StepName "Completed-$PhaseName" -Status 'completed'
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Output "$timestamp-Phase-completed-$PhaseName"
    
    return $result
}

function Write-NSISProgress {
    <#
    .SYNOPSIS
    Writes progress data for NSIS consumption
    #>
    
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, 100)]
        [double]$Progress,
        [string]$StatusText = "",
        [string]$SubText = ""
    )
    
    $roundedProgress = [math]::Round($Progress)
    
    # Output for NSIS to capture
    Write-Output "NSIS_PROGRESS:$roundedProgress"
    Write-Output "NSIS_STATUS:$StatusText"
    if ($SubText) {
        Write-Output "NSIS_SUBTEXT:$SubText"
    }
    
    # Write to file for NSIS to read
    $nsisUpdatePath = "$env:TEMP\claude-installer-nsis-update.txt"
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HH:mm:ss'
    $nsisOutput = "Progress:$roundedProgress`nStatus:$StatusText`nSubText:$SubText`nTimestamp:$timestamp"
    
    try {
        $nsisOutput | Out-File -FilePath $nsisUpdatePath -Encoding UTF8 -Force
    }
    catch {
        Write-Verbose "Failed to write NSIS progress file: $($_.Exception.Message)"
    }
}

function Clear-ProgressFile {
    <#
    .SYNOPSIS
    Cleans up progress tracking files
    #>
    
    $filesToClean = @(
        "$env:TEMP\claude-installer-progress.json",
        "$env:TEMP\claude-installer-ps-update.json", 
        "$env:TEMP\claude-installer-nsis-update.txt"
    )
    
    foreach ($file in $filesToClean) {
        if (Test-Path $file) {
            try {
                Remove-Item $file -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "Failed to clean up progress file: $($_.Exception.Message)"
            }
        }
    }
}

#endregion

# Export only safe function names - NO restricted characters
Export-ModuleMember -Function @(
    'Initialize-ProgressSystem',
    'Update-ProgressStep',
    'Start-InstallPhase',
    'Complete-InstallPhase',
    'Write-NSISProgress',
    'Clear-ProgressFile'
)