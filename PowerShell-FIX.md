# PowerShell Module Integration Fix Plan

## Problem Analysis
The Claude Code installer is failing WSL2 installation because:

1. **PowerShell modules ARE extracted** (lines 890-893 in main.nsi) to `$INSTDIR\scripts\powershell\`
2. **But installer functions DON'T use them** - they use basic inline PowerShell with "disabled for testing" messages
3. **Critical functions affected:**
   - `InstallWSL2Features()` - Line 1021-1023 says "PowerShell modules disabled for testing"
   - `ValidateSystemRequirements()` - Line 1227-1229 same message  
   - `InstallAlpineLinux()` - Line 1060-1062 same message

## Root Cause
The TODO comments indicate file extraction was problematic during development, so PowerShell module usage was temporarily disabled. However:
- File extraction IS working (modules are extracted)
- Basic inline PowerShell commands are insufficient for complex WSL2 setup
- Users see confusing "disabled for testing" messages on production installer

## Available PowerShell Modules
From build system, we have:
- `ClaudeCodeInstaller.psm1` - Main automation functions
- `ProgressTracker.psm1` - Progress tracking utilities

## Fix Strategy

### Phase 1: Enable PowerShell Module Import
**Target:** All functions that currently say "PowerShell modules disabled for testing"
**Action:** Replace inline PowerShell with proper module import and function calls

### Phase 2: Update InstallWSL2Features Function
**Current code (lines 1021-1024):**
```nsis
; TODO: Use PowerShell module when file extraction is fixed
; For now, use basic WSL2 installation
DetailPrint "Installing WSL2 using basic method (PowerShell modules disabled for testing)..."
nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "try { Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart; Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart; Write-Output \"WSL2 features enabled\"; exit 0 } catch { Write-Error $_.Exception.Message; exit 1 }"'
```

**New approach:**
```nsis
DetailPrint "Installing WSL2 using comprehensive PowerShell module..."
nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\"; Install-WSL2Features"'
```

### Phase 3: Update ValidateSystemRequirements Function  
**Current code (lines 1227-1230):**
```nsis
; TODO: Import PowerShell module when file extraction is fixed
; For now, use basic validation
DetailPrint "Performing basic system validation (PowerShell modules disabled for testing)..."
nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "if ([System.Environment]::OSVersion.Version.Build -lt 19041) { Write-Error \"Windows build too old\"; exit 1 } else { Write-Output \"Basic system validation passed\" }"'
```

**New approach:**
```nsis
DetailPrint "Validating system requirements using comprehensive PowerShell module..."
nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\"; Test-SystemRequirements"'
```

### Phase 4: Update InstallAlpineLinux Function
**Current code (lines 1060-1063):**
```nsis
; TODO: Use PowerShell module when file extraction is fixed  
; For now, use basic Alpine installation
DetailPrint "Installing Alpine using basic method (PowerShell modules disabled for testing)..."
nsExec::ExecToStack 'wsl --install -d Alpine'
```

**New approach:**
```nsis
DetailPrint "Installing and configuring Alpine Linux using PowerShell module..."
nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\"; Install-AlpineLinux"'
```

### Phase 5: Progress Tracking Integration
**Add to progress-intensive functions:**
```nsis
nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\"; Update-Progress -Phase \"WSL2Installation\" -Percent 50"'
```

## PowerShell Module Requirements

### ClaudeCodeInstaller.psm1 must provide:
- `Install-WSL2Features` - Comprehensive WSL2 installation with proper error handling
- `Test-SystemRequirements` - Advanced system validation (Windows build, virtualization, etc.)
- `Install-AlpineLinux` - Alpine installation with automatic configuration
- Proper exit codes and error messages for NSIS consumption

### ProgressTracker.psm1 must provide:
- `Update-Progress` - Progress reporting back to NSIS UI
- Integration with NSIS progress bar system

## Implementation Steps

1. **Examine existing PowerShell modules** to understand available functions
2. **Update NSIS functions** to use modules instead of inline commands  
3. **Test module import** - verify modules load correctly from installer directory
4. **Handle module path resolution** - ensure absolute paths work in NSIS context
5. **Error handling integration** - map PowerShell module errors to NSIS abort conditions
6. **Remove all "disabled for testing" messages**
7. **Build and test** on Windows VM

## Risk Mitigation

### If PowerShell modules are incomplete:
- Enhance modules with missing functions
- Ensure error codes and output format match NSIS expectations

### If path resolution fails:
- Use `$INSTDIR` variable expansion carefully
- Test absolute vs relative path handling

### If import fails:
- Add PowerShell execution policy handling
- Verify module file permissions and signatures

## Success Criteria
- ✅ No "disabled for testing" messages in installer
- ✅ PowerShell modules imported and used properly
- ✅ Full-size installer (368KB) with all components  
- ✅ Comprehensive WSL2 installation with reboot handling
- ✅ Alpine Linux installation with configuration
- ✅ Advanced system requirements validation
- 🔄 WSL2 installation testing on Windows VM (next step)

## Testing Requirements
1. **Windows VM test** - Full installation end-to-end
2. **Error condition testing** - What happens when things fail
3. **Module import verification** - PowerShell modules load successfully
4. **WSL2 feature verification** - Features actually get enabled