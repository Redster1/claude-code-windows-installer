# Comprehensive PowerShell Command Analysis Script
# Analyzes ALL aspects of PowerShell modules that could contain restricted characters
# Restricted characters: # ( ) { } [ ] & * ? ; " | < > space tab

param(
    [string]$ModulesPath = "src/scripts/powershell",
    [switch]$Detailed,
    [string]$OutputFile = $null
)

# Define restricted characters as per NSIS/PowerShell import error
$RestrictedChars = @('#', '(', ')', '{', '}', '[', ']', '&', '*', '?', ';', '"', '|', '<', '>', ' ', "`t")
$RestrictedPattern = '[#()\{\}\[\]&*?;"|<> \t]'

function Test-RestrictedCharacters {
    param([string]$Text, [string]$Context)
    
    $violations = @()
    foreach ($char in $RestrictedChars) {
        if ($Text.Contains($char)) {
            $violations += @{
                Character = $char
                Context = $Context
                Text = $Text
                CharCode = [int][char]$char
            }
        }
    }
    return $violations
}

function Analyze-PowerShellModule {
    param([string]$ModulePath)
    
    Write-Host "Analyzing: $ModulePath" -ForegroundColor Cyan
    
    $analysis = @{
        ModulePath = $ModulePath
        FunctionNames = @()
        ParameterNames = @()
        VariableNames = @()
        ExportedFunctions = @()
        Violations = @()
        AllStrings = @()
    }
    
    try {
        $content = Get-Content $ModulePath -Raw
        $lines = Get-Content $ModulePath
        
        # Extract function definitions
        $functionMatches = [regex]::Matches($content, 'function\s+([^\s{(]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($match in $functionMatches) {
            $funcName = $match.Groups[1].Value
            $analysis.FunctionNames += $funcName
            
            # Check function name for violations
            $violations = Test-RestrictedCharacters -Text $funcName -Context "Function Name"
            $analysis.Violations += $violations
        }
        
        # Extract parameter names from param blocks
        $paramMatches = [regex]::Matches($content, '\[Parameter[^\]]*\]\s*\[?[^\]]*\]?\s*\$([^\s,)]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($match in $paramMatches) {
            $paramName = $match.Groups[1].Value
            $analysis.ParameterNames += $paramName
            
            # Check parameter name for violations
            $violations = Test-RestrictedCharacters -Text $paramName -Context "Parameter Name"
            $analysis.Violations += $violations
        }
        
        # Extract all variable names
        $variableMatches = [regex]::Matches($content, '\$([a-zA-Z_][a-zA-Z0-9_:]*)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($match in $variableMatches) {
            $varName = $match.Groups[1].Value
            if ($varName -notin $analysis.VariableNames) {
                $analysis.VariableNames += $varName
                
                # Check variable name for violations
                $violations = Test-RestrictedCharacters -Text $varName -Context "Variable Name"
                $analysis.Violations += $violations
            }
        }
        
        # Extract Export-ModuleMember functions
        $exportMatches = [regex]::Matches($content, "Export-ModuleMember\s+-Function\s+@\((.*?)\)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        foreach ($match in $exportMatches) {
            $exportBlock = $match.Groups[1].Value
            $exportedFunctions = [regex]::Matches($exportBlock, "'([^']+)'")
            foreach ($exportFunc in $exportedFunctions) {
                $funcName = $exportFunc.Groups[1].Value
                $analysis.ExportedFunctions += $funcName
                
                # Check exported function name for violations
                $violations = Test-RestrictedCharacters -Text $funcName -Context "Exported Function Name"
                $analysis.Violations += $violations
            }
        }
        
        # Extract all quoted strings (potential command names or problematic strings)
        $stringMatches = [regex]::Matches($content, '"([^"]*)"')
        foreach ($match in $stringMatches) {
            $stringValue = $match.Groups[1].Value
            $analysis.AllStrings += $stringValue
            
            # Check strings for violations (these might be used in commands)
            $violations = Test-RestrictedCharacters -Text $stringValue -Context "String Literal"
            if ($violations.Count -gt 0) {
                $analysis.Violations += $violations
            }
        }
        
        # Check for problematic command patterns
        $commandPatterns = @(
            '& \w+',           # Command execution with &
            'Invoke-Expression',
            'Start-Process.*-ArgumentList',
            'powershell\.exe.*-Command'
        )
        
        foreach ($pattern in $commandPatterns) {
            $commandMatches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            foreach ($cmdMatch in $commandMatches) {
                $analysis.Violations += @{
                    Character = "Command Pattern"
                    Context = "Potentially Problematic Command"
                    Text = $cmdMatch.Value
                    CharCode = -1
                }
            }
        }
        
    }
    catch {
        Write-Error "Error analyzing ${ModulePath}: $($_.Exception.Message)"
    }
    
    return $analysis
}

# Main execution
Write-Host "=== Comprehensive PowerShell Module Analysis ===" -ForegroundColor Yellow
Write-Host "Checking for restricted characters: $($RestrictedChars -join ' ')" -ForegroundColor Yellow
Write-Host ""

$allAnalysis = @()
$totalViolations = 0

# Find all PowerShell module files
$moduleFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psm1" -Recurse

foreach ($moduleFile in $moduleFiles) {
    $analysis = Analyze-PowerShellModule -ModulePath $moduleFile.FullName
    $allAnalysis += $analysis
    $totalViolations += $analysis.Violations.Count
    
    if ($analysis.Violations.Count -gt 0) {
        Write-Host "VIOLATIONS FOUND in $($moduleFile.Name):" -ForegroundColor Red
        foreach ($violation in $analysis.Violations) {
            Write-Host "  - $($violation.Context): '$($violation.Text)' contains '$($violation.Character)'" -ForegroundColor Red
        }
        Write-Host ""
    } else {
        Write-Host "✓ No violations in $($moduleFile.Name)" -ForegroundColor Green
    }
}

# Generate summary report
$report = @"
# PowerShell Module Analysis Report
Generated: $(Get-Date)

## Summary
- Total modules analyzed: $($moduleFiles.Count)
- Total violations found: $totalViolations
- Modules with violations: $(($allAnalysis | Where-Object { $_.Violations.Count -gt 0 }).Count)

## Restricted Characters
The following characters cause "imported command names" errors in NSIS:
$($RestrictedChars -join ', ')

## Detailed Analysis

"@

foreach ($analysis in $allAnalysis) {
    $moduleName = Split-Path $analysis.ModulePath -Leaf
    $report += @"

### $moduleName
- Function Names: $($analysis.FunctionNames.Count)
- Parameter Names: $($analysis.ParameterNames.Count)
- Variable Names: $($analysis.VariableNames.Count)
- Exported Functions: $($analysis.ExportedFunctions.Count)
- Violations: $($analysis.Violations.Count)

"@

    if ($analysis.Violations.Count -gt 0) {
        $report += "#### Violations:`n"
        foreach ($violation in $analysis.Violations) {
            $report += "- **$($violation.Context)**: `'$($violation.Text)`' contains `'$($violation.Character)`'`n"
        }
        $report += "`n"
    }
    
    if ($Detailed) {
        $report += "#### Functions:`n"
        foreach ($func in $analysis.FunctionNames) {
            $report += "- $func`n"
        }
        
        $report += "`n#### Exported Functions:`n"
        foreach ($export in $analysis.ExportedFunctions) {
            $report += "- $export`n"
        }
    }
}

# Output report
if ($OutputFile) {
    $report | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Report saved to: $OutputFile" -ForegroundColor Green
} else {
    Write-Host $report
}

Write-Host ""
Write-Host "=== Analysis Complete ===" -ForegroundColor Yellow
Write-Host "Total violations: $totalViolations" -ForegroundColor $(if ($totalViolations -gt 0) { "Red" } else { "Green" })

if ($totalViolations -gt 0) {
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Review each violation above" -ForegroundColor Yellow
    Write-Host "2. Fix or rename problematic elements" -ForegroundColor Yellow
    Write-Host "3. Re-run this analysis to verify fixes" -ForegroundColor Yellow
    Write-Host "4. Test installer with cleaned modules" -ForegroundColor Yellow
}