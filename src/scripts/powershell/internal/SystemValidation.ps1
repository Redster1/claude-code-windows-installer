# Claude Code Installer - System Requirements Validation
# This script can contain any characters since it's not imported as a module

param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Constants
$MinWindowsBuild = 19041  # Windows 10 version 2004

function Test-SystemRequirements {
    Write-Output "Starting system requirements validation"
    
    $requirements = @{
        WindowsVersion = Test-WindowsVersion
        Architecture = Test-Architecture  
        DiskSpace = Test-DiskSpace
        AdminRights = Test-AdminRights
        Network = Test-NetworkConnectivity
        HyperV = Test-HyperVSupport
    }
    
    # Calculate overall pass/fail
    $failedCount = 0
    foreach ($requirement in $requirements.Values) {
        if (-not $requirement.Passed) {
            $failedCount++
        }
    }
    
    $requirements.OverallResult = @{
        Passed = $failedCount -eq 0
        Summary = if ($failedCount -eq 0) { "All system requirements met" } else { "$failedCount requirement(s) failed" }
    }
    
    Write-Output "System requirements validation completed"
    return $requirements
}

function Test-WindowsVersion {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $buildNumber = [int]$os.BuildNumber
        $version = $os.Version
        
        $passed = $buildNumber -ge $MinWindowsBuild
        
        return @{
            Passed = $passed
            BuildNumber = $buildNumber
            Version = $version
            ProductName = $os.Caption
            MinRequired = $MinWindowsBuild
            Message = if ($passed) { "Windows version compatible" } else { "Windows version too old. Requires build $MinWindowsBuild or later" }
        }
    }
    catch {
        return @{
            Passed = $false
            BuildNumber = 0
            Version = "Unknown"
            ProductName = "Unknown"
            MinRequired = $MinWindowsBuild
            Message = "Could not determine Windows version: $($_.Exception.Message)"
        }
    }
}

function Test-Architecture {
    $arch = $env:PROCESSOR_ARCHITECTURE
    $passed = $arch -eq 'AMD64'
    
    return @{
        Passed = $passed
        Architecture = $arch
        Message = if ($passed) { "x64 architecture confirmed" } else { "x64 architecture required, found: $arch" }
    }
}

function Test-DiskSpace {
    try {
        $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -ErrorAction Stop | Where-Object { $_.DeviceID -eq $env:SystemDrive }
        if (-not $systemDrive) {
            throw "Could not find system drive $env:SystemDrive"
        }
        
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        $requiredGB = 10
        $passed = $freeSpaceGB -ge $requiredGB
        
        return @{
            Passed = $passed
            FreeSpaceGB = $freeSpaceGB
            RequiredGB = $requiredGB
            Message = if ($passed) { "$freeSpaceGB GB available (sufficient)" } else { "Insufficient disk space. Need $requiredGB GB, have $freeSpaceGB GB" }
        }
    }
    catch {
        return @{
            Passed = $false
            FreeSpaceGB = 0
            RequiredGB = 10
            Message = "Could not check disk space: $($_.Exception.Message)"
        }
    }
}

function Test-AdminRights {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    return @{
        Passed = $isAdmin
        Message = if ($isAdmin) { "Administrator privileges confirmed" } else { "Administrator privileges required" }
    }
}

function Test-NetworkConnectivity {
    try {
        $testUrls = @(
            'https://api.github.com',
            'https://registry.npmjs.org',
            'https://aka.ms/wsl2kernel'
        )
        
        $results = @()
        foreach ($url in $testUrls) {
            try {
                $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing
                $results += @{
                    Url = $url
                    StatusCode = $response.StatusCode
                    Success = $response.StatusCode -eq 200
                }
            }
            catch {
                $results += @{
                    Url = $url
                    StatusCode = 0
                    Success = $false
                    Error = $_.Exception.Message
                }
            }
        }
        
        $allSuccess = ($results | Where-Object { $_.Success }).Count -eq $testUrls.Count
        
        return @{
            Passed = $allSuccess
            Results = $results
            Message = if ($allSuccess) { "Network connectivity confirmed" } else { "Network connectivity issues detected" }
        }
    }
    catch {
        return @{
            Passed = $false
            Message = "Network connectivity test failed: $($_.Exception.Message)"
        }
    }
}

function Test-HyperVSupport {
    try {
        $hyperVFeature = $null
        $vmPlatform = $null
        
        try {
            $hyperVFeature = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -ErrorAction SilentlyContinue
            $vmPlatform = Get-WindowsOptionalFeature -FeatureName VirtualMachinePlatform -Online -ErrorAction SilentlyContinue
        }
        catch {
            # Features may not be available on all Windows editions
        }
        
        # Check if virtualization is enabled in BIOS
        $virtualizationEnabled = $false
        try {
            $processor = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($processor -and $processor.PSObject.Properties['VirtualizationFirmwareEnabled']) {
                $virtualizationEnabled = $processor.VirtualizationFirmwareEnabled
            } else {
                # Fallback - assume enabled if we can't detect
                $virtualizationEnabled = $true
            }
        }
        catch {
            # Fallback check
            $virtualizationEnabled = $true  # Assume enabled if we can't detect
        }
        
        return @{
            Passed = $virtualizationEnabled
            HyperVAvailable = $null -ne $hyperVFeature
            VMPlatformAvailable = $null -ne $vmPlatform
            VirtualizationEnabled = $virtualizationEnabled
            Message = if ($virtualizationEnabled) { "Virtualization support available" } else { "Virtualization must be enabled in BIOS" }
        }
    }
    catch {
        return @{
            Passed = $false
            HyperVAvailable = $false
            VMPlatformAvailable = $false
            VirtualizationEnabled = $false
            Message = "Could not check virtualization support: $($_.Exception.Message)"
        }
    }
}

# Main execution
try {
    $result = Test-SystemRequirements
    
    # Transform result to expected format for NSIS integration
    return @{
        Success = $result.OverallResult.Passed
        Requirements = $result
        Message = $result.OverallResult.Summary
    }
}
catch {
    return @{
        Success = $false
        Error = $_.Exception.Message
        Message = "System validation failed: $($_.Exception.Message)"
    }
}