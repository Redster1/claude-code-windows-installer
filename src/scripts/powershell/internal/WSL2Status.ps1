# Claude Code Installer - WSL2 Status Check Script
# This script can contain any characters since it's not imported as a module

param()

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
        return @()
    }
}

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

# Main execution
try {
    $result = Test-WSL2Installation
    return $result
}
catch {
    return @{
        Installed = $false
        Error = $_.Exception.Message
        Message = "WSL2 status check failed: $($_.Exception.Message)"
    }
}