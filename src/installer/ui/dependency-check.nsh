; Claude Code Windows Installer - Dependency Check UI Page
; Custom NSIS page for dependency checking with real-time progress

!include "nsDialogs.nsh"
!include "LogicLib.nsh"

; Page variables
Var DependencyDialog
Var DependencyLabel
Var ProgressBar
Var DependencyList
Var StatusLabel
Var TimeLabel
Var CheckButton
Var SkipButton

; Progress tracking variables
Var ProgressPercent
Var CurrentStep
Var TotalSteps
Var CheckInProgress

; Create the dependency check page
Function DependencyCheckPage
    !insertmacro MUI_HEADER_TEXT "System Dependencies" "Checking your system for required components..."
    
    ; Create the dialog
    nsDialogs::Create 1018
    Pop $DependencyDialog
    
    ${If} $DependencyDialog == error
        Abort
    ${EndIf}
    
    ; Main status label
    ${NSD_CreateLabel} 0 0 100% 20u "Checking system dependencies and requirements..."
    Pop $DependencyLabel
    
    ; Progress bar
    ${NSD_CreateProgressBar} 0 30u 100% 12u ""
    Pop $ProgressBar
    SendMessage $ProgressBar ${PBM_SETRANGE} 0 0x640064  ; 0-100 range
    
    ; Time remaining label
    ${NSD_CreateLabel} 0 50u 100% 12u "Estimated time: Calculating..."
    Pop $TimeLabel
    
    ; Dependency list box
    ${NSD_CreateListBox} 0 70u 100% 80u ""
    Pop $DependencyList
    
    ; Status label for current operation
    ${NSD_CreateLabel} 0 160u 100% 12u "Initializing dependency check..."
    Pop $StatusLabel
    
    ; Check button (starts dependency check)
    ${NSD_CreateButton} 0 180u 75u 15u "&Check Dependencies"
    Pop $CheckButton
    ${NSD_OnClick} $CheckButton OnCheckDependencies
    
    ; Skip button (for testing or force install)
    ${NSD_CreateButton} 85u 180u 75u 15u "&Skip Check"
    Pop $SkipButton
    ${NSD_OnClick} $SkipButton OnSkipDependencies
    
    ; Initialize state
    StrCpy $CheckInProgress "false"
    StrCpy $ProgressPercent "0"
    StrCpy $CurrentStep "0"
    StrCpy $TotalSteps "5"
    
    ; Auto-start check if not in debug mode
    ${If} $INSTDIR != ""
        Call StartDependencyCheck
    ${EndIf}
    
    nsDialogs::Show
FunctionEnd

; Start the dependency check process
Function StartDependencyCheck
    ${If} $CheckInProgress == "true"
        Return
    ${EndIf}
    
    StrCpy $CheckInProgress "true"
    EnableWindow $CheckButton 0  ; Disable check button
    
    ; Update UI
    ${NSD_SetText} $DependencyLabel "Checking system dependencies..."
    ${NSD_SetText} $StatusLabel "Initializing dependency detection..."
    
    ; Clear list box
    SendMessage $DependencyList ${LB_RESETCONTENT} 0 0
    
    ; Initialize progress tracking
    DetailPrint "Initializing dependency check..."
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; Initialize-ProgressTracker -TotalSteps 5"'
    Pop $0  ; Exit code
    Pop $1  ; Output
    
    ${If} $0 != 0
        DetailPrint "Warning: Progress tracking initialization failed: $1"
    ${EndIf}
    
    ; Start dependency checks
    Call CheckWindowsVersion
FunctionEnd

; Check Windows version compatibility
Function CheckWindowsVersion
    ${NSD_SetText} $StatusLabel "Checking Windows version..."
    SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:🔄 Checking Windows version..."
    
    ; Update progress (Step 1/5 = 20%)
    Call UpdateProgress "Checking Windows version" "starting"
    
    ; Run Windows version check
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\" -Force; $result = Test-WindowsVersion; if ($result.Passed) { Write-Output \"PASSED:Windows $($result.Version) (Build $($result.BuildNumber))\" } else { Write-Output \"FAILED:$($result.Message)\" }"'
    Pop $0  ; Exit code
    Pop $1  ; Output
    
    ${If} $0 == 0
        ; Parse result
        ${If} ${StrLoc} "$1" "PASSED:" 0
            StrCpy $2 $1 "" 7  ; Remove "PASSED:" prefix
            SendMessage $DependencyList ${LB_DELETESTRING} 0 0  ; Remove checking message
            SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:✅ Windows Version: $2"
            Call UpdateProgress "Checking Windows version" "completed"
        ${Else}
            StrCpy $2 $1 "" 7  ; Remove "FAILED:" prefix
            SendMessage $DependencyList ${LB_DELETESTRING} 0 0
            SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:❌ Windows Version: $2"
            Call UpdateProgress "Checking Windows version" "failed"
        ${EndIf}
    ${Else}
        SendMessage $DependencyList ${LB_DELETESTRING} 0 0
        SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:❌ Windows Version: Check failed"
        Call UpdateProgress "Checking Windows version" "failed"
    ${EndIf}
    
    ; Continue to next check
    Call CheckAdminRights
FunctionEnd

; Check administrator privileges
Function CheckAdminRights
    ${NSD_SetText} $StatusLabel "Checking administrator privileges..."
    SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:🔄 Checking administrator privileges..."
    
    Call UpdateProgress "Checking administrator privileges" "starting"
    
    ; Check admin rights
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\" -Force; $result = Test-AdminRights; if ($result.Passed) { Write-Output \"PASSED:Administrator privileges confirmed\" } else { Write-Output \"FAILED:$($result.Message)\" }"'
    Pop $0
    Pop $1
    
    ${If} $0 == 0
        ${If} ${StrLoc} "$1" "PASSED:" 0
            StrCpy $2 $1 "" 7
            SendMessage $DependencyList ${LB_DELETESTRING} 1 0
            SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:✅ Admin Rights: $2"
            Call UpdateProgress "Checking administrator privileges" "completed"
        ${Else}
            StrCpy $2 $1 "" 7
            SendMessage $DependencyList ${LB_DELETESTRING} 1 0
            SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:❌ Admin Rights: $2"
            Call UpdateProgress "Checking administrator privileges" "failed"
        ${EndIf}
    ${Else}
        SendMessage $DependencyList ${LB_DELETESTRING} 1 0
        SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:❌ Admin Rights: Check failed"
        Call UpdateProgress "Checking administrator privileges" "failed"
    ${EndIf}
    
    Call CheckWSL2Status
FunctionEnd

; Check WSL2 installation status
Function CheckWSL2Status
    ${NSD_SetText} $StatusLabel "Checking WSL2 installation..."
    SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:🔄 Checking WSL2 installation..."
    
    Call UpdateProgress "Checking WSL2 installation" "starting"
    
    ; Check WSL2
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\" -Force; $result = Test-WSL2Installation; if ($result.Installed) { Write-Output \"PASSED:WSL2 version $($result.Version) installed\" } else { Write-Output \"NOTFOUND:WSL2 not installed - will be installed\" }"'
    Pop $0
    Pop $1
    
    ${If} $0 == 0
        ${If} ${StrLoc} "$1" "PASSED:" 0
            StrCpy $2 $1 "" 7
            SendMessage $DependencyList ${LB_DELETESTRING} 2 0
            SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:✅ WSL2: $2"
            Call UpdateProgress "Checking WSL2 installation" "completed"
        ${Else}
            StrCpy $2 $1 "" 9  ; Remove "NOTFOUND:" prefix
            SendMessage $DependencyList ${LB_DELETESTRING} 2 0
            SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:📦 WSL2: $2"
            Call UpdateProgress "Checking WSL2 installation" "skipped"
        ${EndIf}
    ${Else}
        SendMessage $DependencyList ${LB_DELETESTRING} 2 0
        SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:❌ WSL2: Check failed"
        Call UpdateProgress "Checking WSL2 installation" "failed"
    ${EndIf}
    
    Call CheckDiskSpace
FunctionEnd

; Check available disk space
Function CheckDiskSpace
    ${NSD_SetText} $StatusLabel "Checking available disk space..."
    SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:🔄 Checking disk space..."
    
    Call UpdateProgress "Checking disk space" "starting"
    
    ; Check disk space
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\" -Force; $result = Test-DiskSpace; if ($result.Passed) { Write-Output \"PASSED:$($result.AvailableGB) GB available\" } else { Write-Output \"FAILED:$($result.Message)\" }"'
    Pop $0
    Pop $1
    
    ${If} $0 == 0
        ${If} ${StrLoc} "$1" "PASSED:" 0
            StrCpy $2 $1 "" 7
            SendMessage $DependencyList ${LB_DELETESTRING} 3 0
            SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:✅ Disk Space: $2"
            Call UpdateProgress "Checking disk space" "completed"
        ${Else}
            StrCpy $2 $1 "" 7
            SendMessage $DependencyList ${LB_DELETESTRING} 3 0
            SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:❌ Disk Space: $2"
            Call UpdateProgress "Checking disk space" "failed"
        ${EndIf}
    ${Else}
        SendMessage $DependencyList ${LB_DELETESTRING} 3 0
        SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:❌ Disk Space: Check failed"
        Call UpdateProgress "Checking disk space" "failed"
    ${EndIf}
    
    Call CheckNetworkConnectivity
FunctionEnd

; Check network connectivity
Function CheckNetworkConnectivity
    ${NSD_SetText} $StatusLabel "Checking network connectivity..."
    SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:🔄 Checking network connectivity..."
    
    Call UpdateProgress "Checking network connectivity" "starting"
    
    ; Check network
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\" -Force; $result = Test-NetworkConnectivity; if ($result.Passed) { Write-Output \"PASSED:Internet connectivity confirmed\" } else { Write-Output \"FAILED:$($result.Message)\" }"'
    Pop $0
    Pop $1
    
    ${If} $0 == 0
        ${If} ${StrLoc} "$1" "PASSED:" 0
            StrCpy $2 $1 "" 7
            SendMessage $DependencyList ${LB_DELETESTRING} 4 0
            SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:✅ Network: $2"
            Call UpdateProgress "Checking network connectivity" "completed"
        ${Else}
            StrCpy $2 $1 "" 7
            SendMessage $DependencyList ${LB_DELETESTRING} 4 0
            SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:❌ Network: $2"
            Call UpdateProgress "Checking network connectivity" "failed"
        ${EndIf}
    ${Else}
        SendMessage $DependencyList ${LB_DELETESTRING} 4 0
        SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:❌ Network: Check failed"
        Call UpdateProgress "Checking network connectivity" "failed"
    ${EndIf}
    
    Call FinalizeDependencyCheck
FunctionEnd

; Finalize dependency check
Function FinalizeDependencyCheck
    ${NSD_SetText} $StatusLabel "Dependency check completed"
    ${NSD_SetText} $TimeLabel "Check completed successfully"
    
    ; Update progress to 100%
    SendMessage $ProgressBar ${PBM_SETPOS} 100 0
    
    ; Enable next button if checks passed
    EnableWindow $CheckButton 1
    StrCpy $CheckInProgress "false"
    
    ; Get final summary
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; $summary = Get-InstallationSummary; Write-Output \"Summary: $($summary.completedSteps) checks completed, $($summary.failedSteps) failed\""'
    Pop $0
    Pop $1
    
    ${If} $0 == 0
        ${NSD_SetText} $DependencyLabel "System dependency check completed - $1"
    ${Else}
        ${NSD_SetText} $DependencyLabel "System dependency check completed"
    ${EndIf}
    
    DetailPrint "Dependency check completed"
FunctionEnd

; Update progress bar and tracking
Function UpdateProgress
    Pop $R1  ; Status
    Pop $R0  ; Step name
    
    ; Update progress tracking
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; $result = Update-InstallationProgress \"$R0\" \"$R1\"; Write-Output $result.progress"'
    Pop $0  ; Exit code
    Pop $1  ; Progress percentage
    
    ${If} $0 == 0
        ; Update progress bar
        SendMessage $ProgressBar ${PBM_SETPOS} $1 0
        StrCpy $ProgressPercent $1
        
        ; Update time estimate
        ${NSD_SetText} $TimeLabel "Progress: $1% completed"
    ${EndIf}
FunctionEnd

; Button click handlers
Function OnCheckDependencies
    Call StartDependencyCheck
FunctionEnd

Function OnSkipDependencies
    ; Skip dependency check (for testing)
    ${NSD_SetText} $DependencyLabel "Dependency check skipped - proceeding with installation"
    ${NSD_SetText} $StatusLabel "Skipped by user request"
    SendMessage $ProgressBar ${PBM_SETPOS} 100 0
    
    ; Clear and add skip message
    SendMessage $DependencyList ${LB_RESETCONTENT} 0 0
    SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:⏭️ Dependency check skipped by user"
    SendMessage $DependencyList ${LB_ADDSTRING} 0 "STR:⚠️ Installation may fail if requirements are not met"
    
    EnableWindow $CheckButton 1
    StrCpy $CheckInProgress "false"
FunctionEnd

; Page leave function
Function DependencyCheckPageLeave
    ; Clean up progress tracking
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; Clear-ProgressTracking"'
    Pop $0
    Pop $1
FunctionEnd