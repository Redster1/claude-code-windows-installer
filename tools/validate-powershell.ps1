# PowerShell Module Validation Script
# Validates PowerShell modules for syntax errors and best practices

param(
    [Parameter(Mandatory)]
    [string]$ModulePath,
    
    [switch]$Detailed,
    [switch]$FixErrors
)

Write-Host "=== PowerShell Module Validation ===" -ForegroundColor Cyan
Write-Host "Validating: $ModulePath" -ForegroundColor White

# Check if PSScriptAnalyzer is available
$hasAnalyzer = Get-Module -ListAvailable PSScriptAnalyzer
if (-not $hasAnalyzer) {
    Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Yellow
    try {
        Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
        Write-Host "✅ PSScriptAnalyzer installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to install PSScriptAnalyzer: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Falling back to basic syntax validation..." -ForegroundColor Yellow
    }
}

# Function to perform basic syntax validation
function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    try {
        # Parse the PowerShell file to check for syntax errors
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
        
        if ($errors.Count -gt 0) {
            Write-Host "❌ Syntax Errors Found:" -ForegroundColor Red
            foreach ($error in $errors) {
                Write-Host "  Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Red
            }
            return $false
        } else {
            Write-Host "✅ No syntax errors found" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "❌ Failed to parse file: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check for problematic patterns
function Test-ProblematicPatterns {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw
    $issues = @()
    
    # Check for Write-Error in embedded commands
    if ($content -match 'Write-Error') {
        $issues += "Contains Write-Error calls which may cause issues in NSIS execution"
    }
    
    # Check for problematic characters in function names
    $functionPattern = 'function\s+([^\s\{]+)'
    $functions = [regex]::Matches($content, $functionPattern) | ForEach-Object { $_.Groups[1].Value }
    
    foreach ($func in $functions) {
        if ($func -match '[\#\(\)\{\}\[\]\&\*\?\;\"|\<\>]') {
            $issues += "Function '$func' contains potentially problematic characters"
        }
    }
    
    # Check for missing error handling
    $getWmiObjectPattern = 'Get-WmiObject[^;]*(?!\s*-ErrorAction)'
    if ([regex]::IsMatch($content, $getWmiObjectPattern)) {
        $issues += "Get-WmiObject calls without explicit error handling detected"
    }
    
    # Check for missing CIM error handling
    $getCimInstanceLines = $content -split "`n" | Where-Object { $_ -match 'Get-CimInstance' }
    foreach ($line in $getCimInstanceLines) {
        if ($line -notmatch '-ErrorAction') {
            $issues += "Get-CimInstance calls without explicit error handling detected"
            break
        }
    }
    
    if ($issues.Count -gt 0) {
        Write-Host "⚠️  Potential Issues Found:" -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host "  • $issue" -ForegroundColor Yellow
        }
        return $false
    } else {
        Write-Host "✅ No problematic patterns detected" -ForegroundColor Green
        return $true
    }
}

# Function to run PSScriptAnalyzer if available
function Invoke-PowerShellAnalyzer {
    param([string]$FilePath)
    
    try {
        $results = Invoke-ScriptAnalyzer -Path $FilePath -Severity Warning,Error
        
        if ($results.Count -eq 0) {
            Write-Host "✅ PSScriptAnalyzer found no issues" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠️  PSScriptAnalyzer Issues:" -ForegroundColor Yellow
            foreach ($result in $results) {
                $color = if ($result.Severity -eq 'Error') { 'Red' } else { 'Yellow' }
                Write-Host "  [$($result.Severity)] Line $($result.Line): $($result.Message)" -ForegroundColor $color
                if ($Detailed) {
                    Write-Host "    Rule: $($result.RuleName)" -ForegroundColor Gray
                    Write-Host "    Suggestion: $($result.SuggestedCorrections)" -ForegroundColor Gray
                }
            }
            return $false
        }
    }
    catch {
        Write-Host "❌ PSScriptAnalyzer failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main validation logic
$overallResult = $true

Write-Host "`n1. Basic Syntax Validation" -ForegroundColor Cyan
$syntaxResult = Test-PowerShellSyntax -FilePath $ModulePath
$overallResult = $overallResult -and $syntaxResult

Write-Host "`n2. Problematic Patterns Check" -ForegroundColor Cyan
$patternsResult = Test-ProblematicPatterns -FilePath $ModulePath
$overallResult = $overallResult -and $patternsResult

Write-Host "`n3. PSScriptAnalyzer Validation" -ForegroundColor Cyan
if (Get-Module -ListAvailable PSScriptAnalyzer) {
    $analyzerResult = Invoke-PowerShellAnalyzer -FilePath $ModulePath
    $overallResult = $overallResult -and $analyzerResult
} else {
    Write-Host "⚠️  PSScriptAnalyzer not available, skipping advanced analysis" -ForegroundColor Yellow
}

Write-Host "`n=== Validation Summary ===" -ForegroundColor Cyan
if ($overallResult) {
    Write-Host "✅ Module validation PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Module validation FAILED" -ForegroundColor Red
    Write-Host "Please fix the issues above and re-run validation." -ForegroundColor Yellow
    exit 1
}