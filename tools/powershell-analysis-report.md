# PowerShell Module Analysis Report
Generated: 06/19/2025 22:44:54

## Summary
- Total modules analyzed: 3
- Total violations found: 450
- Modules with violations: 3

## Restricted Characters
The following characters cause "imported command names" errors in NSIS:
#, (, ), {, }, [, ], &, *, ?, ;, ", |, <, >,  , 	

## Detailed Analysis

### ClaudeCodeInstaller.psm1
- Function Names: 23
- Parameter Names: 3
- Variable Names: 108
- Exported Functions: 10
- Violations: 363
#### Violations:
- **String Literal**: '[$timestamp] [$Level] $Message' contains '['
- **String Literal**: '[$timestamp] [$Level] $Message' contains ']'
- **String Literal**: '[$timestamp] [$Level] $Message' contains ' '
- **String Literal**: 'INFO: $Message' contains ' '
- **String Literal**: 'WARNING: $Message' contains ' '
- **String Literal**: 'ERROR: $Message' contains ' '
- **String Literal**: 'SUCCESS: $Message' contains ' '
- **String Literal**: 'Failed to write to log file: $($_.Exception.Message)' contains '('
- **String Literal**: 'Failed to write to log file: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Failed to write to log file: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Progress: $Activity - $Status ($PercentComplete%)' contains '('
- **String Literal**: 'Progress: $Activity - $Status ($PercentComplete%)' contains ')'
- **String Literal**: 'Progress: $Activity - $Status ($PercentComplete%)' contains ' '
- **String Literal**: 'Starting system requirements validation' contains ' '
- **String Literal**: 'All system requirements met' contains ' '
- **String Literal**: '$allPassed requirement(s) failed' contains '('
- **String Literal**: '$allPassed requirement(s) failed' contains ')'
- **String Literal**: '$allPassed requirement(s) failed' contains ' '
- **String Literal**: 'System requirements validation completed' contains ' '
- **String Literal**: 'Windows version compatible' contains ' '
- **String Literal**: 'Windows version too old. Requires build $script:MinWindowsBuild or later' contains ' '
- **String Literal**: 'Could not determine Windows version: $($_.Exception.Message)' contains '('
- **String Literal**: 'Could not determine Windows version: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Could not determine Windows version: $($_.Exception.Message)' contains ' '
- **String Literal**: 'x64 architecture confirmed' contains ' '
- **String Literal**: 'x64 architecture required, found: $arch' contains ' '
- **String Literal**: 'Could not find system drive $env:SystemDrive' contains ' '
- **String Literal**: '$freeSpaceGB GB available (sufficient)' contains '('
- **String Literal**: '$freeSpaceGB GB available (sufficient)' contains ')'
- **String Literal**: '$freeSpaceGB GB available (sufficient)' contains ' '
- **String Literal**: 'Insufficient disk space. Need $requiredGB GB, have $freeSpaceGB GB' contains ' '
- **String Literal**: 'Could not check disk space: $($_.Exception.Message)' contains '('
- **String Literal**: 'Could not check disk space: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Could not check disk space: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Administrator privileges confirmed' contains ' '
- **String Literal**: 'Administrator privileges required' contains ' '
- **String Literal**: 'Network connectivity confirmed' contains ' '
- **String Literal**: 'Network connectivity issues detected' contains ' '
- **String Literal**: 'Network connectivity test failed: $($_.Exception.Message)' contains '('
- **String Literal**: 'Network connectivity test failed: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Network connectivity test failed: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Windows optional features not available: $($_.Exception.Message)' contains '('
- **String Literal**: 'Windows optional features not available: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Windows optional features not available: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Virtualization support available' contains ' '
- **String Literal**: 'Virtualization must be enabled in BIOS' contains ' '
- **String Literal**: 'Could not check virtualization support: $($_.Exception.Message)' contains '('
- **String Literal**: 'Could not check virtualization support: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Could not check virtualization support: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Windows Defender module not available: $($_.Exception.Message)' contains '('
- **String Literal**: 'Windows Defender module not available: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Windows Defender module not available: $($_.Exception.Message)' contains ' '
- **String Literal**: 'SecurityCenter2 not available: $($_.Exception.Message)' contains '('
- **String Literal**: 'SecurityCenter2 not available: $($_.Exception.Message)' contains ')'
- **String Literal**: 'SecurityCenter2 not available: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Antivirus status checked - may require exclusions during installation' contains ' '
- **String Literal**: 'Could not check antivirus status: $($_.Exception.Message)' contains '('
- **String Literal**: 'Could not check antivirus status: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Could not check antivirus status: $($_.Exception.Message)' contains ' '
- **String Literal**: 'WSL not installed' contains ' '
- **String Literal**: 'WSL version: ([\d\.]+)' contains '('
- **String Literal**: 'WSL version: ([\d\.]+)' contains ')'
- **String Literal**: 'WSL version: ([\d\.]+)' contains '['
- **String Literal**: 'WSL version: ([\d\.]+)' contains ']'
- **String Literal**: 'WSL version: ([\d\.]+)' contains ' '
- **String Literal**: 'Default Version: (\d+)' contains '('
- **String Literal**: 'Default Version: (\d+)' contains ')'
- **String Literal**: 'Default Version: (\d+)' contains ' '
- **String Literal**: 'WSL2 version $version installed with $($distributions.Count) distribution(s)' contains '('
- **String Literal**: 'WSL2 version $version installed with $($distributions.Count) distribution(s)' contains ')'
- **String Literal**: 'WSL2 version $version installed with $($distributions.Count) distribution(s)' contains ' '
- **String Literal**: 'Error checking WSL2: $($_.Exception.Message)' contains '('
- **String Literal**: 'Error checking WSL2: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Error checking WSL2: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Error getting WSL distributions: $($_.Exception.Message)' contains '('
- **String Literal**: 'Error getting WSL distributions: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Error getting WSL distributions: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Starting WSL2 installation' contains ' '
- **String Literal**: 'Installing WSL2' contains ' '
- **String Literal**: 'Checking current status' contains ' '
- **String Literal**: 'System prerequisites not met: $($systemCheck.Message)' contains '('
- **String Literal**: 'System prerequisites not met: $($systemCheck.Message)' contains ')'
- **String Literal**: 'System prerequisites not met: $($systemCheck.Message)' contains ' '
- **String Literal**: 'WSL2 already installed, skipping' contains ' '
- **String Literal**: 'WSL2 already installed and functional' contains ' '
- **String Literal**: 'Installing WSL2' contains ' '
- **String Literal**: 'Checking WSL feature status' contains ' '
- **String Literal**: 'Installing WSL2' contains ' '
- **String Literal**: 'Enabling Windows Subsystem for Linux' contains ' '
- **String Literal**: 'Enabling WSL feature...' contains ' '
- **String Literal**: 'WSL Feature Enabled' contains ' '
- **String Literal**: 'WSL feature enabled - reboot required' contains ' '
- **String Literal**: 'WSL feature already enabled' contains ' '
- **String Literal**: 'Installing WSL2' contains ' '
- **String Literal**: 'Checking Virtual Machine Platform' contains ' '
- **String Literal**: 'Installing WSL2' contains ' '
- **String Literal**: 'Enabling Virtual Machine Platform' contains ' '
- **String Literal**: 'Enabling Virtual Machine Platform...' contains ' '
- **String Literal**: 'Virtual Machine Platform Enabled' contains ' '
- **String Literal**: 'Virtual Machine Platform enabled - reboot required' contains ' '
- **String Literal**: 'Virtual Machine Platform already enabled' contains ' '
- **String Literal**: 'Installing WSL2' contains ' '
- **String Literal**: 'Features enabled - reboot required' contains ' '
- **String Literal**: 'WSL2 features enabled successfully. Reboot required to continue.' contains ' '
- **String Literal**: 'WSL2 features enabled' contains ' '
- **String Literal**: 'WSL2 features enabled. Please reboot and run installer again.' contains ' '
- **String Literal**: 'Installing WSL2' contains ' '
- **String Literal**: 'Installing WSL2 kernel update' contains ' '
- **String Literal**: 'WSL2 kernel installation failed: $($kernelResult.Error)' contains '('
- **String Literal**: 'WSL2 kernel installation failed: $($kernelResult.Error)' contains ')'
- **String Literal**: 'WSL2 kernel installation failed: $($kernelResult.Error)' contains ' '
- **String Literal**: 'WSL2 Kernel Installed' contains ' '
- **String Literal**: 'Installing WSL2' contains ' '
- **String Literal**: 'Setting WSL2 as default version' contains ' '
- **String Literal**: 'Setting WSL2 as default version...' contains ' '
- **String Literal**: 'WSL2 set as default version' contains ' '
- **String Literal**: 'WSL2 Set as Default' contains ' '
- **String Literal**: 'Warning: Could not set WSL2 as default version: $setDefaultResult' contains ' '
- **String Literal**: 'Installing WSL2' contains ' '
- **String Literal**: 'Validating installation' contains ' '
- **String Literal**: 'WSL2 installation validation failed' contains ' '
- **String Literal**: 'Installing WSL2' contains ' '
- **String Literal**: 'WSL2 installation completed successfully' contains ' '
- **String Literal**: 'WSL2 installation completed successfully' contains ' '
- **String Literal**: 'WSL2 installed and configured successfully' contains ' '
- **String Literal**: 'WSL2 installation failed: $($_.Exception.Message)' contains '('
- **String Literal**: 'WSL2 installation failed: $($_.Exception.Message)' contains ')'
- **String Literal**: 'WSL2 installation failed: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Attempting to rollback partial installation...' contains ' '
- **String Literal**: 'Manual intervention may be required. Steps completed: $($installationSteps -join ', ')' contains '('
- **String Literal**: 'Manual intervention may be required. Steps completed: $($installationSteps -join ', ')' contains ')'
- **String Literal**: 'Manual intervention may be required. Steps completed: $($installationSteps -join ', ')' contains ' '
- **String Literal**: 'WSL2 installation failed: $($_.Exception.Message)' contains '('
- **String Literal**: 'WSL2 installation failed: $($_.Exception.Message)' contains ')'
- **String Literal**: 'WSL2 installation failed: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Checking WSL2 prerequisites...' contains ' '
- **String Literal**: 'Could not determine Windows version: $($_.Exception.Message)' contains '('
- **String Literal**: 'Could not determine Windows version: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Could not determine Windows version: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Windows build $buildNumber is too old. WSL2 requires build 19041 or newer.' contains ' '
- **String Literal**: 'WSL2 requires 64-bit Windows (AMD64 architecture)' contains '('
- **String Literal**: 'WSL2 requires 64-bit Windows (AMD64 architecture)' contains ')'
- **String Literal**: 'WSL2 requires 64-bit Windows (AMD64 architecture)' contains ' '
- **String Literal**: 'Administrator privileges required for WSL2 installation' contains ' '
- **String Literal**: 'Insufficient disk space. At least 2GB required, $freeSpaceGB GB available' contains ' '
- **String Literal**: 'Could not find system drive $env:SystemDrive' contains ' '
- **String Literal**: 'Could not check disk space: $($_.Exception.Message)' contains '('
- **String Literal**: 'Could not check disk space: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Could not check disk space: $($_.Exception.Message)' contains ' '
- **String Literal**: 'All WSL2 prerequisites met' contains ' '
- **String Literal**: '; ' contains ';'
- **String Literal**: '; ' contains ' '
- **String Literal**: 'Prerequisites check: $message' contains ' '
- **String Literal**: 'Downloading WSL2 kernel from $kernelUrl' contains ' '
- **String Literal**: 'Installing WSL2 kernel update' contains ' '
- **String Literal**: 'WSL2 kernel installed successfully' contains ' '
- **String Literal**: 'WSL2 kernel installation failed with exit code: $($installResult.ExitCode)' contains '('
- **String Literal**: 'WSL2 kernel installation failed with exit code: $($installResult.ExitCode)' contains ')'
- **String Literal**: 'WSL2 kernel installation failed with exit code: $($installResult.ExitCode)' contains ' '
- **String Literal**: 'Error installing WSL2 kernel: $($_.Exception.Message)' contains '('
- **String Literal**: 'Error installing WSL2 kernel: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Error installing WSL2 kernel: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Starting Alpine Linux installation and configuration' contains ' '
- **String Literal**: 'Installing Alpine Linux' contains ' '
- **String Literal**: 'Checking current distributions' contains ' '
- **String Literal**: '*Alpine*' contains '*'
- **String Literal**: 'Alpine Linux already installed, skipping' contains ' '
- **String Literal**: 'Alpine Linux already available and functional' contains ' '
- **String Literal**: 'Installing Alpine Linux' contains ' '
- **String Literal**: 'Validating WSL2 environment' contains ' '
- **String Literal**: 'WSL2 must be installed before installing Alpine Linux' contains ' '
- **String Literal**: 'Installing Alpine Linux' contains ' '
- **String Literal**: 'Downloading Alpine Linux distribution' contains ' '
- **String Literal**: 'Installing Alpine Linux distribution...' contains ' '
- **String Literal**: 'Alpine Linux installation timed out after $TimeoutMinutes minutes' contains ' '
- **String Literal**: 'Alpine Linux installation failed with exit code: $exitCode' contains ' '
- **String Literal**: 'Alpine Linux distribution installed successfully' contains ' '
- **String Literal**: 'Installing Alpine Linux' contains ' '
- **String Literal**: 'Verifying installation' contains ' '
- **String Literal**: '*Alpine*' contains '*'
- **String Literal**: 'Alpine Linux installation verification failed - distribution not found' contains ' '
- **String Literal**: 'Alpine Linux verified: $($alpine.Name) - State: $($alpine.State)' contains '('
- **String Literal**: 'Alpine Linux verified: $($alpine.Name) - State: $($alpine.State)' contains ')'
- **String Literal**: 'Alpine Linux verified: $($alpine.Name) - State: $($alpine.State)' contains ' '
- **String Literal**: 'Installing Alpine Linux' contains ' '
- **String Literal**: 'Starting Alpine Linux' contains ' '
- **String Literal**: 'Starting Alpine Linux distribution...' contains ' '
- **String Literal**: 'Starting Alpine...' contains ' '
- **String Literal**: 'Warning: Could not start Alpine Linux automatically' contains ' '
- **String Literal**: 'Alpine Linux started successfully' contains ' '
- **String Literal**: 'Installing Alpine Linux' contains ' '
- **String Literal**: 'Configuring Alpine Linux' contains ' '
- **String Literal**: 'Warning: Alpine configuration incomplete: $($configResult.Error)' contains '('
- **String Literal**: 'Warning: Alpine configuration incomplete: $($configResult.Error)' contains ')'
- **String Literal**: 'Warning: Alpine configuration incomplete: $($configResult.Error)' contains ' '
- **String Literal**: 'Installing Alpine Linux' contains ' '
- **String Literal**: 'Setting as default distribution' contains ' '
- **String Literal**: 'Setting Alpine Linux as default WSL distribution...' contains ' '
- **String Literal**: 'Alpine Linux set as default distribution' contains ' '
- **String Literal**: 'Warning: Could not set Alpine as default distribution' contains ' '
- **String Literal**: 'Installing Alpine Linux' contains ' '
- **String Literal**: 'Final validation' contains ' '
- **String Literal**: 'Installing Alpine Linux' contains ' '
- **String Literal**: 'Alpine Linux ready' contains ' '
- **String Literal**: 'Alpine Linux installation and configuration completed successfully' contains ' '
- **String Literal**: 'Alpine Linux installed and configured successfully' contains ' '
- **String Literal**: 'Alpine Linux installation failed: $($_.Exception.Message)' contains '('
- **String Literal**: 'Alpine Linux installation failed: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Alpine Linux installation failed: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Alpine Linux installation failed: $($_.Exception.Message)' contains '('
- **String Literal**: 'Alpine Linux installation failed: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Alpine Linux installation failed: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Configuring Alpine Linux for Claude Code development...' contains ' '
- **String Literal**: 'Alpine Ready' contains ' '
- **String Literal**: 'Cannot communicate with Alpine Linux: $testResult' contains ' '
- **String Literal**: 'Alpine Linux version: $alpineVersion' contains ' '
- **String Literal**: 'Current Alpine user: $rootCheck' contains ' '
- **String Literal**: 'Updating package repository...' contains ' '
- **String Literal**: 'Installing essential packages...' contains ' '
- **String Literal**: 'Checking/creating user: $Username' contains ' '
- **String Literal**: 'Created user: $Username' contains ' '
- **String Literal**: 'Verifying tool installation...' contains ' '
- **String Literal**: 'Alpine Linux configuration completed.`n' contains ' '
- **String Literal**: 'curl: $(if ($curlVersion) { $curlVersion } else { 'Not available' })`n' contains '('
- **String Literal**: 'curl: $(if ($curlVersion) { $curlVersion } else { 'Not available' })`n' contains ')'
- **String Literal**: 'curl: $(if ($curlVersion) { $curlVersion } else { 'Not available' })`n' contains '{'
- **String Literal**: 'curl: $(if ($curlVersion) { $curlVersion } else { 'Not available' })`n' contains '}'
- **String Literal**: 'curl: $(if ($curlVersion) { $curlVersion } else { 'Not available' })`n' contains ' '
- **String Literal**: 'git: $(if ($gitVersion) { $gitVersion } else { 'Not available' })`n' contains '('
- **String Literal**: 'git: $(if ($gitVersion) { $gitVersion } else { 'Not available' })`n' contains ')'
- **String Literal**: 'git: $(if ($gitVersion) { $gitVersion } else { 'Not available' })`n' contains '{'
- **String Literal**: 'git: $(if ($gitVersion) { $gitVersion } else { 'Not available' })`n' contains '}'
- **String Literal**: 'git: $(if ($gitVersion) { $gitVersion } else { 'Not available' })`n' contains ' '
- **String Literal**: 'node: $(if ($nodeVersion) { $nodeVersion } else { 'Not available' })`n' contains '('
- **String Literal**: 'node: $(if ($nodeVersion) { $nodeVersion } else { 'Not available' })`n' contains ')'
- **String Literal**: 'node: $(if ($nodeVersion) { $nodeVersion } else { 'Not available' })`n' contains '{'
- **String Literal**: 'node: $(if ($nodeVersion) { $nodeVersion } else { 'Not available' })`n' contains '}'
- **String Literal**: 'node: $(if ($nodeVersion) { $nodeVersion } else { 'Not available' })`n' contains ' '
- **String Literal**: 'npm: $(if ($npmVersion) { $npmVersion } else { 'Not available' })`n' contains '('
- **String Literal**: 'npm: $(if ($npmVersion) { $npmVersion } else { 'Not available' })`n' contains ')'
- **String Literal**: 'npm: $(if ($npmVersion) { $npmVersion } else { 'Not available' })`n' contains '{'
- **String Literal**: 'npm: $(if ($npmVersion) { $npmVersion } else { 'Not available' })`n' contains '}'
- **String Literal**: 'npm: $(if ($npmVersion) { $npmVersion } else { 'Not available' })`n' contains ' '
- **String Literal**: 'Alpine configuration output: $setupOutput' contains ' '
- **String Literal**: 'Alpine Linux configured successfully' contains ' '
- **String Literal**: 'Alpine configuration failed: $($_.Exception.Message)' contains '('
- **String Literal**: 'Alpine configuration failed: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Alpine configuration failed: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Validating Alpine Linux installation...' contains ' '
- **String Literal**: 'touch /tmp/test && rm /tmp/test' contains '&'
- **String Literal**: 'touch /tmp/test && rm /tmp/test' contains ' '
- **String Literal**: 'Alpine validation completed. All checks passed: $allPassed' contains ' '
- **String Literal**: 'Alpine Linux is ready for Claude Code' contains ' '
- **String Literal**: 'Alpine Linux has some issues but is functional' contains ' '
- **String Literal**: 'Alpine validation failed: $($_.Exception.Message)' contains '('
- **String Literal**: 'Alpine validation failed: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Alpine validation failed: $($_.Exception.Message)' contains ' '
- **String Literal**: 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' contains ' '
- **String Literal**: 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' contains ' '
- **String Literal**: 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations' contains ' '
- **String Literal**: 'Scheduling installer continuation after reboot' contains ' '
- **String Literal**: 'yyyy-MM-dd HH:mm:ss' contains ' '
- **String Literal**: 'WSL2 features installation' contains ' '
- **String Literal**: 'Complete WSL2 kernel installation' contains ' '
- **String Literal**: 'Install Alpine Linux' contains ' '
- **String Literal**: 'Configure Claude Code' contains ' '
- **String Literal**: 'Installation state saved to $stateFile' contains ' '
- **String Literal**: 'Warning: Could not save installation state: $($_.Exception.Message)' contains '('
- **String Literal**: 'Warning: Could not save installation state: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Warning: Could not save installation state: $($_.Exception.Message)' contains ' '
- **String Literal**: '
# Claude Code Installer - Post-Reboot Continuation
# Auto-generated on $(Get-Date)

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Output ' contains '#'
- **String Literal**: '
# Claude Code Installer - Post-Reboot Continuation
# Auto-generated on $(Get-Date)

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Output ' contains '('
- **String Literal**: '
# Claude Code Installer - Post-Reboot Continuation
# Auto-generated on $(Get-Date)

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Output ' contains ')'
- **String Literal**: '
# Claude Code Installer - Post-Reboot Continuation
# Auto-generated on $(Get-Date)

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Output ' contains ' '
- **String Literal**: '
Write-Output ' contains ' '
- **String Literal**: '
Write-Output ' contains ' '
- **String Literal**: '
Write-Output ' contains ' '
- **String Literal**: '

try {
    # Load installation state
    if (Test-Path ' contains '#'
- **String Literal**: '

try {
    # Load installation state
    if (Test-Path ' contains '('
- **String Literal**: '

try {
    # Load installation state
    if (Test-Path ' contains '{'
- **String Literal**: '

try {
    # Load installation state
    if (Test-Path ' contains ' '
- **String Literal**: ') {
        `$state = Get-Content ' contains ')'
- **String Literal**: ') {
        `$state = Get-Content ' contains '{'
- **String Literal**: ') {
        `$state = Get-Content ' contains ' '
- **String Literal**: ' -Raw | ConvertFrom-Json
        Write-Output ' contains '|'
- **String Literal**: ' -Raw | ConvertFrom-Json
        Write-Output ' contains ' '
- **String Literal**: '
        Write-Output ' contains ' '
- **String Literal**: '
        Write-Output ' contains ' '
- **String Literal**: '
    }
    
    # Launch installer with continuation phase
    Write-Output ' contains '#'
- **String Literal**: '
    }
    
    # Launch installer with continuation phase
    Write-Output ' contains '}'
- **String Literal**: '
    }
    
    # Launch installer with continuation phase
    Write-Output ' contains ' '
- **String Literal**: '
    Start-Process -FilePath ' contains ' '
- **String Literal**: ' -ArgumentList ' contains ' '
- **String Literal**: ', ' contains ' '
- **String Literal**: ' -Wait
    
    Write-Output ' contains ' '
- **String Literal**: '
}
catch {
    Write-Output ' contains '{'
- **String Literal**: '
}
catch {
    Write-Output ' contains '}'
- **String Literal**: '
}
catch {
    Write-Output ' contains ' '
- **String Literal**: '
    Write-Output ' contains ' '
- **String Literal**: '
    Read-Host ' contains ' '
- **String Literal**: '
}

# Clean up scheduled task
try {
    Unregister-ScheduledTask -TaskName ' contains '#'
- **String Literal**: '
}

# Clean up scheduled task
try {
    Unregister-ScheduledTask -TaskName ' contains '{'
- **String Literal**: '
}

# Clean up scheduled task
try {
    Unregister-ScheduledTask -TaskName ' contains '}'
- **String Literal**: '
}

# Clean up scheduled task
try {
    Unregister-ScheduledTask -TaskName ' contains ' '
- **String Literal**: ' -Confirm:`$false -ErrorAction SilentlyContinue
}
catch {
    # Task cleanup failed, but continue
}
' contains '#'
- **String Literal**: ' -Confirm:`$false -ErrorAction SilentlyContinue
}
catch {
    # Task cleanup failed, but continue
}
' contains '{'
- **String Literal**: ' -Confirm:`$false -ErrorAction SilentlyContinue
}
catch {
    # Task cleanup failed, but continue
}
' contains '}'
- **String Literal**: ' -Confirm:`$false -ErrorAction SilentlyContinue
}
catch {
    # Task cleanup failed, but continue
}
' contains ' '
- **String Literal**: '-ExecutionPolicy Bypass -WindowStyle Normal -File `' contains ' '
- **String Literal**: 'Post-reboot continuation scheduled successfully' contains ' '
- **String Literal**: 'WSL2 features enabled - restart required' contains ' '
- **String Literal**: 'System will restart and automatically continue installation. Reboot now?' contains '?'
- **String Literal**: 'System will restart and automatically continue installation. Reboot now?' contains ' '
- **String Literal**: 'Error scheduling post-reboot continuation: $($_.Exception.Message)' contains '('
- **String Literal**: 'Error scheduling post-reboot continuation: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Error scheduling post-reboot continuation: $($_.Exception.Message)' contains ' '
- **String Literal**: 'WSL2 features enabled - restart required' contains ' '
- **String Literal**: 'Reboot required, but automatic continuation could not be scheduled. Please run installer manually after reboot.' contains ' '
- **String Literal**: 'Installation state loaded: Phase $($state.Phase), Steps: $($state.CompletedSteps -join ', ')' contains '('
- **String Literal**: 'Installation state loaded: Phase $($state.Phase), Steps: $($state.CompletedSteps -join ', ')' contains ')'
- **String Literal**: 'Installation state loaded: Phase $($state.Phase), Steps: $($state.CompletedSteps -join ', ')' contains ' '
- **String Literal**: 'Warning: Could not load installation state: $($_.Exception.Message)' contains '('
- **String Literal**: 'Warning: Could not load installation state: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Warning: Could not load installation state: $($_.Exception.Message)' contains ' '
- **String Literal**: 'No installation state file found' contains ' '
- **String Literal**: 'Installation state file cleaned up' contains ' '
- **String Literal**: 'Warning: Could not remove state file: $($_.Exception.Message)' contains '('
- **String Literal**: 'Warning: Could not remove state file: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Warning: Could not remove state file: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Continuation script cleaned up' contains ' '
- **String Literal**: 'Warning: Could not remove continuation script: $($_.Exception.Message)' contains '('
- **String Literal**: 'Warning: Could not remove continuation script: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Warning: Could not remove continuation script: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Scheduled task cleaned up' contains ' '
- **String Literal**: 'Warning: Could not remove scheduled task: $($_.Exception.Message)' contains '('
- **String Literal**: 'Warning: Could not remove scheduled task: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Warning: Could not remove scheduled task: $($_.Exception.Message)' contains ' '
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& wsl' contains 'Command Pattern'
- **Potentially Problematic Command**: '& rm' contains 'Command Pattern'
- **Potentially Problematic Command**: 'Start-Process -FilePath "msiexec.exe" -ArgumentList' contains 'Command Pattern'
- **Potentially Problematic Command**: 'Start-Process -FilePath "$InstallerPath" -ArgumentList' contains 'Command Pattern'

#### Functions:
- Write-Log
- Write-Progress-Enhanced
- Test-SystemRequirements
- Test-WindowsVersion
- Test-Architecture
- Test-DiskSpace
- Test-AdminRights
- Test-NetworkConnectivity
- Test-HyperVSupport
- Test-AntivirusInterference
- Test-WSL2Installation
- Get-WSLDistributions
- Install-WSL2
- Test-WSL2Prerequisites
- Install-WSL2Kernel
- Install-AlpineLinux
- Initialize-AlpineConfiguration
- Test-AlpineInstallation
- Test-RebootRequired
- Request-RebootWithContinuation
- Get-InstallationState
- Clear-InstallationState
- @

#### Exported Functions:
- Write-Log
- Write-Progress-Enhanced
- Test-SystemRequirements
- Test-WSL2Installation
- Install-WSL2
- Install-AlpineLinux
- Test-RebootRequired
- Request-RebootWithContinuation
- Get-InstallationState
- Clear-InstallationState

### ProgressTracker-Simple.psm1
- Function Names: 4
- Parameter Names: 3
- Variable Names: 12
- Exported Functions: 3
- Violations: 17
#### Violations:
- **String Literal**: '[$timestamp] $StepName' contains '['
- **String Literal**: '[$timestamp] $StepName' contains ']'
- **String Literal**: '[$timestamp] $StepName' contains ' '
- **String Literal**: '   Warning: $($Details.warning)' contains '('
- **String Literal**: '   Warning: $($Details.warning)' contains ')'
- **String Literal**: '   Warning: $($Details.warning)' contains ' '
- **String Literal**: '   Error: $($Details.error)' contains '('
- **String Literal**: '   Error: $($Details.error)' contains ')'
- **String Literal**: '   Error: $($Details.error)' contains ' '
- **String Literal**: 'Error updating progress: $($_.Exception.Message)' contains '('
- **String Literal**: 'Error updating progress: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Error updating progress: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Starting Phase: $PhaseName' contains ' '
- **String Literal**: '   Expected steps: $PhaseSteps' contains ' '
- **String Literal**: 'Starting $PhaseName' contains ' '
- **String Literal**: 'Completed $PhaseName' contains ' '
- **String Literal**: 'Phase completed: $PhaseName' contains ' '

#### Functions:
- Update-InstallationProgress
- Start-InstallationPhase
- Complete-InstallationPhase
- @

#### Exported Functions:
- Update-InstallationProgress
- Start-InstallationPhase
- Complete-InstallationPhase

### ProgressTracker.psm1
- Function Names: 12
- Parameter Names: 4
- Variable Names: 39
- Exported Functions: 11
- Violations: 70
#### Violations:
- **String Literal**: 'Initializing progress tracking system...' contains ' '
- **String Literal**: 'Progress tracker script not found at: $NodeScriptPath' contains ' '
- **String Literal**: '
const ProgressTracker = require('$($NodeScriptPath.Replace('\', '/'))');
const tracker = new ProgressTracker($TotalSteps);
console.log('Progress tracker initialized with $TotalSteps steps');
' contains '('
- **String Literal**: '
const ProgressTracker = require('$($NodeScriptPath.Replace('\', '/'))');
const tracker = new ProgressTracker($TotalSteps);
console.log('Progress tracker initialized with $TotalSteps steps');
' contains ')'
- **String Literal**: '
const ProgressTracker = require('$($NodeScriptPath.Replace('\', '/'))');
const tracker = new ProgressTracker($TotalSteps);
console.log('Progress tracker initialized with $TotalSteps steps');
' contains ';'
- **String Literal**: '
const ProgressTracker = require('$($NodeScriptPath.Replace('\', '/'))');
const tracker = new ProgressTracker($TotalSteps);
console.log('Progress tracker initialized with $TotalSteps steps');
' contains ' '
- **String Literal**: 'Progress tracking initialized successfully' contains ' '
- **String Literal**: 'Failed to initialize progress tracker: $result' contains ' '
- **String Literal**: 'Error initializing progress tracker: $($_.Exception.Message)' contains '('
- **String Literal**: 'Error initializing progress tracker: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Error initializing progress tracker: $($_.Exception.Message)' contains ' '
- **String Literal**: '[$progressPercent%] $StepName' contains '['
- **String Literal**: '[$progressPercent%] $StepName' contains ']'
- **String Literal**: '[$progressPercent%] $StepName' contains ' '
- **String Literal**: '   Warning: $($Details.warning)' contains '('
- **String Literal**: '   Warning: $($Details.warning)' contains ')'
- **String Literal**: '   Warning: $($Details.warning)' contains ' '
- **String Literal**: '   Error: $($Details.error)' contains '('
- **String Literal**: '   Error: $($Details.error)' contains ')'
- **String Literal**: '   Error: $($Details.error)' contains ' '
- **String Literal**: 'Failed to update progress: $result' contains ' '
- **String Literal**: 'Error updating progress: $($_.Exception.Message)' contains '('
- **String Literal**: 'Error updating progress: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Error updating progress: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Starting Phase: $PhaseName' contains ' '
- **String Literal**: '   Expected steps: $PhaseSteps' contains ' '
- **String Literal**: 'Starting $PhaseName' contains ' '
- **String Literal**: 'Completed $PhaseName' contains ' '
- **String Literal**: 'Phase completed: $PhaseName' contains ' '
- **String Literal**: 'No progress state file found' contains ' '
- **String Literal**: 'Error reading progress state: $($_.Exception.Message)' contains '('
- **String Literal**: 'Error reading progress state: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Error reading progress state: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Error reading PowerShell progress update: $($_.Exception.Message)' contains '('
- **String Literal**: 'Error reading PowerShell progress update: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Error reading PowerShell progress update: $($_.Exception.Message)' contains ' '
- **String Literal**: '
Progress: $([math]::Round($Progress))
Status: $StatusText
SubText: $SubText
Timestamp: $(Get-Date -Format ' contains '('
- **String Literal**: '
Progress: $([math]::Round($Progress))
Status: $StatusText
SubText: $SubText
Timestamp: $(Get-Date -Format ' contains ')'
- **String Literal**: '
Progress: $([math]::Round($Progress))
Status: $StatusText
SubText: $SubText
Timestamp: $(Get-Date -Format ' contains '['
- **String Literal**: '
Progress: $([math]::Round($Progress))
Status: $StatusText
SubText: $SubText
Timestamp: $(Get-Date -Format ' contains ']'
- **String Literal**: '
Progress: $([math]::Round($Progress))
Status: $StatusText
SubText: $SubText
Timestamp: $(Get-Date -Format ' contains ' '
- **String Literal**: ')
' contains ')'
- **String Literal**: 'NSIS_PROGRESS:$([math]::Round($Progress))' contains '('
- **String Literal**: 'NSIS_PROGRESS:$([math]::Round($Progress))' contains ')'
- **String Literal**: 'NSIS_PROGRESS:$([math]::Round($Progress))' contains '['
- **String Literal**: 'NSIS_PROGRESS:$([math]::Round($Progress))' contains ']'
- **String Literal**: '
const ProgressTracker = require('$($script:NodeTrackerPath.Replace('\', '/'))');
const tracker = ProgressTracker.loadState();

if (tracker) {
    const summary = tracker.generateSummary();
    console.log(JSON.stringify(summary, null, 2));
} else {
    console.log(JSON.stringify({ error: 'No progress data available' }));
}
' contains '('
- **String Literal**: '
const ProgressTracker = require('$($script:NodeTrackerPath.Replace('\', '/'))');
const tracker = ProgressTracker.loadState();

if (tracker) {
    const summary = tracker.generateSummary();
    console.log(JSON.stringify(summary, null, 2));
} else {
    console.log(JSON.stringify({ error: 'No progress data available' }));
}
' contains ')'
- **String Literal**: '
const ProgressTracker = require('$($script:NodeTrackerPath.Replace('\', '/'))');
const tracker = ProgressTracker.loadState();

if (tracker) {
    const summary = tracker.generateSummary();
    console.log(JSON.stringify(summary, null, 2));
} else {
    console.log(JSON.stringify({ error: 'No progress data available' }));
}
' contains '{'
- **String Literal**: '
const ProgressTracker = require('$($script:NodeTrackerPath.Replace('\', '/'))');
const tracker = ProgressTracker.loadState();

if (tracker) {
    const summary = tracker.generateSummary();
    console.log(JSON.stringify(summary, null, 2));
} else {
    console.log(JSON.stringify({ error: 'No progress data available' }));
}
' contains '}'
- **String Literal**: '
const ProgressTracker = require('$($script:NodeTrackerPath.Replace('\', '/'))');
const tracker = ProgressTracker.loadState();

if (tracker) {
    const summary = tracker.generateSummary();
    console.log(JSON.stringify(summary, null, 2));
} else {
    console.log(JSON.stringify({ error: 'No progress data available' }));
}
' contains ';'
- **String Literal**: '
const ProgressTracker = require('$($script:NodeTrackerPath.Replace('\', '/'))');
const tracker = ProgressTracker.loadState();

if (tracker) {
    const summary = tracker.generateSummary();
    console.log(JSON.stringify(summary, null, 2));
} else {
    console.log(JSON.stringify({ error: 'No progress data available' }));
}
' contains ' '
- **String Literal**: 'Failed to get installation summary: $result' contains ' '
- **String Literal**: 'Error getting installation summary: $($_.Exception.Message)' contains '('
- **String Literal**: 'Error getting installation summary: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Error getting installation summary: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Cleaned up: $file' contains ' '
- **String Literal**: 'Could not clean up $file: $($_.Exception.Message)' contains '('
- **String Literal**: 'Could not clean up $file: $($_.Exception.Message)' contains ')'
- **String Literal**: 'Could not clean up $file: $($_.Exception.Message)' contains ' '
- **String Literal**: 'Node.js available: $nodeVersion' contains ' '
- **String Literal**: 'Node.js not available - progress tracking will be limited' contains ' '
- **String Literal**: 'Node.js not available - progress tracking will be limited' contains ' '
- **String Literal**: '[$timestamp] $StepName' contains '['
- **String Literal**: '[$timestamp] $StepName' contains ']'
- **String Literal**: '[$timestamp] $StepName' contains ' '
- **Potentially Problematic Command**: '& node' contains 'Command Pattern'
- **Potentially Problematic Command**: '& node' contains 'Command Pattern'
- **Potentially Problematic Command**: '& node' contains 'Command Pattern'
- **Potentially Problematic Command**: '& node' contains 'Command Pattern'

#### Functions:
- Initialize-ProgressTracker
- Update-InstallationProgress
- Start-InstallationPhase
- Complete-InstallationPhase
- Get-InstallationProgress
- Get-PowerShellProgressUpdate
- Write-ProgressToNSIS
- Get-InstallationSummary
- Clear-ProgressTracking
- Test-NodeJSAvailable
- Write-SimpleProgress
- @

#### Exported Functions:
- Initialize-ProgressTracker
- Update-InstallationProgress
- Start-InstallationPhase
- Complete-InstallationPhase
- Get-InstallationProgress
- Get-PowerShellProgressUpdate
- Write-ProgressToNSIS
- Get-InstallationSummary
- Clear-ProgressTracking
- Test-NodeJSAvailable
- Write-SimpleProgress

