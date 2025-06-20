# Claude Code Installer - Progress System Script
# This script can contain any characters since it's not imported as a module

param(
    [Parameter(Mandatory)]
    [ValidateSet('Initialize', 'Update', 'Get', 'Clear')]
    [string]$Action,
    
    [int]$TotalSteps = 10,
    [string]$StepName = "",
    [string]$Status = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Progress state file
$ProgressStatePath = "$env:TEMP\\claude-installer-progress.json"

function Initialize-ProgressTracker {
    param([int]$TotalSteps)
    
    $progressState = @{
        TotalSteps = $TotalSteps
        CurrentStep = 0
        Steps = @()
        StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    try {
        $progressState | ConvertTo-Json -Depth 3 | Out-File -FilePath $ProgressStatePath -Encoding UTF8
        return $true
    }
    catch {
        return $false
    }
}

function Update-ProgressTracker {
    param(
        [string]$StepName,
        [string]$Status
    )
    
    try {
        $progressState = @{
            TotalSteps = 10
            CurrentStep = 0
            Steps = @()
            StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        # Load existing state if available
        if (Test-Path $ProgressStatePath) {
            $progressState = Get-Content $ProgressStatePath -Raw | ConvertFrom-Json
        }
        
        # Update current step
        $progressState.CurrentStep++
        $progressState.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Add step info
        $stepInfo = @{
            Name = $StepName
            Status = $Status
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            StepNumber = $progressState.CurrentStep
        }
        
        $progressState.Steps += $stepInfo
        
        # Save updated state
        $progressState | ConvertTo-Json -Depth 3 | Out-File -FilePath $ProgressStatePath -Encoding UTF8
        
        # Calculate progress percentage
        $progressPercent = [math]::Min(($progressState.CurrentStep / $progressState.TotalSteps) * 100, 100)
        
        return @{
            success = $true
            stepNumber = $progressState.CurrentStep
            progress = $progressPercent
            stepName = $StepName
            status = $Status
        }
    }
    catch {
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Get-ProgressState {
    try {
        if (Test-Path $ProgressStatePath) {
            $progressData = Get-Content $ProgressStatePath -Raw | ConvertFrom-Json
            return $progressData
        } else {
            return $null
        }
    }
    catch {
        return $null
    }
}

function Clear-ProgressState {
    try {
        if (Test-Path $ProgressStatePath) {
            Remove-Item $ProgressStatePath -Force
        }
        return $true
    }
    catch {
        return $false
    }
}

# Main execution based on action
try {
    switch ($Action) {
        'Initialize' {
            $result = Initialize-ProgressTracker -TotalSteps $TotalSteps
            return $result
        }
        'Update' {
            $result = Update-ProgressTracker -StepName $StepName -Status $Status
            return $result
        }
        'Get' {
            $result = Get-ProgressState
            return $result
        }
        'Clear' {
            $result = Clear-ProgressState
            return $result
        }
        default {
            throw "Unknown action: $Action"
        }
    }
}
catch {
    return @{
        success = $false
        error = $_.Exception.Message
        message = "Progress system action failed: $($_.Exception.Message)"
    }
}