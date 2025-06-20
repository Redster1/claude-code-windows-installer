# PowerShell Module Analysis Report
Generated: 06/19/2025 22:53:41

## Summary
- Total modules analyzed: 2
- Total violations found: 17
- Modules with violations: 2

## Restricted Characters
The following characters cause "imported command names" errors in NSIS:
#, (, ), {, }, [, ], &, *, ?, ;, ", |, <, >,  , 	

## Detailed Analysis

### ClaudeInstaller.psm1
- Function Names: 8
- Parameter Names: 1
- Variable Names: 25
- Exported Functions: 6
- Violations: 7
#### Violations:
- **String Literal**: 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' contains ' '
- **String Literal**: 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' contains ' '
- **String Literal**: '$timestamp $Level $Message' contains ' '
- **Potentially Problematic Command**: '& powershell' contains 'Command Pattern'
- **Potentially Problematic Command**: '& powershell' contains 'Command Pattern'
- **Potentially Problematic Command**: '& powershell' contains 'Command Pattern'
- **Potentially Problematic Command**: '& powershell' contains 'Command Pattern'


### ProgressTracker.psm1
- Function Names: 8
- Parameter Names: 4
- Variable Names: 23
- Exported Functions: 6
- Violations: 10
#### Violations:
- **String Literal**: '$timestamp Starting Phase $PhaseName' contains ' '
- **String Literal**: '$timestamp Expected steps $PhaseSteps' contains ' '
- **String Literal**: 'Starting $PhaseName' contains ' '
- **String Literal**: 'Completed $PhaseName' contains ' '
- **String Literal**: '$timestamp Phase completed $PhaseName' contains ' '
- **String Literal**: 'Progress: $roundedProgress`nStatus: $StatusText`nSubText: $SubText`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')' contains '('
- **String Literal**: 'Progress: $roundedProgress`nStatus: $StatusText`nSubText: $SubText`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')' contains ')'
- **String Literal**: 'Progress: $roundedProgress`nStatus: $StatusText`nSubText: $SubText`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')' contains ' '
- **Potentially Problematic Command**: '& powershell' contains 'Command Pattern'
- **Potentially Problematic Command**: '& powershell' contains 'Command Pattern'


