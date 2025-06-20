# PowerShell Module Analysis Report
Generated: 06/19/2025 22:57:02

## Summary
- Total modules analyzed: 2
- Total violations found: 2
- Modules with violations: 7

## Restricted Characters
The following characters cause "imported command names" errors in NSIS:
#, (, ), {, }, [, ], &, *, ?, ;, ", |, <, >,  , 	

## Detailed Analysis

### ClaudeInstaller.psm1
- Function Names: 8
- Parameter Names: 1
- Variable Names: 24
- Exported Functions: 6
- Violations: 2
#### Violations:
- **Potentially Problematic Command**: '& character' contains 'Command Pattern'
- **Potentially Problematic Command**: '& character' contains 'Command Pattern'


### ProgressTracker.psm1
- Function Names: 8
- Parameter Names: 4
- Variable Names: 23
- Exported Functions: 6
- Violations: 0

