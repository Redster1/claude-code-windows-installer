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
    Installs and configures WSL2
    #>
    
    param(
        [switch]$SkipIfExists
    )
    
    Write-Log "Starting WSL2 installation" -Level Info
    Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Checking current status" -PercentComplete 10
    
    # Check if already installed
    $wslStatus = Test-WSL2Installation
    if ($wslStatus.Installed -and $SkipIfExists) {
        Write-Log "WSL2 already installed, skipping" -Level Success
        return $wslStatus
    }
    
    try {
        # Step 1: Enable WSL feature
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Enabling Windows Subsystem for Linux" -PercentComplete 20
        $wslFeature = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        
        # Step 2: Enable Virtual Machine Platform
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Enabling Virtual Machine Platform" -PercentComplete 40
        $vmFeature = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
        
        # Step 3: Download and install WSL2 kernel
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Downloading WSL2 kernel update" -PercentComplete 60
        $kernelResult = Install-WSL2Kernel
        
        # Step 4: Set WSL2 as default
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "Setting WSL2 as default version" -PercentComplete 80
        & wsl --set-default-version 2
        
        # Check if reboot is required
        $rebootRequired = $wslFeature.RestartNeeded -or $vmFeature.RestartNeeded
        
        Write-Progress-Enhanced -Activity "Installing WSL2" -Status "WSL2 installation completed" -PercentComplete 100
        Write-Log "WSL2 installation completed successfully" -Level Success
        
        return @{
            Success = $true
            RebootRequired = $rebootRequired
            KernelInstalled = $kernelResult.Success
            Message = if ($rebootRequired) { "WSL2 installed successfully. Reboot required." } else { "WSL2 installed successfully." }
        }
    }
    catch {
        Write-Log "WSL2 installation failed: $($_.Exception.Message)" -Level Error
        throw
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
    Installs Alpine Linux distribution for WSL2
    #>
    
    param(
        [switch]$SetAsDefault
    )
    
    Write-Log "Installing Alpine Linux distribution" -Level Info
    
    try {
        # Check if Alpine is already installed
        $distributions = Get-WSLDistributions
        $alpineExists = $distributions | Where-Object { $_.Name -like "*Alpine*" }
        
        if ($alpineExists) {
            Write-Log "Alpine Linux already installed" -Level Success
            return @{
                Success = $true
                AlreadyInstalled = $true
                Message = "Alpine Linux already available"
            }
        }
        
        # Install Alpine Linux
        Write-Progress-Enhanced -Activity "Installing Alpine Linux" -Status "Downloading and installing Alpine" -PercentComplete 50
        & wsl --install -d Alpine
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Alpine Linux installed successfully" -Level Success
            
            # Set as default if requested
            if ($SetAsDefault) {
                & wsl --set-default Alpine
                Write-Log "Alpine Linux set as default distribution" -Level Info
            }
            
            return @{
                Success = $true
                AlreadyInstalled = $false
                Message = "Alpine Linux installed successfully"
            }
        }
        else {
            throw "Alpine Linux installation failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-Log "Error installing Alpine Linux: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Error = $_.Exception.Message
            Message = "Alpine Linux installation failed"
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
    Schedules installer continuation after reboot
    #>
    
    param(
        [string]$InstallerPath,
        [string]$ContinuationPhase = "PostReboot"
    )
    
    Write-Log "Scheduling installer continuation after reboot" -Level Info
    
    # Create continuation script
    $continuationScript = @"
# Claude Code Installer - Post-Reboot Continuation
Write-Host "Resuming Claude Code installation after reboot..."
Start-Process -FilePath "$InstallerPath" -ArgumentList "/PHASE=$ContinuationPhase" -Wait
"@
    
    $continuationPath = "$env:TEMP\ClaudeCodeInstaller-PostReboot.ps1"
    $continuationScript | Out-File -FilePath $continuationPath -Encoding UTF8
    
    # Schedule task to run after reboot
    $taskName = "ClaudeCodeInstaller-PostReboot"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$continuationPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force
    
    Write-Log "Post-reboot continuation scheduled" -Level Success
    
    # Prompt user for reboot
    $rebootChoice = Read-Host "A reboot is required to continue installation. Reboot now? (Y/N)"
    if ($rebootChoice -eq 'Y' -or $rebootChoice -eq 'y') {
        Write-Log "Initiating system reboot" -Level Info
        Restart-Computer -Force
    }
    else {
        Write-Log "Reboot postponed. Installation will continue after manual reboot." -Level Warning
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