# Claude Code Installer - WSL2 Management Script
# This script can contain any characters since it's not imported as a module

param(
    [switch]$SkipIfExists,
    [switch]$AutoReboot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-WSL2Installation {
    try {
        # Check if WSL command is available
        $wslStatus = & wsl --status 2>$null
        if ($LASTEXITCODE -ne 0) {
            return @{
                Installed = $false
                Version = $null
                DefaultVersion = $null
                Distributions = @()
                Message = "WSL not installed"
            }
        }
        
        # Get WSL version
        $wslVersionOutput = & wsl --version 2>$null
        $versionMatch = $wslVersionOutput | Where-Object { $_ -match "WSL version: ([\\d\\.]+)" }
        $version = if ($versionMatch) { $matches[1] } else { "Unknown" }
        
        # Get default version
        $defaultVersion = & wsl --list --verbose 2>$null | Where-Object { $_ -match "Default Version: (\\d+)" }
        $defaultVer = if ($defaultVersion) { $matches[1] } else { "Unknown" }
        
        # Get distributions
        $distributions = Get-WSLDistributions
        
        return @{
            Installed = $true
            Version = $version
            DefaultVersion = $defaultVer
            Distributions = $distributions
            Message = "WSL2 version $version installed with $($distributions.Count) distribution(s)"
        }
    }
    catch {
        return @{
            Installed = $false
            Version = $null
            DefaultVersion = $null
            Distributions = @()
            Message = "Error checking WSL2: $($_.Exception.Message)"
        }
    }
}

function Get-WSLDistributions {
    try {
        $output = & wsl --list --verbose 2>$null
        $distributions = @()
        
        foreach ($line in $output) {
            if ($line -match '^\\s*\\*?\\s*([^\\s]+)\\s+(\\w+)\\s+(\\d+)') {
                $distributions += @{
                    Name = $matches[1]
                    State = $matches[2]
                    Version = $matches[3]
                    Default = $line.StartsWith('*')
                }
            }
        }
        
        return $distributions
    }
    catch {
        Write-Output "Error getting WSL distributions: $($_.Exception.Message)"
        return @()
    }
}

function Install-WSL2 {
    Write-Output "Starting WSL2 installation"
    
    # Check if already installed
    $wslStatus = Test-WSL2Installation
    if ($wslStatus.Installed -and $SkipIfExists) {
        Write-Output "WSL2 already installed, skipping"
        return @{
            Success = $true
            AlreadyInstalled = $true
            RebootRequired = $false
            Message = "WSL2 already installed and functional"
        }
    }
    
    $installationSteps = @()
    $rebootRequired = $false
    
    try {
        # Step 1: Check and enable WSL feature
        Write-Output "Checking WSL feature status"
        $wslFeatureStatus = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        
        if ($wslFeatureStatus.State -ne "Enabled") {
            Write-Output "Enabling Windows Subsystem for Linux"
            
            $wslFeature = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
            $installationSteps += "WSL Feature Enabled"
            
            if ($wslFeature.RestartNeeded) {
                $rebootRequired = $true
                Write-Output "WSL feature enabled - reboot required"
            }
        } else {
            Write-Output "WSL feature already enabled"
        }
        
        # Step 2: Check and enable Virtual Machine Platform
        Write-Output "Checking Virtual Machine Platform"
        $vmFeatureStatus = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
        
        if ($vmFeatureStatus.State -ne "Enabled") {
            Write-Output "Enabling Virtual Machine Platform"
            
            $vmFeature = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
            $installationSteps += "Virtual Machine Platform Enabled"
            
            if ($vmFeature.RestartNeeded) {
                $rebootRequired = $true
                Write-Output "Virtual Machine Platform enabled - reboot required"
            }
        } else {
            Write-Output "Virtual Machine Platform already enabled"
        }
        
        # Step 3: Handle reboot if required for features
        if ($rebootRequired) {
            Write-Output "Features enabled - reboot required"
            Write-Output "WSL2 features enabled successfully. Reboot required to continue."
            
            return @{
                Success = $true
                RebootRequired = $true
                RebootReason = "WSL2 features enabled"
                InstallationSteps = $installationSteps
                Message = "WSL2 features enabled. Please reboot and run installer again."
            }
        }
        
        # Step 4: Download and install WSL2 kernel (only if no reboot needed)
        Write-Output "Installing WSL2 kernel update"
        $kernelResult = Install-WSL2Kernel
        if (-not $kernelResult.Success) {
            throw "WSL2 kernel installation failed: $($kernelResult.Error)"
        }
        $installationSteps += "WSL2 Kernel Installed"
        
        # Step 5: Set WSL2 as default version
        Write-Output "Setting WSL2 as default version"
        
        $setDefaultResult = & wsl --set-default-version 2 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Output "WSL2 set as default version"
            $installationSteps += "WSL2 Set as Default"
        } else {
            Write-Output "Warning: Could not set WSL2 as default version: $setDefaultResult"
        }
        
        # Step 6: Final validation
        Write-Output "Validating installation"
        Start-Sleep -Seconds 2  # Allow services to initialize
        
        $finalStatus = Test-WSL2Installation
        if (-not $finalStatus.Installed) {
            throw "WSL2 installation validation failed"
        }
        
        Write-Output "WSL2 installation completed successfully"
        
        return @{
            Success = $true
            RebootRequired = $false
            InstallationSteps = $installationSteps
            KernelInstalled = $kernelResult.Success
            Version = $finalStatus.Version
            Message = "WSL2 installed and configured successfully"
        }
    }
    catch {
        Write-Output "WSL2 installation failed: $($_.Exception.Message)"
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            InstallationSteps = $installationSteps
            Message = "WSL2 installation failed: $($_.Exception.Message)"
        }
    }
}

function Install-WSL2Kernel {
    $kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $kernelPath = "$env:TEMP\\wsl_update_x64.msi"
    
    try {
        # Download kernel update
        Write-Output "Downloading WSL2 kernel from $kernelUrl"
        Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelPath -UseBasicParsing
        
        # Install kernel update
        Write-Output "Installing WSL2 kernel update"
        $installResult = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $kernelPath, "/quiet", "/norestart" -Wait -PassThru
        
        if ($installResult.ExitCode -eq 0) {
            Write-Output "WSL2 kernel installed successfully"
            return @{ Success = $true; ExitCode = 0 }
        }
        else {
            Write-Output "WSL2 kernel installation failed with exit code: $($installResult.ExitCode)"
            return @{ Success = $false; ExitCode = $installResult.ExitCode }
        }
    }
    catch {
        Write-Output "Error installing WSL2 kernel: $($_.Exception.Message)"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
    finally {
        # Clean up downloaded file
        if (Test-Path $kernelPath) {
            Remove-Item $kernelPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# Main execution
try {
    $result = Install-WSL2
    return $result
}
catch {
    return @{
        Success = $false
        Error = $_.Exception.Message
        Message = "WSL2 installation script failed: $($_.Exception.Message)"
    }
}