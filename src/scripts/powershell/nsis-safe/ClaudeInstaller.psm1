# Claude Code Installer - NSIS-Safe PowerShell Module
# Contains only minimal wrapper functions with NO restricted characters
# All complex logic delegated to separate script files to avoid NSIS import issues

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Module-level variables - NO restricted characters in names or values
$script:ScriptRoot = $PSScriptRoot
$script:InternalScriptsPath = Join-Path (Split-Path $script:ScriptRoot -Parent) "internal"

#region NSIS-Safe Wrapper Functions

function Invoke-SystemRequirementsCheck {
    <#
    .SYNOPSIS
    Validates system requirements for Claude Code installation
    #>
    
    $validationScript = Join-Path $script:InternalScriptsPath "SystemValidation.ps1"
    
    # Debug information
    $debugInfo = @{
        ScriptRoot = $script:ScriptRoot
        InternalScriptsPath = $script:InternalScriptsPath
        ValidationScriptPath = $validationScript
        ValidationScriptExists = (Test-Path $validationScript)
        WorkingDirectory = Get-Location
    }
    
    if (-not (Test-Path $validationScript)) {
        return @{
            Success = $false
            Error = "ValidationScriptNotFound"
            Message = "Cannot find SystemValidation.ps1 at: $validationScript"
            Debug = $debugInfo
        }
    }
    
    try {
        $result = . $validationScript
        if (-not $result) {
            return @{
                Success = $false
                Error = "ValidationScriptReturnedNull"
                Message = "SystemValidation.ps1 returned null result"
                Debug = $debugInfo
            }
        }
        return $result
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Message = "SystemValidation.ps1 threw exception: $($_.Exception.Message)"
            Debug = $debugInfo
        }
    }
}

function Test-BasicSystemRequirement {
    <#
    .SYNOPSIS
    Simple system requirements check without external scripts
    #>
    
    try {
        # Check Windows version
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $buildNumber = [int]$os.BuildNumber
        $windowsOK = $buildNumber -ge 19041
        
        # Check architecture
        $archOK = $env:PROCESSOR_ARCHITECTURE -eq 'AMD64'
        
        # Check admin rights
        $adminOK = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        
        $allPassed = $windowsOK -and $archOK -and $adminOK
        
        $details = @{
            WindowsBuild = $buildNumber
            WindowsOK = $windowsOK
            ArchitectureOK = $archOK
            AdminRightsOK = $adminOK
        }
        
        return @{
            Success = $allPassed
            Message = if ($allPassed) { "Basic system requirements met" } else { "Some basic requirements failed" }
            Details = $details
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Message = "Basic system check failed: $($_.Exception.Message)"
        }
    }
}

function Invoke-WSL2Installation {
    <#
    .SYNOPSIS
    Installs and configures WSL2
    #>
    
    param(
        [switch]$SkipIfExists,
        [switch]$AutoReboot
    )
    
    $installScript = Join-Path $script:InternalScriptsPath "WSL2Management.ps1"
    
    if (-not (Test-Path $installScript)) {
        return @{
            Success = $false
            Error = "WSL2ScriptNotFound"
        }
    }
    
    try {
        # Use dot-sourcing approach
        if ($SkipIfExists -and $AutoReboot) {
            $result = . $installScript -SkipIfExists -AutoReboot
        } elseif ($SkipIfExists) {
            $result = . $installScript -SkipIfExists
        } elseif ($AutoReboot) {
            $result = . $installScript -AutoReboot
        } else {
            $result = . $installScript
        }
        return $result
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Invoke-AlpineLinuxSetup {
    <#
    .SYNOPSIS
    Installs and configures Alpine Linux for Claude Code
    #>
    
    param(
        [switch]$SetAsDefault,
        [switch]$SkipIfExists,
        [string]$Username = "claude"
    )
    
    $setupScript = Join-Path $script:InternalScriptsPath "AlpineSetup.ps1"
    
    if (-not (Test-Path $setupScript)) {
        return @{
            Success = $false
            Error = "AlpineScriptNotFound"
        }
    }
    
    try {
        # Use dot-sourcing approach
        if ($SetAsDefault -and $SkipIfExists -and $Username -ne "claude") {
            $result = . $setupScript -SetAsDefault -SkipIfExists -Username $Username
        } elseif ($SetAsDefault -and $SkipIfExists) {
            $result = . $setupScript -SetAsDefault -SkipIfExists
        } elseif ($SetAsDefault -and $Username -ne "claude") {
            $result = . $setupScript -SetAsDefault -Username $Username
        } elseif ($SkipIfExists -and $Username -ne "claude") {
            $result = . $setupScript -SkipIfExists -Username $Username
        } elseif ($SetAsDefault) {
            $result = . $setupScript -SetAsDefault
        } elseif ($SkipIfExists) {
            $result = . $setupScript -SkipIfExists
        } elseif ($Username -ne "claude") {
            $result = . $setupScript -Username $Username
        } else {
            $result = . $setupScript
        }
        return $result
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-WSL2Status {
    <#
    .SYNOPSIS
    Checks current WSL2 installation status
    #>
    
    $statusScript = Join-Path $script:InternalScriptsPath "WSL2Status.ps1"
    
    if (-not (Test-Path $statusScript)) {
        return @{
            Installed = $false
            Error = "StatusScriptNotFound"
        }
    }
    
    try {
        $result = . $statusScript
        return $result
    }
    catch {
        return @{
            Installed = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-RebootNeeded {
    <#
    .SYNOPSIS
    Checks if system reboot is required
    #>
    
    try {
        $rebootKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\AutoUpdate\RebootRequired",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ComponentBasedServicing\RebootPending"
        )
        
        foreach ($key in $rebootKeys) {
            if (Test-Path $key) {
                return $true
            }
        }
        
        return $false
    }
    catch {
        return $false
    }
}

function Write-LogMessage {
    <#
    .SYNOPSIS
    Writes log message with timestamp
    #>
    
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $logEntry = "$timestamp-$Level-$Message"
    
    Write-Output $logEntry
    
    # Write to log file if possible
    $logPath = "$env:TEMP\ClaudeCodeInstaller.log"
    try {
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        Write-Verbose "Failed to write to log file: $($_.Exception.Message)"
    }
}

#endregion

# Export only safe function names - NO restricted characters
Export-ModuleMember -Function @(
    'Invoke-SystemRequirementsCheck',
    'Test-BasicSystemRequirement',
    'Invoke-WSL2Installation', 
    'Invoke-AlpineLinuxSetup',
    'Test-WSL2Status',
    'Test-RebootNeeded',
    'Write-LogMessage'
)