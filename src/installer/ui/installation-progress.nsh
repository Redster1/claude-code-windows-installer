; Claude Code Windows Installer - Installation Progress UI Page
; Real-time progress tracking for WSL2, Alpine, and Claude Code installation

!include "nsDialogs.nsh"
!include "LogicLib.nsh"

; Page variables
Var ProgressDialog
Var ProgressLabel
Var MainProgressBar
Var PhaseProgressBar
Var InstallationList
Var CurrentStatusLabel
Var TimeEstimateLabel
Var PhaseLabel
Var CancelButton

; Installation state variables
Var InstallationInProgress
Var CurrentPhase
Var TotalPhases
Var OverallProgress
Var PhaseProgress
Var EstimatedTimeRemaining
Var InstallationStartTime

; Create the installation progress page
Function InstallationProgressPage
    !insertmacro MUI_HEADER_TEXT "Installing Claude Code" "Setting up WSL2, Alpine Linux, and Claude Code CLI..."
    
    ; Create the dialog
    nsDialogs::Create 1018
    Pop $ProgressDialog
    
    ${If} $ProgressDialog == error
        Abort
    ${EndIf}
    
    ; Main installation label
    ${NSD_CreateLabel} 0 0 100% 20u "Installing Claude Code for Windows..."
    Pop $ProgressLabel
    
    ; Overall progress bar
    ${NSD_CreateLabel} 0 25u 15% 12u "Overall:"
    Pop $R0
    ${NSD_CreateProgressBar} 20% 25u 80% 12u ""
    Pop $MainProgressBar
    SendMessage $MainProgressBar ${PBM_SETRANGE} 0 0x640064  ; 0-100 range
    
    ; Phase progress bar
    ${NSD_CreateLabel} 0 45u 15% 12u "Phase:"
    Pop $PhaseLabel
    ${NSD_CreateProgressBar} 20% 45u 80% 12u ""
    Pop $PhaseProgressBar
    SendMessage $PhaseProgressBar ${PBM_SETRANGE} 0 0x640064
    
    ; Time estimate label
    ${NSD_CreateLabel} 0 65u 100% 12u "Estimated time remaining: Calculating..."
    Pop $TimeEstimateLabel
    
    ; Installation steps list
    ${NSD_CreateListBox} 0 85u 100% 80u ""
    Pop $InstallationList
    
    ; Current status label
    ${NSD_CreateLabel} 0 175u 100% 12u "Initializing installation..."
    Pop $CurrentStatusLabel
    
    ; Cancel button
    ${NSD_CreateButton} 0 195u 75u 15u "&Cancel Installation"
    Pop $CancelButton
    ${NSD_OnClick} $CancelButton OnCancelInstallation
    
    ; Initialize installation state
    StrCpy $InstallationInProgress "false"
    StrCpy $CurrentPhase "Initialization"
    StrCpy $TotalPhases "4"
    StrCpy $OverallProgress "0"
    StrCpy $PhaseProgress "0"
    System::Call 'kernel32::GetTickCount() i .r$InstallationStartTime'
    
    ; Auto-start installation
    Call StartInstallationProcess
    
    nsDialogs::Show
FunctionEnd

; Start the main installation process
Function StartInstallationProcess
    ${If} $InstallationInProgress == "true"
        Return
    ${EndIf}
    
    StrCpy $InstallationInProgress "true"
    EnableWindow $CancelButton 1
    
    ; Initialize progress tracking with total steps
    DetailPrint "Initializing Claude Code installation..."
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; Initialize-ProgressTracker -TotalSteps 12"'
    Pop $0
    Pop $1
    
    ${If} $0 != 0
        DetailPrint "Warning: Progress tracking initialization failed: $1"
    ${EndIf}
    
    ; Add initial status to list
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:🚀 Claude Code installation started"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:📋 Installation plan:"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:   1. System validation"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:   2. WSL2 installation and configuration"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:   3. Alpine Linux setup"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:   4. Claude Code CLI installation"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:"
    
    ; Start with system validation
    Call StartSystemValidationPhase
FunctionEnd

; Phase 1: System Validation
Function StartSystemValidationPhase
    StrCpy $CurrentPhase "System Validation"
    ${NSD_SetText} $PhaseLabel "Phase: System Validation"
    ${NSD_SetText} $CurrentStatusLabel "Validating system requirements..."
    
    Call StartPhaseProgress "System Validation" 3
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:🔍 Phase 1: System Validation"
    
    ; Run system validation
    Call ValidateSystemRequirements
FunctionEnd

Function ValidateSystemRequirements
    Call UpdatePhaseProgress "Validating Windows version and architecture" "starting"
    
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\" -Force; $result = Test-SystemRequirements; if ($result.OverallResult.Passed) { Write-Output \"SUCCESS\" } else { Write-Output \"FAILED:$($result.OverallResult.Summary)\" }"'
    Pop $0
    Pop $1
    
    ${If} $0 == 0
        ${If} ${StrLoc} "$1" "SUCCESS" 0
            SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:✅ System requirements validated"
            Call UpdatePhaseProgress "Validating Windows version and architecture" "completed"
        ${Else}
            StrCpy $2 $1 "" 7  ; Remove "FAILED:" prefix
            SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:❌ System validation failed: $2"
            Call UpdatePhaseProgress "Validating Windows version and architecture" "failed"
            Call HandleInstallationError "System validation failed" "$2"
            Return
        ${EndIf}
    ${Else}
        SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:❌ System validation error"
        Call UpdatePhaseProgress "Validating Windows version and architecture" "failed"
        Call HandleInstallationError "System validation error" "Could not run system checks"
        Return
    ${EndIf}
    
    Call StartWSL2InstallationPhase
FunctionEnd

; Phase 2: WSL2 Installation
Function StartWSL2InstallationPhase
    StrCpy $CurrentPhase "WSL2 Installation"
    ${NSD_SetText} $PhaseLabel "Phase: WSL2 Installation"
    ${NSD_SetText} $CurrentStatusLabel "Installing Windows Subsystem for Linux 2..."
    
    Call CompletePhaseProgress "System Validation"
    Call StartPhaseProgress "WSL2 Installation" 4
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:🔧 Phase 2: WSL2 Installation"
    
    Call InstallWSL2
FunctionEnd

Function InstallWSL2
    Call UpdatePhaseProgress "Installing WSL2 components" "starting"
    
    ; Run WSL2 installation with progress integration
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\" -Force; Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; $result = Install-WSL2 -SkipIfExists; if ($result.Success) { if ($result.RebootRequired) { Write-Output \"REBOOT_REQUIRED\" } else { Write-Output \"SUCCESS\" } } else { Write-Output \"FAILED:$($result.Message)\" }"'
    Pop $0
    Pop $1
    
    ${If} $0 == 0
        ${If} ${StrLoc} "$1" "SUCCESS" 0
            SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:✅ WSL2 installed successfully"
            Call UpdatePhaseProgress "Installing WSL2 components" "completed"
            Call StartAlpineInstallationPhase
        ${ElseIf} ${StrLoc} "$1" "REBOOT_REQUIRED" 0
            SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:🔄 WSL2 installed - reboot required"
            Call UpdatePhaseProgress "Installing WSL2 components" "completed"
            Call HandleRebootRequired
        ${Else}
            StrCpy $2 $1 "" 7  ; Remove "FAILED:" prefix
            SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:❌ WSL2 installation failed: $2"
            Call UpdatePhaseProgress "Installing WSL2 components" "failed"
            Call HandleInstallationError "WSL2 installation failed" "$2"
        ${EndIf}
    ${Else}
        SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:❌ WSL2 installation error"
        Call UpdatePhaseProgress "Installing WSL2 components" "failed"
        Call HandleInstallationError "WSL2 installation error" "PowerShell execution failed"
    ${EndIf}
FunctionEnd

; Phase 3: Alpine Linux Installation
Function StartAlpineInstallationPhase
    StrCpy $CurrentPhase "Alpine Linux Setup"
    ${NSD_SetText} $PhaseLabel "Phase: Alpine Linux Setup"
    ${NSD_SetText} $CurrentStatusLabel "Installing and configuring Alpine Linux..."
    
    Call CompletePhaseProgress "WSL2 Installation"
    Call StartPhaseProgress "Alpine Linux Setup" 3
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:🏔️ Phase 3: Alpine Linux Setup"
    
    Call InstallAlpineLinux
FunctionEnd

Function InstallAlpineLinux
    Call UpdatePhaseProgress "Installing Alpine Linux distribution" "starting"
    
    ; Run Alpine installation with progress integration
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\" -Force; Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; $result = Install-AlpineLinux -SetAsDefault -SkipIfExists -Username \"claude\"; if ($result.Success) { Write-Output \"SUCCESS\" } else { Write-Output \"FAILED:$($result.Message)\" }"'
    Pop $0
    Pop $1
    
    ${If} $0 == 0
        ${If} ${StrLoc} "$1" "SUCCESS" 0
            SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:✅ Alpine Linux configured successfully"
            Call UpdatePhaseProgress "Installing Alpine Linux distribution" "completed"
            Call StartClaudeCodeInstallationPhase
        ${Else}
            StrCpy $2 $1 "" 7  ; Remove "FAILED:" prefix
            SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:❌ Alpine Linux installation failed: $2"
            Call UpdatePhaseProgress "Installing Alpine Linux distribution" "failed"
            Call HandleInstallationError "Alpine Linux installation failed" "$2"
        ${EndIf}
    ${Else}
        SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:❌ Alpine Linux installation error"
        Call UpdatePhaseProgress "Installing Alpine Linux distribution" "failed"
        Call HandleInstallationError "Alpine Linux installation error" "PowerShell execution failed"
    ${EndIf}
FunctionEnd

; Phase 4: Claude Code Installation
Function StartClaudeCodeInstallationPhase
    StrCpy $CurrentPhase "Claude Code Installation"
    ${NSD_SetText} $PhaseLabel "Phase: Claude Code Installation"
    ${NSD_SetText} $CurrentStatusLabel "Installing Claude Code CLI..."
    
    Call CompletePhaseProgress "Alpine Linux Setup"
    Call StartPhaseProgress "Claude Code Installation" 2
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:🤖 Phase 4: Claude Code Installation"
    
    Call InstallClaudeCode
FunctionEnd

Function InstallClaudeCode
    Call UpdatePhaseProgress "Installing Claude Code CLI" "starting"
    
    ; Install Claude Code via npm in Alpine
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "wsl -d Alpine -- sh -c \"npm install -g @anthropic-ai/claude-code && claude --version\""'
    Pop $0
    Pop $1
    
    ${If} $0 == 0
        SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:✅ Claude Code CLI installed: $1"
        Call UpdatePhaseProgress "Installing Claude Code CLI" "completed"
        Call FinalizeInstallation
    ${Else}
        SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:❌ Claude Code installation failed"
        Call UpdatePhaseProgress "Installing Claude Code CLI" "failed"
        Call HandleInstallationError "Claude Code installation failed" "NPM installation failed"
    ${EndIf}
FunctionEnd

; Finalize installation
Function FinalizeInstallation
    Call CompletePhaseProgress "Claude Code Installation"
    
    ${NSD_SetText} $CurrentStatusLabel "Installation completed successfully!"
    ${NSD_SetText} $PhaseLabel "Installation Complete"
    
    ; Update progress to 100%
    SendMessage $MainProgressBar ${PBM_SETPOS} 100 0
    SendMessage $PhaseProgressBar ${PBM_SETPOS} 100 0
    
    ; Add completion messages
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:🎉 Claude Code installation completed!"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:✅ WSL2 configured and running"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:✅ Alpine Linux ready for development"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:✅ Claude Code CLI available"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:💡 Usage: Open WSL terminal and run 'claude --help'"
    
    ; Calculate total installation time
    System::Call 'kernel32::GetTickCount() i .r$R0'
    IntOp $R1 $R0 - $InstallationStartTime
    IntOp $R1 $R1 / 1000  ; Convert to seconds
    IntOp $R2 $R1 / 60    ; Minutes
    IntOp $R3 $R1 % 60    ; Remaining seconds
    
    ${NSD_SetText} $TimeEstimateLabel "Total installation time: $R2 minutes, $R3 seconds"
    
    ; Change cancel button to finish
    ${NSD_SetText} $CancelButton "&Finish"
    
    StrCpy $InstallationInProgress "false"
    DetailPrint "Claude Code installation completed successfully"
FunctionEnd

; Progress tracking helper functions
Function StartPhaseProgress
    Pop $R1  ; Phase steps
    Pop $R0  ; Phase name
    
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; Start-InstallationPhase \"$R0\" -PhaseSteps $R1"'
    Pop $0
    Pop $1
    
    ; Reset phase progress bar
    SendMessage $PhaseProgressBar ${PBM_SETPOS} 0 0
FunctionEnd

Function CompletePhaseProgress
    Pop $R0  ; Phase name
    
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; Complete-InstallationPhase \"$R0\""'
    Pop $0
    Pop $1
    
    ; Set phase progress to 100%
    SendMessage $PhaseProgressBar ${PBM_SETPOS} 100 0
FunctionEnd

Function UpdatePhaseProgress
    Pop $R1  ; Status
    Pop $R0  ; Step name
    
    ; Update progress tracking
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; $result = Update-InstallationProgress \"$R0\" \"$R1\"; Write-Output \"$($result.progress),$($result.estimatedTimeRemaining)\""'
    Pop $0
    Pop $1
    
    ${If} $0 == 0
        ; Parse progress and time estimate
        ${StrLoc} $R2 "$1" "," 0
        ${If} $R2 != ""
            StrCpy $R3 $1 $R2          ; Progress percentage
            IntOp $R4 $R2 + 1
            StrCpy $R5 $1 "" $R4       ; Time remaining
            
            ; Update progress bars
            SendMessage $MainProgressBar ${PBM_SETPOS} $R3 0
            
            ; Update time estimate
            ${If} $R5 != ""
            ${AndIf} $R5 != "null"
                IntOp $R6 $R5 / 60     ; Minutes
                IntOp $R7 $R5 % 60     ; Seconds
                ${NSD_SetText} $TimeEstimateLabel "Estimated time remaining: $R6 minutes, $R7 seconds"
            ${EndIf}
        ${EndIf}
    ${EndIf}
FunctionEnd

; Error handling functions
Function HandleInstallationError
    Pop $R1  ; Error details
    Pop $R0  ; Error title
    
    ${NSD_SetText} $CurrentStatusLabel "Installation failed: $R0"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:💥 Installation Error: $R0"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:   Details: $R1"
    
    MessageBox MB_OK|MB_ICONERROR "Installation Failed$\n$\n$R0$\n$\nDetails: $R1$\n$\nPlease check the installation log for more information."
    
    ; Change cancel button to exit
    ${NSD_SetText} $CancelButton "&Exit"
    StrCpy $InstallationInProgress "false"
FunctionEnd

Function HandleRebootRequired
    ${NSD_SetText} $CurrentStatusLabel "Reboot required to continue installation"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:🔄 System reboot required"
    SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:   Installation will continue after reboot"
    
    MessageBox MB_YESNO|MB_ICONQUESTION "A system reboot is required to complete WSL2 installation.$\n$\nThe installer will automatically continue after reboot.$\n$\nReboot now?" IDYES RebootNow IDNO RebootLater
    
    RebootNow:
        ; Schedule continuation and reboot
        Call ScheduleInstallationContinuation
        Reboot
        
    RebootLater:
        MessageBox MB_OK|MB_ICONINFORMATION "Please reboot your system and run the installer again to complete the installation."
        ${NSD_SetText} $CancelButton "&Exit"
        StrCpy $InstallationInProgress "false"
FunctionEnd

Function ScheduleInstallationContinuation
    ; Use our existing reboot continuation system
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ClaudeCodeInstaller.psm1\" -Force; Request-RebootWithContinuation -InstallerPath \"$EXEPATH\" -ContinuationPhase \"PostWSLReboot\""'
    Pop $0
    Pop $1
FunctionEnd

; Button click handlers
Function OnCancelInstallation
    ${If} $InstallationInProgress == "true"
        MessageBox MB_YESNO|MB_ICONQUESTION "Are you sure you want to cancel the installation?" IDYES CancelInstall IDNO ContinueInstall
        
        CancelInstall:
            ; Clean up progress tracking
            nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; Clear-ProgressTracking"'
            Pop $0
            Pop $1
            
            SendMessage $InstallationList ${LB_ADDSTRING} 0 "STR:❌ Installation cancelled by user"
            ${NSD_SetText} $CurrentStatusLabel "Installation cancelled"
            StrCpy $InstallationInProgress "false"
            Abort
            
        ContinueInstall:
            Return
    ${Else}
        ; Installation complete or failed - close installer
        Return
    ${EndIf}
FunctionEnd

; Page leave function
Function InstallationProgressPageLeave
    ; Clean up progress tracking
    nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\\scripts\\powershell\\ProgressTracker.psm1\" -Force; Clear-ProgressTracking"'
    Pop $0
    Pop $1
FunctionEnd