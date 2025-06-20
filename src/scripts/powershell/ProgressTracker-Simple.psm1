# Claude Code Installer - Simplified Progress Tracking
# Simplified version without complex Node.js integration to avoid PowerShell parsing issues

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Update-InstallationProgress {
    <#
    .SYNOPSIS
    Updates installation progress with current step information (simplified)
    
    .PARAMETER StepName
    Name of the current installation step
    
    .PARAMETER Status
    Status of the step: 'starting', 'in_progress', 'completed', 'failed', 'skipped'
    
    .PARAMETER Details
    Additional details about the step (hashtable)
    #>
    
    param(
        [Parameter(Mandatory)]
        [string]$StepName,
        
        [Parameter(Mandatory)]
        [ValidateSet('starting', 'in_progress', 'completed', 'failed', 'skipped')]
        [string]$Status,
        
        [hashtable]$Details = @{}
    )
    
    try {
        # Use simple PowerShell progress display 
        $statusEmoji = @{
            'starting' = '🔄'
            'in_progress' = '⏳' 
            'completed' = '✅'
            'failed' = '❌'
            'skipped' = '⏭️'
        }
        
        $emoji = if ($statusEmoji[$Status]) { $statusEmoji[$Status] } else { '📍' }
        $timestamp = Get-Date -Format "HH:mm:ss"
        
        Write-Host "$emoji [$timestamp] $StepName" -ForegroundColor $(
            switch ($Status) {
                'completed' { 'Green' }
                'failed' { 'Red' }
                'skipped' { 'Yellow' }
                default { 'Cyan' }
            }
        )
        
        # Show warnings or errors
        if ($Details.warning) {
            Write-Host "   ⚠️  Warning: $($Details.warning)" -ForegroundColor Yellow
        }
        
        if ($Status -eq 'failed' -and $Details.error) {
            Write-Host "   💥 Error: $($Details.error)" -ForegroundColor Red
        }
        
        # Return simple progress data
        return @{
            success = $true
            stepName = $StepName
            status = $Status
            timestamp = $timestamp
        }
    }
    catch {
        Write-Warning "Error updating progress: $($_.Exception.Message)"
        return $null
    }
}

function Start-InstallationPhase {
    param(
        [Parameter(Mandatory)]
        [string]$PhaseName,
        [int]$PhaseSteps = $null
    )
    
    Write-Host ""
    Write-Host "🚀 Starting Phase: $PhaseName" -ForegroundColor Magenta
    if ($PhaseSteps) {
        Write-Host "   Expected steps: $PhaseSteps" -ForegroundColor Gray
    }
    
    return Update-InstallationProgress -StepName "Starting $PhaseName" -Status 'starting'
}

function Complete-InstallationPhase {
    param(
        [Parameter(Mandatory)]
        [string]$PhaseName,
        [hashtable]$Summary = @{}
    )
    
    $result = Update-InstallationProgress -StepName "Completed $PhaseName" -Status 'completed' -Details $Summary
    Write-Host "✨ Phase completed: $PhaseName" -ForegroundColor Green
    return $result
}

# Export functions
Export-ModuleMember -Function @(
    'Update-InstallationProgress',
    'Start-InstallationPhase', 
    'Complete-InstallationPhase'
)