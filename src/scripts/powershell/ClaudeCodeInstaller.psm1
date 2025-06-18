# Claude Code Windows Installer - PowerShell Module
# Handles system validation, WSL2 installation, and Windows-specific operations

#Requires -Version 5.1
#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Module-level variables
$script:LogPath = "$env:TEMP\ClaudeCodeInstaller.log"
$script:MinWindowsBuild = 19041  # Windows 10 version 2004

#region Logging Functions

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with colors
    switch ($Level) {
        'Info'    { Write-Host $logEntry -ForegroundColor White }
        'Warning' { Write-Host $logEntry -ForegroundColor Yellow }
        'Error'   { Write-Host $logEntry -ForegroundColor Red }
        'Success' { Write-Host $logEntry -ForegroundColor Green }
    }
    
    # Write to log file
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8
    }
    catch {
        # If we can't write to log, continue anyway
    }
}

function Write-Progress-Enhanced {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete = 0,
        [string]$CurrentOperation = $null
    )
    
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete -CurrentOperation $CurrentOperation
    Write-Log "Progress: $Activity - $Status ($PercentComplete%)" -Level Info
}

#endregion

#region System Validation Functions

function Test-SystemRequirements {
    <#
    .SYNOPSIS
    Validates system requirements for Claude Code installation
    
    .DESCRIPTION
    Checks Windows version, architecture, disk space, admin rights, and network connectivity
    
    .OUTPUTS
    Hashtable with validation results
    #>
    
    Write-Log "Starting system requirements validation" -Level Info
    
    $requirements = @{
        WindowsVersion = Test-WindowsVersion
        Architecture = Test-Architecture
        DiskSpace = Test-DiskSpace
        AdminRights = Test-AdminRights
        Network = Test-NetworkConnectivity
        HyperV = Test-HyperVSupport
        Antivirus = Test-AntivirusInterference
    }
    
    # Calculate overall pass/fail
    $allPassed = $requirements.Values | ForEach-Object { $_.Passed } | Where-Object { $_ -eq $false } | Measure-Object | Select-Object -ExpandProperty Count
    $requirements.OverallResult = @{
        Passed = $allPassed -eq 0
        Summary = if ($allPassed -eq 0) { "All system requirements met" } else { "$allPassed requirement(s) failed" }
    }
    
    Write-Log "System requirements validation completed" -Level Info
    return $requirements
}

function Test-WindowsVersion {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $buildNumber = [int]$os.BuildNumber
    $version = $os.Version
    
    $passed = $buildNumber -ge $script:MinWindowsBuild
    
    return @{
        Passed = $passed
        BuildNumber = $buildNumber
        Version = $version
        ProductName = $os.Caption
        MinRequired = $script:MinWindowsBuild
        Message = if ($passed) { "Windows version compatible" } else { "Windows version too old. Requires build $script:MinWindowsBuild or later" }
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
    $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
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
        $hyperVFeature = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -ErrorAction SilentlyContinue
        $vmPlatform = Get-WindowsOptionalFeature -FeatureName VirtualMachinePlatform -Online -ErrorAction SilentlyContinue
        
        # Check if virtualization is enabled in BIOS
        $virtualizationEnabled = $false
        try {
            $processor = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
            $virtualizationEnabled = $processor.VirtualizationFirmwareEnabled
        }
        catch {
            # Fallback check
            $virtualizationEnabled = $true  # Assume enabled if we can't detect
        }
        
        return @{
            Passed = $virtualizationEnabled
            HyperVAvailable = $hyperVFeature -ne $null
            VMPlatformAvailable = $vmPlatform -ne $null
            VirtualizationEnabled = $virtualizationEnabled
            Message = if ($virtualizationEnabled) { "Virtualization support available" } else { "Virtualization must be enabled in BIOS" }
        }
    }
    catch {
        return @{
            Passed = $false
            Message = "Could not check virtualization support: $($_.Exception.Message)"
        }
    }
}

function Test-AntivirusInterference {
    try {
        # Check Windows Defender status
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        
        # Check for other antivirus products
        $antivirusProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct -ErrorAction SilentlyContinue
        
        return @{
            Passed = $true  # We don't fail on antivirus, just warn
            WindowsDefender = if ($defenderStatus) { 
                @{
                    Enabled = $defenderStatus.AntivirusEnabled
                    RealTimeProtection = $defenderStatus.RealTimeProtectionEnabled
                }
            } else { $null }
            AntivirusProducts = if ($antivirusProducts) {
                $antivirusProducts | ForEach-Object {
                    @{
                        Name = $_.displayName
                        State = $_.productState
                    }
                }
            } else { @() }
            Message = "Antivirus status checked - may require exclusions during installation"
        }
    }
    catch {
        return @{
            Passed = $true
            Message = "Could not check antivirus status: $($_.Exception.Message)"
        }
    }
}

#endregion

#region WSL2 Management Functions

function Test-WSL2Installation {
    <#
    .SYNOPSIS
    Checks if WSL2 is installed and configured properly
    #>
    
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
        $versionMatch = $wslVersionOutput | Where-Object { $_ -match "WSL version: ([\d\.]+)" }
        $version = if ($versionMatch) { $matches[1] } else { "Unknown" }
        
        # Get default version
        $defaultVersion = & wsl --list --verbose 2>$null | Where-Object { $_ -match "Default Version: (\d+)" }
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
            if ($line -match '^\s*\*?\s*([^\s]+)\s+(\w+)\s+(\d+)') {
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
        Write-Log "Error getting WSL distributions: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Install-WSL2 {
    <#
    .SYNOPSIS
    Installs and configures WSL2 with comprehensive error handling and reboot management
    #>
    
    param(
        [switch]$SkipIfExists,
        [switch]$AutoReboot,
        [string]$ContinuationPhase = "PostWSLReboot"
    )
    
    Write-Log "Starting WSL2 installation" -Level Info
    Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Checking current status" -PercentComplete 5
    
    # Pre-installation validation
    $systemCheck = Test-WSL2Prerequisites
    if (-not $systemCheck.Passed) {
        throw "System prerequisites not met: $($systemCheck.Message)"
    }
    
    # Check if already installed
    $wslStatus = Test-WSL2Installation
    if ($wslStatus.Installed -and $SkipIfExists) {
        Write-Log "WSL2 already installed, skipping" -Level Success
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
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Checking WSL feature status" -PercentComplete 15
        $wslFeatureStatus = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        
        if ($wslFeatureStatus.State -ne "Enabled") {
            Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Enabling Windows Subsystem for Linux" -PercentComplete 25
            Write-Log "Enabling WSL feature..." -Level Info
            
            $wslFeature = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
            $installationSteps += "WSL Feature Enabled"
            
            if ($wslFeature.RestartNeeded) {
                $rebootRequired = $true
                Write-Log "WSL feature enabled - reboot required" -Level Warning
            }
        } else {
            Write-Log "WSL feature already enabled" -Level Info
        }
        
        # Step 2: Check and enable Virtual Machine Platform
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Checking Virtual Machine Platform" -PercentComplete 35
        $vmFeatureStatus = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
        
        if ($vmFeatureStatus.State -ne "Enabled") {
            Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Enabling Virtual Machine Platform" -PercentComplete 45
            Write-Log "Enabling Virtual Machine Platform..." -Level Info
            
            $vmFeature = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
            $installationSteps += "Virtual Machine Platform Enabled"
            
            if ($vmFeature.RestartNeeded) {
                $rebootRequired = $true
                Write-Log "Virtual Machine Platform enabled - reboot required" -Level Warning
            }
        } else {
            Write-Log "Virtual Machine Platform already enabled" -Level Info
        }
        
        # Step 3: Handle reboot if required for features
        if ($rebootRequired) {
            Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Features enabled - reboot required" -PercentComplete 50
            Write-Log "WSL2 features enabled successfully. Reboot required to continue." -Level Info
            
            if ($AutoReboot) {
                return Request-RebootWithContinuation -ContinuationPhase $ContinuationPhase -InstallationSteps $installationSteps
            } else {
                return @{
                    Success = $true
                    RebootRequired = $true
                    RebootReason = "WSL2 features enabled"
                    InstallationSteps = $installationSteps
                    Message = "WSL2 features enabled. Please reboot and run installer again."
                    NextPhase = $ContinuationPhase
                }
            }
        }
        
        # Step 4: Download and install WSL2 kernel (only if no reboot needed)
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Installing WSL2 kernel update" -PercentComplete 65
        $kernelResult = Install-WSL2Kernel
        if (-not $kernelResult.Success) {
            throw "WSL2 kernel installation failed: $($kernelResult.Error)"
        }
        $installationSteps += "WSL2 Kernel Installed"
        
        # Step 5: Set WSL2 as default version
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Setting WSL2 as default version" -PercentComplete 80
        Write-Log "Setting WSL2 as default version..." -Level Info
        
        $setDefaultResult = & wsl --set-default-version 2 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "WSL2 set as default version" -Level Success
            $installationSteps += "WSL2 Set as Default"
        } else {
            Write-Log "Warning: Could not set WSL2 as default version: $setDefaultResult" -Level Warning
        }
        
        # Step 6: Final validation
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Validating installation" -PercentComplete 90
        Start-Sleep -Seconds 2  # Allow services to initialize
        
        $finalStatus = Test-WSL2Installation
        if (-not $finalStatus.Installed) {
            throw "WSL2 installation validation failed"
        }
        
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "WSL2 installation completed successfully" -PercentComplete 100
        Write-Log "WSL2 installation completed successfully" -Level Success
        
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
        Write-Log "WSL2 installation failed: $($_.Exception.Message)" -Level Error
        
        # Attempt rollback of any partial installation
        if ($installationSteps.Count -gt 0) {
            Write-Log "Attempting to rollback partial installation..." -Level Warning
            # Note: Rolling back Windows features is complex and may require reboot
            # We'll log the issue for manual intervention
            Write-Log "Manual intervention may be required. Steps completed: $($installationSteps -join ', ')" -Level Warning
        }
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            InstallationSteps = $installationSteps
            Message = "WSL2 installation failed: $($_.Exception.Message)"
        }
    }
}

function Test-WSL2Prerequisites {
    <#
    .SYNOPSIS
    Validates system prerequisites for WSL2 installation
    #>
    
    Write-Log "Checking WSL2 prerequisites..." -Level Info
    
    $issues = @()
    
    # Check Windows version
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $buildNumber = [int]$os.BuildNumber
    
    if ($buildNumber -lt 19041) {
        $issues += "Windows build $buildNumber is too old. WSL2 requires build 19041 or newer."
    }
    
    # Check architecture
    if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
        $issues += "WSL2 requires 64-bit Windows (AMD64 architecture)"
    }
    
    # Check Hyper-V support
    $hyperVCheck = Test-HyperVSupport
    if (-not $hyperVCheck.Passed) {
        $issues += $hyperVCheck.Message
    }
    
    # Check admin rights
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        $issues += "Administrator privileges required for WSL2 installation"
    }
    
    # Check disk space
    $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
    
    if ($freeSpaceGB -lt 2) {
        $issues += "Insufficient disk space. At least 2GB required, $freeSpaceGB GB available"
    }
    
    $passed = $issues.Count -eq 0
    $message = if ($passed) { "All WSL2 prerequisites met" } else { $issues -join "; " }
    
    Write-Log "Prerequisites check: $message" -Level $(if ($passed) { "Info" } else { "Warning" })
    
    return @{
        Passed = $passed
        Issues = $issues
        Message = $message
        Details = @{
            WindowsBuild = $buildNumber
            Architecture = $env:PROCESSOR_ARCHITECTURE
            DiskSpaceGB = $freeSpaceGB
            IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        }
    }
}

function Install-WSL2Kernel {
    $kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $kernelPath = "$env:TEMP\wsl_update_x64.msi"
    
    try {
        # Download kernel update
        Write-Log "Downloading WSL2 kernel from $kernelUrl" -Level Info
        Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelPath -UseBasicParsing
        
        # Install kernel update
        Write-Log "Installing WSL2 kernel update" -Level Info
        $installResult = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $kernelPath, "/quiet", "/norestart" -Wait -PassThru
        
        if ($installResult.ExitCode -eq 0) {
            Write-Log "WSL2 kernel installed successfully" -Level Success
            return @{ Success = $true; ExitCode = 0 }
        }
        else {
            Write-Log "WSL2 kernel installation failed with exit code: $($installResult.ExitCode)" -Level Error
            return @{ Success = $false; ExitCode = $installResult.ExitCode }
        }
    }
    catch {
        Write-Log "Error installing WSL2 kernel: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
    finally {
        # Clean up downloaded file
        if (Test-Path $kernelPath) {
            Remove-Item $kernelPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-AlpineLinux {
    <#
    .SYNOPSIS
    Installs and configures Alpine Linux distribution for WSL2 with comprehensive setup
    #>
    
    param(
        [switch]$SetAsDefault,
        [switch]$SkipIfExists,
        [string]$Username = "claude",
        [int]$TimeoutMinutes = 10
    )
    
    Write-Log "Starting Alpine Linux installation and configuration" -Level Info
    Write-Progress-Enhanced -Activity "Installing Alpine Linux" -Status "Checking current distributions" -PercentComplete 5
    
    try {
        # Step 1: Check if Alpine is already installed
        $distributions = Get-WSLDistributions
        $alpineExists = $distributions | Where-Object { $_.Name -like "*Alpine*" }
        
        if ($alpineExists -and $SkipIfExists) {
            Write-Log "Alpine Linux already installed, skipping" -Level Success
            return @{
                Success = $true
                AlreadyInstalled = $true
                DistributionName = $alpineExists.Name
                State = $alpineExists.State
                Message = "Alpine Linux already available and functional"
            }
        }
        
        # Step 2: Validate WSL2 is ready
        Write-Progress-Enhanced -Activity "Installing Alpine Linux" -Status "Validating WSL2 environment" -PercentComplete 10
        $wslStatus = Test-WSL2Installation
        if (-not $wslStatus.Installed) {
            throw "WSL2 must be installed before installing Alpine Linux"
        }
        
        # Step 3: Install Alpine Linux if not exists
        if (-not $alpineExists) {
            Write-Progress-Enhanced -Activity "Installing Alpine Linux" -Status "Downloading Alpine Linux distribution" -PercentComplete 20
            Write-Log "Installing Alpine Linux distribution..." -Level Info
            
            # Use timeout to prevent hanging
            $installJob = Start-Job -ScriptBlock {
                param($TimeoutMinutes)
                & wsl --install -d Alpine 2>&1
                return $LASTEXITCODE
            } -ArgumentList $TimeoutMinutes
            
            # Wait for installation with timeout
            $installResult = $installJob | Wait-Job -Timeout ($TimeoutMinutes * 60)
            
            if (-not $installResult) {
                # Installation timed out
                $installJob | Stop-Job -Force
                $installJob | Remove-Job -Force
                throw "Alpine Linux installation timed out after $TimeoutMinutes minutes"
            }
            
            $exitCode = Receive-Job $installJob
            $installJob | Remove-Job -Force
            
            if ($exitCode -ne 0) {
                throw "Alpine Linux installation failed with exit code: $exitCode"
            }
            
            Write-Log "Alpine Linux distribution installed successfully" -Level Success
        }
        
        # Step 4: Verify installation and get distribution info
        Write-Progress-Enhanced -Activity "Installing Alpine Linux" -Status "Verifying installation" -PercentComplete 50
        Start-Sleep -Seconds 3  # Allow WSL to register the new distribution
        
        $distributions = Get-WSLDistributions
        $alpine = $distributions | Where-Object { $_.Name -like "*Alpine*" }
        
        if (-not $alpine) {
            throw "Alpine Linux installation verification failed - distribution not found"
        }
        
        Write-Log "Alpine Linux verified: $($alpine.Name) - State: $($alpine.State)" -Level Info
        
        # Step 5: Start Alpine if not running
        if ($alpine.State -ne "Running") {
            Write-Progress-Enhanced -Activity "Installing Alpine Linux" -Status "Starting Alpine Linux" -PercentComplete 60
            Write-Log "Starting Alpine Linux distribution..." -Level Info
            
            & wsl -d $alpine.Name --exec echo "Starting Alpine..." 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Warning: Could not start Alpine Linux automatically" -Level Warning
            } else {
                Write-Log "Alpine Linux started successfully" -Level Success
            }
        }
        
        # Step 6: Basic Alpine configuration
        Write-Progress-Enhanced -Activity "Installing Alpine Linux" -Status "Configuring Alpine Linux" -PercentComplete 70
        $configResult = Initialize-AlpineConfiguration -DistributionName $alpine.Name -Username $Username
        
        if (-not $configResult.Success) {
            Write-Log "Warning: Alpine configuration incomplete: $($configResult.Error)" -Level Warning
        }
        
        # Step 7: Set as default if requested
        if ($SetAsDefault) {
            Write-Progress-Enhanced -Activity "Installing Alpine Linux" -Status "Setting as default distribution" -PercentComplete 85
            Write-Log "Setting Alpine Linux as default WSL distribution..." -Level Info
            
            & wsl --set-default $alpine.Name 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Alpine Linux set as default distribution" -Level Success
            } else {
                Write-Log "Warning: Could not set Alpine as default distribution" -Level Warning
            }
        }
        
        # Step 8: Final validation
        Write-Progress-Enhanced -Activity "Installing Alpine Linux" -Status "Final validation" -PercentComplete 95
        $finalValidation = Test-AlpineInstallation -DistributionName $alpine.Name
        
        Write-Progress-Enhanced -Activity "Installing Alpine Linux" -Status "Alpine Linux ready" -PercentComplete 100
        Write-Log "Alpine Linux installation and configuration completed successfully" -Level Success
        
        return @{
            Success = $true
            AlreadyInstalled = $alpineExists -ne $null
            DistributionName = $alpine.Name
            State = $alpine.State
            IsDefault = $SetAsDefault
            Configuration = $configResult
            Validation = $finalValidation
            Message = "Alpine Linux installed and configured successfully"
        }
        
    }
    catch {
        Write-Log "Alpine Linux installation failed: $($_.Exception.Message)" -Level Error
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            Message = "Alpine Linux installation failed: $($_.Exception.Message)"
        }
    }
}

function Initialize-AlpineConfiguration {
    <#
    .SYNOPSIS
    Performs basic Alpine Linux configuration for Claude Code development
    #>
    
    param(
        [Parameter(Mandatory)]
        [string]$DistributionName,
        [string]$Username = "claude"
    )
    
    Write-Log "Configuring Alpine Linux for Claude Code development..." -Level Info
    
    try {
        # Test basic connectivity
        $testResult = & wsl -d $DistributionName --exec echo "Alpine Ready" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot communicate with Alpine Linux: $testResult"
        }
        
        # Get Alpine version
        $alpineVersion = & wsl -d $DistributionName --exec cat /etc/alpine-release 2>$null
        Write-Log "Alpine Linux version: $alpineVersion" -Level Info
        
        # Check if root setup is needed
        $rootCheck = & wsl -d $DistributionName --exec whoami 2>$null
        Write-Log "Current Alpine user: $rootCheck" -Level Info
        
        # Create setup script for Alpine
        $setupScript = @"
#!/bin/sh
# Alpine Linux setup for Claude Code installer
echo "=== Alpine Linux Configuration ==="

# Update package repository
echo "Updating package repository..."
apk update 2>/dev/null || echo "Warning: Could not update package repository"

# Install essential packages
echo "Installing essential packages..."
apk add --no-cache curl wget git nodejs npm 2>/dev/null || echo "Warning: Some packages may not be available"

# Create user if specified and not root
if [ "$1" != "root" ] && [ ! -z "$1" ]; then
    if ! id "$1" >/dev/null 2>&1; then
        echo "Creating user: $1"
        adduser -D -s /bin/sh "$1"
        echo "User $1 created successfully"
    else
        echo "User $1 already exists"
    fi
fi

# Verify essential tools
echo "=== Verification ==="
echo "curl: \$(curl --version 2>/dev/null | head -1 || echo 'Not available')"
echo "git: \$(git --version 2>/dev/null || echo 'Not available')"  
echo "node: \$(node --version 2>/dev/null || echo 'Not available')"
echo "npm: \$(npm --version 2>/dev/null || echo 'Not available')"

echo "Alpine Linux configuration completed"
"@
        
        $setupScriptPath = "$env:TEMP\alpine-setup.sh"
        $setupScript | Out-File -FilePath $setupScriptPath -Encoding UTF8
        
        # Copy setup script to Alpine and execute
        & wsl -d $DistributionName --exec sh -c "cat > /tmp/setup.sh" < $setupScriptPath
        $setupOutput = & wsl -d $DistributionName --exec sh /tmp/setup.sh $Username 2>&1
        
        # Clean up
        Remove-Item $setupScriptPath -Force -ErrorAction SilentlyContinue
        & wsl -d $DistributionName --exec rm -f /tmp/setup.sh 2>$null
        
        Write-Log "Alpine configuration output: $setupOutput" -Level Info
        
        return @{
            Success = $true
            AlpineVersion = $alpineVersion.Trim()
            CurrentUser = $rootCheck.Trim()
            SetupOutput = $setupOutput
            Message = "Alpine Linux configured successfully"
        }
        
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Message = "Alpine configuration failed: $($_.Exception.Message)"
        }
    }
}

function Test-AlpineInstallation {
    <#
    .SYNOPSIS
    Validates Alpine Linux installation and readiness for Claude Code
    #>
    
    param(
        [Parameter(Mandatory)]
        [string]$DistributionName
    )
    
    Write-Log "Validating Alpine Linux installation..." -Level Info
    
    try {
        $validation = @{
            Connectivity = $false
            EssentialTools = @{}
            UserAccess = $false
            FileSystem = $false
        }
        
        # Test basic connectivity
        $echoTest = & wsl -d $DistributionName --exec echo "test" 2>$null
        $validation.Connectivity = ($LASTEXITCODE -eq 0 -and $echoTest -eq "test")
        
        # Test essential tools
        $tools = @("curl", "git", "node", "npm")
        foreach ($tool in $tools) {
            $toolCheck = & wsl -d $DistributionName --exec which $tool 2>$null
            $validation.EssentialTools[$tool] = ($LASTEXITCODE -eq 0 -and $toolCheck)
        }
        
        # Test user access
        $userTest = & wsl -d $DistributionName --exec whoami 2>$null
        $validation.UserAccess = ($LASTEXITCODE -eq 0 -and $userTest)
        
        # Test file system access
        $fsTest = & wsl -d $DistributionName --exec "touch /tmp/test && rm /tmp/test" 2>$null
        $validation.FileSystem = ($LASTEXITCODE -eq 0)
        
        $allPassed = $validation.Connectivity -and $validation.UserAccess -and $validation.FileSystem
        
        Write-Log "Alpine validation completed. All checks passed: $allPassed" -Level $(if ($allPassed) { "Success" } else { "Warning" })
        
        return @{
            Success = $allPassed
            Details = $validation
            Message = if ($allPassed) { "Alpine Linux is ready for Claude Code" } else { "Alpine Linux has some issues but is functional" }
        }
        
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Message = "Alpine validation failed: $($_.Exception.Message)"
        }
    }
}

#endregion

#region Utility Functions

function Test-RebootRequired {
    <#
    .SYNOPSIS
    Checks if a reboot is required
    #>
    
    $rebootRequired = $false
    
    # Check registry keys that indicate pending reboot
    $rebootKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations"
    )
    
    foreach ($key in $rebootKeys) {
        if (Test-Path $key) {
            $rebootRequired = $true
            break
        }
    }
    
    return $rebootRequired
}

function Request-RebootWithContinuation {
    <#
    .SYNOPSIS
    Schedules installer continuation after reboot with state preservation
    #>
    
    param(
        [string]$InstallerPath,
        [string]$ContinuationPhase = "PostReboot",
        [array]$InstallationSteps = @()
    )
    
    Write-Log "Scheduling installer continuation after reboot" -Level Info
    
    # Save installation state
    $stateFile = "$env:TEMP\ClaudeCodeInstaller-State.json"
    $installationState = @{
        Phase = $ContinuationPhase
        CompletedSteps = $InstallationSteps
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        RebootReason = "WSL2 features installation"
        NextActions = @("Complete WSL2 kernel installation", "Install Alpine Linux", "Configure Claude Code")
    }
    
    try {
        $installationState | ConvertTo-Json -Depth 3 | Out-File -FilePath $stateFile -Encoding UTF8
        Write-Log "Installation state saved to $stateFile" -Level Info
    }
    catch {
        Write-Log "Warning: Could not save installation state: $($_.Exception.Message)" -Level Warning
    }
    
    # Create enhanced continuation script
    $continuationScript = @"
# Claude Code Installer - Post-Reboot Continuation
# Auto-generated on $(Get-Date)

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Claude Code Installer - Resuming Installation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Load installation state
    if (Test-Path "$stateFile") {
        `$state = Get-Content "$stateFile" -Raw | ConvertFrom-Json
        Write-Host "Resuming from phase: `$(`$state.Phase)" -ForegroundColor Green
        Write-Host "Completed steps: `$(`$state.CompletedSteps -join ', ')" -ForegroundColor Green
        Write-Host ""
    }
    
    # Launch installer with continuation phase
    Write-Host "Launching installer continuation..." -ForegroundColor Yellow
    Start-Process -FilePath "$InstallerPath" -ArgumentList "/PHASE=$ContinuationPhase", "/SILENT" -Wait
    
    Write-Host "Installation continuation completed." -ForegroundColor Green
}
catch {
    Write-Host "Error during installation continuation: `$(`$_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please run the installer manually." -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

# Clean up scheduled task
try {
    Unregister-ScheduledTask -TaskName "ClaudeCodeInstaller-PostReboot" -Confirm:`$false -ErrorAction SilentlyContinue
}
catch {
    # Task cleanup failed, but continue
}
"@
    
    $continuationPath = "$env:TEMP\ClaudeCodeInstaller-PostReboot.ps1"
    $continuationScript | Out-File -FilePath $continuationPath -Encoding UTF8
    
    # Schedule task to run after reboot with enhanced configuration
    $taskName = "ClaudeCodeInstaller-PostReboot"
    
    try {
        # Remove existing task if it exists
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        
        # Create new scheduled task
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Normal -File `"$continuationPath`""
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        
        Write-Log "Post-reboot continuation scheduled successfully" -Level Success
        
        return @{
            Success = $true
            RebootRequired = $true
            RebootReason = "WSL2 features enabled - restart required"
            ContinuationScheduled = $true
            StateFile = $stateFile
            ContinuationScript = $continuationPath
            Message = "System will restart and automatically continue installation. Reboot now?"
        }
        
    }
    catch {
        Write-Log "Error scheduling post-reboot continuation: $($_.Exception.Message)" -Level Error
        
        return @{
            Success = $false
            RebootRequired = $true
            RebootReason = "WSL2 features enabled - restart required"
            ContinuationScheduled = $false
            Error = $_.Exception.Message
            Message = "Reboot required, but automatic continuation could not be scheduled. Please run installer manually after reboot."
        }
}

function Get-InstallationState {
    <#
    .SYNOPSIS
    Loads saved installation state after reboot
    #>
    
    $stateFile = "$env:TEMP\ClaudeCodeInstaller-State.json"
    
    if (Test-Path $stateFile) {
        try {
            $state = Get-Content $stateFile -Raw | ConvertFrom-Json
            Write-Log "Installation state loaded: Phase $($state.Phase), Steps: $($state.CompletedSteps -join ', ')" -Level Info
            return $state
        }
        catch {
            Write-Log "Warning: Could not load installation state: $($_.Exception.Message)" -Level Warning
            return $null
        }
    }
    else {
        Write-Log "No installation state file found" -Level Info
        return $null
    }
}

function Clear-InstallationState {
    <#
    .SYNOPSIS
    Cleans up installation state files and scheduled tasks
    #>
    
    $stateFile = "$env:TEMP\ClaudeCodeInstaller-State.json"
    $continuationScript = "$env:TEMP\ClaudeCodeInstaller-PostReboot.ps1"
    $taskName = "ClaudeCodeInstaller-PostReboot"
    
    # Remove state file
    if (Test-Path $stateFile) {
        try {
            Remove-Item $stateFile -Force
            Write-Log "Installation state file cleaned up" -Level Info
        }
        catch {
            Write-Log "Warning: Could not remove state file: $($_.Exception.Message)" -Level Warning
        }
    }
    
    # Remove continuation script
    if (Test-Path $continuationScript) {
        try {
            Remove-Item $continuationScript -Force
            Write-Log "Continuation script cleaned up" -Level Info
        }
        catch {
            Write-Log "Warning: Could not remove continuation script: $($_.Exception.Message)" -Level Warning
        }
    }
    
    # Remove scheduled task
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Log "Scheduled task cleaned up" -Level Info
    }
    catch {
        Write-Log "Warning: Could not remove scheduled task: $($_.Exception.Message)" -Level Warning
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Write-Log',
    'Write-Progress-Enhanced',
    'Test-SystemRequirements',
    'Test-WSL2Installation',
    'Install-WSL2',
    'Install-AlpineLinux',
    'Test-RebootRequired',
    'Request-RebootWithContinuation'
)