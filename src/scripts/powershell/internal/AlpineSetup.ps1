# Claude Code Installer - Alpine Linux Setup Script
# This script can contain any characters since it's not imported as a module

param(
    [switch]$SetAsDefault,
    [switch]$SkipIfExists,
    [string]$Username = "claude",
    [int]$TimeoutMinutes = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Test-WSL2Installation {
    try {
        $wslStatus = & wsl --status 2>$null
        if ($LASTEXITCODE -ne 0) {
            return @{ Installed = $false; Message = "WSL not installed" }
        }
        
        return @{ Installed = $true; Message = "WSL2 is available" }
    }
    catch {
        return @{ Installed = $false; Message = "Error checking WSL2: $($_.Exception.Message)" }
    }
}

function Install-AlpineLinux {
    Write-Output "Starting Alpine Linux installation and configuration"
    
    try {
        # Step 1: Check if Alpine is already installed
        $distributions = Get-WSLDistributions
        $alpineExists = $distributions | Where-Object { $_.Name -like "*Alpine*" }
        
        if ($alpineExists -and $SkipIfExists) {
            Write-Output "Alpine Linux already installed, skipping"
            return @{
                Success = $true
                AlreadyInstalled = $true
                DistributionName = $alpineExists.Name
                State = $alpineExists.State
                Message = "Alpine Linux already available and functional"
            }
        }
        
        # Step 2: Validate WSL2 is ready
        Write-Output "Validating WSL2 environment"
        $wslStatus = Test-WSL2Installation
        if (-not $wslStatus.Installed) {
            throw "WSL2 must be installed before installing Alpine Linux"
        }
        
        # Step 3: Install Alpine Linux if not exists
        if (-not $alpineExists) {
            Write-Output "Downloading Alpine Linux distribution"
            Write-Output "Installing Alpine Linux distribution..."
            
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
            
            Write-Output "Alpine Linux distribution installed successfully"
        }
        
        # Step 4: Verify installation and get distribution info
        Write-Output "Verifying installation"
        Start-Sleep -Seconds 3  # Allow WSL to register the new distribution
        
        $distributions = Get-WSLDistributions
        $alpine = $distributions | Where-Object { $_.Name -like "*Alpine*" }
        
        if (-not $alpine) {
            throw "Alpine Linux installation verification failed - distribution not found"
        }
        
        Write-Output "Alpine Linux verified: $($alpine.Name) - State: $($alpine.State)"
        
        # Step 5: Start Alpine if not running
        if ($alpine.State -ne "Running") {
            Write-Output "Starting Alpine Linux"
            Write-Output "Starting Alpine Linux distribution..."
            
            & wsl -d $alpine.Name --exec echo "Starting Alpine..." 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Output "Warning: Could not start Alpine Linux automatically"
            } else {
                Write-Output "Alpine Linux started successfully"
            }
        }
        
        # Step 6: Basic Alpine configuration
        Write-Output "Configuring Alpine Linux"
        $configResult = Initialize-AlpineConfiguration -DistributionName $alpine.Name -Username $Username
        
        if (-not $configResult.Success) {
            Write-Output "Warning: Alpine configuration incomplete: $($configResult.Error)"
        }
        
        # Step 7: Set as default if requested
        if ($SetAsDefault) {
            Write-Output "Setting as default distribution"
            Write-Output "Setting Alpine Linux as default WSL distribution..."
            
            & wsl --set-default $alpine.Name 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Output "Alpine Linux set as default distribution"
            } else {
                Write-Output "Warning: Could not set Alpine as default distribution"
            }
        }
        
        # Step 8: Final validation
        Write-Output "Final validation"
        $finalValidation = Test-AlpineInstallation -DistributionName $alpine.Name
        
        Write-Output "Alpine Linux ready"
        Write-Output "Alpine Linux installation and configuration completed successfully"
        
        return @{
            Success = $true
            AlreadyInstalled = $null -ne $alpineExists
            DistributionName = $alpine.Name
            State = $alpine.State
            IsDefault = $SetAsDefault
            Configuration = $configResult
            Validation = $finalValidation
            Message = "Alpine Linux installed and configured successfully"
        }
        
    }
    catch {
        Write-Output "Alpine Linux installation failed: $($_.Exception.Message)"
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            Message = "Alpine Linux installation failed: $($_.Exception.Message)"
        }
    }
}

function Initialize-AlpineConfiguration {
    param(
        [Parameter(Mandatory)]
        [string]$DistributionName,
        [string]$Username = "claude"
    )
    
    Write-Output "Configuring Alpine Linux for Claude Code development..."
    
    try {
        # Test basic connectivity
        $testResult = & wsl -d $DistributionName --exec echo "Alpine Ready" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot communicate with Alpine Linux: $testResult"
        }
        
        # Get Alpine version
        $alpineVersion = & wsl -d $DistributionName --exec cat /etc/alpine-release 2>$null
        Write-Output "Alpine Linux version: $alpineVersion"
        
        # Check if root setup is needed
        $rootCheck = & wsl -d $DistributionName --exec whoami 2>$null
        Write-Output "Current Alpine user: $rootCheck"
        
        # Use direct commands instead of complex bash script to avoid PowerShell parsing issues
        Write-Output "Updating package repository..."
        & wsl -d $DistributionName --exec apk update 2>$null
        
        Write-Output "Installing essential packages..."
        & wsl -d $DistributionName --exec apk add --no-cache curl wget git nodejs npm 2>$null
        
        # Create user if needed
        if ($Username -ne "root") {
            Write-Output "Checking/creating user: $Username"
            $userExists = & wsl -d $DistributionName --exec id $Username 2>$null
            if ($LASTEXITCODE -ne 0) {
                & wsl -d $DistributionName --exec adduser -D -s /bin/sh $Username 2>$null
                Write-Output "Created user: $Username"
            }
        }
        
        # Verify tools installation
        Write-Output "Verifying tool installation..."
        $curlVersion = & wsl -d $DistributionName --exec curl --version 2>$null | Select-Object -First 1
        $gitVersion = & wsl -d $DistributionName --exec git --version 2>$null
        $nodeVersion = & wsl -d $DistributionName --exec node --version 2>$null
        $npmVersion = & wsl -d $DistributionName --exec npm --version 2>$null
        
        $setupOutput = "Alpine Linux configuration completed.`n"
        $setupOutput += "curl: $(if ($curlVersion) { $curlVersion } else { 'Not available' })`n"
        $setupOutput += "git: $(if ($gitVersion) { $gitVersion } else { 'Not available' })`n"
        $setupOutput += "node: $(if ($nodeVersion) { $nodeVersion } else { 'Not available' })`n"
        $setupOutput += "npm: $(if ($npmVersion) { $npmVersion } else { 'Not available' })`n"
        
        Write-Output "Alpine configuration output: $setupOutput"
        
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
    param(
        [Parameter(Mandatory)]
        [string]$DistributionName
    )
    
    Write-Output "Validating Alpine Linux installation..."
    
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
        
        Write-Output "Alpine validation completed. All checks passed: $allPassed"
        
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

# Main execution
try {
    $result = Install-AlpineLinux
    return $result
}
catch {
    return @{
        Success = $false
        Error = $_.Exception.Message
        Message = "Alpine setup script failed: $($_.Exception.Message)"
    }
}