# Claude Code Installer - PowerShell Progress Tracking Integration
# Provides PowerShell integration with the Node.js progress tracking system

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Module-level variables
$script:ProgressStatePath = "$env:TEMP\claude-installer-progress.json"
$script:PowerShellUpdatePath = "$env:TEMP\claude-installer-ps-update.json"
$script:NodeTrackerPath = $null
$script:CurrentTracker = $null

#region Core Progress Functions

function Initialize-ProgressTracker {
    <#
    .SYNOPSIS
    Initializes the progress tracking system for the installation
    
    .PARAMETER TotalSteps
    Total number of installation steps
    
    .PARAMETER NodeScriptPath
    Path to the Node.js progress tracker script
    #>
    
    param(
        [Parameter(Mandatory)]
        [int]$TotalSteps,
        
        [string]$NodeScriptPath = $null
    )
    
    Write-Host "🔧 Initializing progress tracking system..." -ForegroundColor Cyan
    
    # Find Node.js tracker script
    if (-not $NodeScriptPath) {
        $NodeScriptPath = Join-Path $PSScriptRoot "..\..\installer\progress-tracker.js"
        if (-not (Test-Path $NodeScriptPath)) {
            Write-Warning "Progress tracker script not found at: $NodeScriptPath"
            return $false
        }
    }
    
    $script:NodeTrackerPath = $NodeScriptPath
    
    try {
        # Initialize progress tracker via Node.js
        $initScript = @"
const ProgressTracker = require('$($NodeScriptPath.Replace('\', '/'))');
const tracker = new ProgressTracker($TotalSteps);
console.log('Progress tracker initialized with $TotalSteps steps');
"@
        
        $tempScriptPath = "$env:TEMP\init-progress.js"
        $initScript | Out-File -FilePath $tempScriptPath -Encoding UTF8
        
        $result = & node $tempScriptPath 2>&1
        Remove-Item $tempScriptPath -Force -ErrorAction SilentlyContinue
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Progress tracking initialized successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "Failed to initialize progress tracker: $result"
            return $false
        }
    }
    catch {
        Write-Warning "Error initializing progress tracker: $($_.Exception.Message)"
        return $false
    }
}

function Update-InstallationProgress {
    <#
    .SYNOPSIS
    Updates installation progress with current step information
    
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
        # Convert hashtable to JSON for Node.js
        $detailsJson = $Details | ConvertTo-Json -Compress -Depth 3
        
        # Create Node.js script to update progress
        $updateScript = @"
const ProgressTracker = require('$($script:NodeTrackerPath.Replace('\', '/'))');
const tracker = ProgressTracker.loadState() || new ProgressTracker(10);

const details = $detailsJson;
const result = tracker.updateProgress('$StepName', '$Status', details);

console.log(JSON.stringify({
    success: true,
    stepNumber: result.stepNumber,
    progress: Math.min((tracker.currentStep / tracker.totalSteps) * 100, 100),
    estimatedTimeRemaining: tracker.state.estimatedTimeRemaining
}));
"@
        
        $tempScriptPath = "$env:TEMP\update-progress.js"
        $updateScript | Out-File -FilePath $tempScriptPath -Encoding UTF8
        
        $result = & node $tempScriptPath 2>&1
        Remove-Item $tempScriptPath -Force -ErrorAction SilentlyContinue
        
        if ($LASTEXITCODE -eq 0) {
            $progressData = $result | ConvertFrom-Json
            
            # Display progress in PowerShell
            $statusEmoji = @{
                'starting' = '🔄'
                'in_progress' = '⏳'
                'completed' = '✅'
                'failed' = '❌'
                'skipped' = '⏭️'
            }
            
            $emoji = $statusEmoji[$Status]
            $progressPercent = [math]::Round($progressData.progress, 1)
            
            Write-Host "$emoji [$progressPercent%] $StepName" -ForegroundColor $(
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
            
            return $progressData
        } else {
            Write-Warning "Failed to update progress: $result"
            return $null
        }
    }
    catch {
        Write-Warning "Error updating progress: $($_.Exception.Message)"
        return $null
    }
}

function Start-InstallationPhase {
    <#
    .SYNOPSIS
    Starts a new phase of the installation
    
    .PARAMETER PhaseName
    Name of the installation phase
    
    .PARAMETER PhaseSteps
    Expected number of steps in this phase
    #>
    
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
    
    $details = @{ phase = $PhaseName }
    if ($PhaseSteps) {
        $details.phaseSteps = $PhaseSteps
    }
    
    return Update-InstallationProgress -StepName "Starting $PhaseName" -Status 'starting' -Details $details
}

function Complete-InstallationPhase {
    <#
    .SYNOPSIS
    Completes an installation phase
    
    .PARAMETER PhaseName
    Name of the installation phase
    
    .PARAMETER Summary
    Summary information about the completed phase
    #>
    
    param(
        [Parameter(Mandatory)]
        [string]$PhaseName,
        
        [hashtable]$Summary = @{}
    )
    
    $details = @{ 
        phase = $PhaseName
        summary = $Summary
    }
    
    $result = Update-InstallationProgress -StepName "Completed $PhaseName" -Status 'completed' -Details $details
    
    Write-Host "✨ Phase completed: $PhaseName" -ForegroundColor Green
    
    return $result
}

function Get-InstallationProgress {
    <#
    .SYNOPSIS
    Gets the current installation progress state
    #>
    
    try {
        if (Test-Path $script:ProgressStatePath) {
            $progressData = Get-Content $script:ProgressStatePath -Raw | ConvertFrom-Json
            return $progressData
        } else {
            Write-Warning "No progress state file found"
            return $null
        }
    }
    catch {
        Write-Warning "Error reading progress state: $($_.Exception.Message)"
        return $null
    }
}

function Get-PowerShellProgressUpdate {
    <#
    .SYNOPSIS
    Gets the latest progress update formatted for PowerShell/NSIS consumption
    #>
    
    try {
        if (Test-Path $script:PowerShellUpdatePath) {
            $updateData = Get-Content $script:PowerShellUpdatePath -Raw | ConvertFrom-Json
            return $updateData
        } else {
            return $null
        }
    }
    catch {
        Write-Warning "Error reading PowerShell progress update: $($_.Exception.Message)"
        return $null
    }
}

function Write-ProgressToNSIS {
    <#
    .SYNOPSIS
    Writes progress data in NSIS-compatible format
    
    .PARAMETER Progress
    Progress percentage (0-100)
    
    .PARAMETER StatusText
    Status text to display
    
    .PARAMETER SubText
    Additional sub-text
    #>
    
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, 100)]
        [double]$Progress,
        
        [string]$StatusText = "",
        
        [string]$SubText = ""
    )
    
    # Format for NSIS DetailPrint and Progress
    $nsisOutput = @"
Progress: $([math]::Round($Progress))
Status: $StatusText
SubText: $SubText
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    # Write to file that NSIS can read
    $nsisUpdatePath = "$env:TEMP\claude-installer-nsis-update.txt"
    $nsisOutput | Out-File -FilePath $nsisUpdatePath -Encoding UTF8 -Force
    
    # Also output to console for NSIS to capture
    Write-Output "NSIS_PROGRESS:$([math]::Round($Progress))"
    Write-Output "NSIS_STATUS:$StatusText"
    if ($SubText) {
        Write-Output "NSIS_SUBTEXT:$SubText"
    }
}

function Get-InstallationSummary {
    <#
    .SYNOPSIS
    Generates a summary of the installation process
    #>
    
    try {
        $summaryScript = @"
const ProgressTracker = require('$($script:NodeTrackerPath.Replace('\', '/'))');
const tracker = ProgressTracker.loadState();

if (tracker) {
    const summary = tracker.generateSummary();
    console.log(JSON.stringify(summary, null, 2));
} else {
    console.log(JSON.stringify({ error: 'No progress data available' }));
}
"@
        
        $tempScriptPath = "$env:TEMP\get-summary.js"
        $summaryScript | Out-File -FilePath $tempScriptPath -Encoding UTF8
        
        $result = & node $tempScriptPath 2>&1
        Remove-Item $tempScriptPath -Force -ErrorAction SilentlyContinue
        
        if ($LASTEXITCODE -eq 0) {
            return $result | ConvertFrom-Json
        } else {
            Write-Warning "Failed to get installation summary: $result"
            return $null
        }
    }
    catch {
        Write-Warning "Error getting installation summary: $($_.Exception.Message)"
        return $null
    }
}

function Clear-ProgressTracking {
    <#
    .SYNOPSIS
    Cleans up progress tracking files
    #>
    
    $filesToClean = @(
        $script:ProgressStatePath,
        $script:PowerShellUpdatePath,
        "$env:TEMP\claude-installer-nsis-update.txt"
    )
    
    foreach ($file in $filesToClean) {
        if (Test-Path $file) {
            try {
                Remove-Item $file -Force
                Write-Verbose "Cleaned up: $file"
            }
            catch {
                Write-Warning "Could not clean up $file: $($_.Exception.Message)"
            }
        }
    }
}

#endregion

#region Helper Functions

function Test-NodeJSAvailable {
    <#
    .SYNOPSIS
    Tests if Node.js is available for progress tracking
    #>
    
    try {
        $nodeVersion = & node --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Verbose "Node.js available: $nodeVersion"
            return $true
        } else {
            Write-Warning "Node.js not available - progress tracking will be limited"
            return $false
        }
    }
    catch {
        Write-Warning "Node.js not available - progress tracking will be limited"
        return $false
    }
}

function Write-SimpleProgress {
    <#
    .SYNOPSIS
    Simple progress output when Node.js tracking is not available
    
    .PARAMETER StepName
    Name of the step
    
    .PARAMETER Status
    Status of the step
    #>
    
    param(
        [string]$StepName,
        [string]$Status
    )
    
    $statusEmoji = @{
        'starting' = '🔄'
        'in_progress' = '⏳'
        'completed' = '✅'
        'failed' = '❌'
        'skipped' = '⏭️'
    }
    
    $emoji = $statusEmoji[$Status] || '📍'
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    Write-Host "$emoji [$timestamp] $StepName" -ForegroundColor $(
        switch ($Status) {
            'completed' { 'Green' }
            'failed' { 'Red' }
            'skipped' { 'Yellow' }
            default { 'Cyan' }
        }
    )
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Initialize-ProgressTracker',
    'Update-InstallationProgress',
    'Start-InstallationPhase',
    'Complete-InstallationPhase',
    'Get-InstallationProgress',
    'Get-PowerShellProgressUpdate',
    'Write-ProgressToNSIS',
    'Get-InstallationSummary',
    'Clear-ProgressTracking',
    'Test-NodeJSAvailable',
    'Write-SimpleProgress'
)