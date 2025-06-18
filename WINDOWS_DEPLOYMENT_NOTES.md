# Windows Deployment Differences

## Current Development vs Windows Runtime Differences

### Overview
Our WSL2 automation was developed on Linux/NixOS for cross-platform compatibility, but the actual execution will happen on Windows machines. This document outlines what changes when we deploy to real Windows environments.

## 1. PowerShell Execution Environment

### Development (Linux + PowerShell Core):
```bash
# We test with PowerShell Core on Linux
pwsh --version  # PowerShell 7.5.1
```

### Windows Runtime:
```powershell
# Will use Windows PowerShell 5.1 OR PowerShell Core 7.x
$PSVersionTable.PSVersion  # Could be 5.1 or 7.x

# Key differences:
# - Error handling behavior slightly different
# - Some cmdlets have different parameters
# - Execution policy enforcement varies
# - Module loading paths differ
```

**Impact**: Our code is compatible with both, but we should test execution policies and module loading.

## 2. WSL2 Command Availability

### Development (Mock Testing):
```javascript
// We mock WSL commands in tests
mockExec.mockImplementation((cmd, options, callback) => {
  if (cmd.includes('wsl --status')) {
    callback(null, { stdout: 'WSL version: 2.0.9.0' }, '');
  }
});
```

### Windows Runtime:
```powershell
# Real WSL commands will execute
wsl --status          # Actually checks WSL status
wsl --version         # Returns real version info
wsl --list --verbose  # Shows actual distributions

# Possible outcomes:
# - Command not found (WSL not installed)
# - Access denied (insufficient privileges)
# - Real version/distribution data
# - Various error states we haven't mocked
```

**Impact**: Real WSL behavior may include edge cases we haven't tested.

## 3. Windows Feature Management

### Development (Simulated):
```powershell
# We assume these work in development
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
```

### Windows Runtime:
```powershell
# Real Windows feature operations
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
# Returns: Enabled, Disabled, or EnablePending

Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
# May return: RestartNeeded = $true

# Real considerations:
# - Group Policy restrictions in corporate environments
# - BIOS/UEFI virtualization settings
# - Windows edition limitations (Home vs Pro vs Enterprise)
# - Conflicting software (VirtualBox, VMware, etc.)
```

**Impact**: Corporate environments may block feature installation.

## 4. Registry and System Access

### Development (Limited):
```bash
# We can't test Windows registry on Linux
# Registry paths are mocked or assumed
```

### Windows Runtime:
```powershell
# Real registry access
Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"

# Real system info
Get-CimInstance -ClassName Win32_OperatingSystem
Get-WmiObject -Class Win32_LogicalDisk

# Considerations:
# - Registry virtualization on older Windows
# - UAC prompts for registry modification
# - Antivirus interference with registry access
# - Corporate security software blocking WMI queries
```

**Impact**: System queries will return real data with potential security restrictions.

## 5. Network and Download Operations

### Development (Assumed Working):
```powershell
# We assume downloads work
Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelPath -UseBasicParsing
```

### Windows Runtime:
```powershell
# Real network conditions
Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"

# Real challenges:
# - Corporate proxy servers requiring authentication
# - Firewall blocking Microsoft URLs
# - TLS/SSL certificate validation issues
# - Slow or interrupted downloads
# - Antivirus scanning downloaded files
# - Windows Defender SmartScreen blocking executables
```

**Impact**: Network operations may fail in corporate environments.

## 6. File System and Permissions

### Development (Full Control):
```bash
# We have full control over temp directories
echo "test" > /tmp/test.txt
```

### Windows Runtime:
```powershell
# Real Windows file system restrictions
$env:TEMP\ClaudeCodeInstaller-State.json
$env:TEMP\wsl_update_x64.msi

# Considerations:
# - Temp directory cleanup policies
# - Antivirus real-time scanning delays
# - File locking by other processes
# - NTFS permissions on system directories
# - UAC virtualization of file operations
```

**Impact**: File operations may be slower or fail due to security software.

## 7. Scheduled Task Management

### Development (Untested):
```powershell
# We create scheduled tasks but can't test execution
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger
```

### Windows Runtime:
```powershell
# Real scheduled task behavior
Register-ScheduledTask -TaskName "ClaudeCodeInstaller-PostReboot"

# Real considerations:
# - Group Policy restrictions on scheduled tasks
# - Task Scheduler service status
# - User account limitations (standard vs admin)
# - Task execution context differences
# - Cleanup when tasks fail to run
```

**Impact**: Scheduled tasks may fail to create or execute in restricted environments.

## 8. Reboot and Continuation Handling

### Development (Simulated):
```powershell
# We simulate reboot scenarios
$rebootRequired = $true
```

### Windows Runtime:
```powershell
# Real reboot scenarios
Restart-Computer -Force

# Real challenges:
# - Fast Startup interfering with true reboots
# - BitLocker requiring user interaction
# - Automatic login disabled in corporate environments
# - Multiple reboots required for some features
# - User canceling or delaying reboots
# - Power management policies
```

**Impact**: Reboot continuation may fail if user doesn't log back in automatically.

## 9. Error Messages and User Experience

### Development (Controlled):
```javascript
// We control all error scenarios in tests
const error = new Error('Command not found');
```

### Windows Runtime:
```powershell
# Real Windows error messages (often cryptic)
"The specified module 'VirtualMachinePlatform' could not be loaded because of configuration error 0x80004005"
"Access is denied" (many possible causes)
"The system cannot find the file specified" (path issues)

# Localization considerations:
# - Error messages in different languages
# - Date/time formats varying by locale
# - Registry keys that vary by Windows language
```

**Impact**: Error handling must account for localized and unexpected error messages.

## 10. Testing Strategy for Windows Deployment

### Required Testing Environments:

1. **Clean Windows 10/11 Installations**
   - Home, Pro, Enterprise editions
   - Various build numbers (19041+)
   - Different hardware configurations

2. **Corporate Environments**
   - Domain-joined machines
   - Group Policy restrictions
   - Proxy servers and firewalls
   - Antivirus software variations

3. **Edge Cases**
   - Machines with existing WSL1 installations
   - Systems with conflicting virtualization software
   - Low disk space scenarios
   - Slow network connections

### Validation Checklist:

- [ ] WSL2 installation on fresh Windows systems
- [ ] Behavior with existing WSL installations
- [ ] Corporate proxy and firewall compatibility
- [ ] Multiple antivirus software compatibility
- [ ] Reboot continuation across different Windows configurations
- [ ] Error handling with real Windows error messages
- [ ] Performance on various hardware configurations

## 11. Deployment Modifications Needed

### Code Changes Required:

1. **Enhanced Error Detection**:
```powershell
# Add more specific Windows error code handling
function Get-WindowsErrorDetails {
    param([int]$ErrorCode)
    
    # Map common Windows error codes to user-friendly messages
    switch ($ErrorCode) {
        0x80004005 { "Access denied or configuration error" }
        0x800f0950 { "Windows feature installation failed" }
        # Add more Windows-specific error codes
    }
}
```

2. **Corporate Environment Detection**:
```powershell
function Test-CorporateEnvironment {
    # Detect domain membership, proxy settings, group policies
    $isDomainJoined = (Get-CimInstance -Class Win32_ComputerSystem).PartOfDomain
    $proxySettings = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    
    return @{
        IsDomainJoined = $isDomainJoined
        HasProxy = $proxySettings.ProxyEnable -eq 1
        ProxyServer = $proxySettings.ProxyServer
    }
}
```

3. **Enhanced Network Handling**:
```powershell
function Invoke-WebRequestWithRetry {
    param([string]$Uri, [string]$OutFile, [int]$MaxRetries = 3)
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            # Handle proxy, TLS, and corporate firewall issues
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -Proxy:$ProxyServer
            return
        }
        catch {
            if ($i -eq $MaxRetries) { throw }
            Start-Sleep -Seconds (5 * $i)  # Exponential backoff
        }
    }
}
```

## Summary

While our cross-platform development approach is solid, Windows deployment will require:

1. **Enhanced error handling** for real Windows scenarios
2. **Corporate environment compatibility** features  
3. **More robust network operations** with proxy support
4. **Comprehensive testing** on actual Windows systems
5. **Better user communication** for Windows-specific issues

The core architecture remains sound, but we need Windows-specific refinements for production deployment.