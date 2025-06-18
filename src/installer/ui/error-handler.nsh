; Claude Code Windows Installer - Error Handling UI System
; Professional error dialogs with detailed information and recovery options

!include "nsDialogs.nsh"
!include "LogicLib.nsh"

; Error dialog variables
Var ErrorDialog
Var ErrorIcon
Var ErrorTitle
Var ErrorMessage
Var ErrorDetails
Var ErrorCode
Var ErrorDetailsBox
Var ErrorLogButton
Var ErrorRetryButton
Var ErrorSkipButton
Var ErrorExitButton
Var ShowingDetails

; Error logging
Var LogFile

; Initialize error handling system
Function InitializeErrorHandling
    StrCpy $LogFile "$INSTDIR\install.log"
    StrCpy $ShowingDetails "false"
    
    ; Create log file header
    FileOpen $0 $LogFile w
    FileWrite $0 "Claude Code Windows Installer - Installation Log$\r$\n"
    FileWrite $0 "Started: $(^Time) $(^Date)$\r$\n"
    FileWrite $0 "Windows Version: $WindowsVersion$\r$\n"
    FileWrite $0 "Install Directory: $INSTDIR$\r$\n"
    FileWrite $0 "======================================$\r$\n$\r$\n"
    FileClose $0
FunctionEnd

; Main error display macro
!macro ShowError ErrorTitle ErrorMessage ErrorCode
    Push "${ErrorTitle}"
    Push "${ErrorMessage}"
    Push "${ErrorCode}"
    Call DisplayErrorDialog
!macroend

; Display comprehensive error dialog
Function DisplayErrorDialog
    Pop $R2  ; Error code
    Pop $R1  ; Error message
    Pop $R0  ; Error title
    
    ; Log the error
    Call LogError "$R0" "$R1" "$R2"
    
    ; Create error dialog
    nsDialogs::Create 1018
    Pop $ErrorDialog
    
    ${If} $ErrorDialog == error
        ; Fallback to simple message box
        MessageBox MB_OK|MB_ICONERROR "$R0$\n$\n$R1$\n$\nError Code: $R2"
        Return
    ${EndIf}
    
    ; Store error information
    StrCpy $ErrorTitle "$R0"
    StrCpy $ErrorMessage "$R1"
    StrCpy $ErrorCode "$R2"
    
    ; Create error icon
    ${NSD_CreateIcon} 10u 10u 32u 32u ""
    Pop $ErrorIcon
    ${NSD_SetIconFromInstaller} $ErrorIcon "shell32.dll" 16  ; Error icon
    
    ; Error title
    ${NSD_CreateLabel} 50u 10u 85% 20u "$R0"
    Pop $R3
    CreateFont $R4 "MS Shell Dlg" 12 700  ; Bold font
    SendMessage $R3 ${WM_SETFONT} $R4 0
    
    ; Error message
    ${NSD_CreateLabel} 50u 35u 85% 40u "$R1"
    Pop $R3
    
    ; Error code
    ${NSD_CreateLabel} 50u 80u 85% 15u "Error Code: $R2"
    Pop $R3
    CreateFont $R4 "MS Shell Dlg" 8 400  ; Smaller font
    SendMessage $R3 ${WM_SETFONT} $R4 0
    
    ; Details section (initially hidden)
    ${NSD_CreateGroupBox} 10u 105u 95% 60u "Error Details"
    Pop $R3
    ShowWindow $R3 ${SW_HIDE}
    
    ${NSD_CreateText} 15u 120u 90% 40u ""
    Pop $ErrorDetailsBox
    SendMessage $ErrorDetailsBox ${EM_SETREADONLY} 1 0
    ShowWindow $ErrorDetailsBox ${SW_HIDE}
    
    ; Buttons
    ${NSD_CreateButton} 10u 175u 60u 15u "Show &Details"
    Pop $ErrorLogButton
    ${NSD_OnClick} $ErrorLogButton OnShowErrorDetails
    
    ${NSD_CreateButton} 80u 175u 60u 15u "&Retry"
    Pop $ErrorRetryButton
    ${NSD_OnClick} $ErrorRetryButton OnRetryOperation
    
    ${NSD_CreateButton} 150u 175u 60u 15u "&Skip"
    Pop $ErrorSkipButton
    ${NSD_OnClick} $ErrorSkipButton OnSkipOperation
    
    ${NSD_CreateButton} 220u 175u 60u 15u "E&xit"
    Pop $ErrorExitButton
    ${NSD_OnClick} $ErrorExitButton OnExitInstaller
    
    ; Populate details with diagnostic information
    Call GatherErrorDetails
    
    ; Set window title
    FindWindow $R3 "#32770" "" $HWNDPARENT
    ${If} $R3 != 0
        SendMessage $R3 ${WM_SETTEXT} 0 "STR:Claude Code Installer - Error"
    ${EndIf}
    
    nsDialogs::Show
FunctionEnd

; Gather detailed error information
Function GatherErrorDetails
    ; Get system information
    StrCpy $R0 "System Information:$\r$\n"
    StrCpy $R0 "$R0OS: $WindowsVersion$\r$\n"
    StrCpy $R0 "$R0Architecture: $PROGRAMFILES64$\r$\n"
    StrCpy $R0 "$R0Install Directory: $INSTDIR$\r$\n"
    StrCpy $R0 "$R0Temp Directory: $TEMP$\r$\n"
    StrCpy $R0 "$R0$\r$\n"
    
    ; Get WSL status
    StrCpy $R0 "$R0WSL Status:$\r$\n"
    nsExec::ExecToStack 'powershell.exe -Command "wsl --status" 2>&1'
    Pop $R1  ; Exit code
    Pop $R2  ; Output
    ${If} $R1 == 0
        StrCpy $R0 "$R0$R2$\r$\n"
    ${Else}
        StrCpy $R0 "$R0WSL not available or not configured$\r$\n"
    ${EndIf}
    StrCpy $R0 "$R0$\r$\n"
    
    ; Get PowerShell version
    StrCpy $R0 "$R0PowerShell Version:$\r$\n"
    nsExec::ExecToStack 'powershell.exe -Command "$PSVersionTable.PSVersion" 2>&1'
    Pop $R1
    Pop $R2
    ${If} $R1 == 0
        StrCpy $R0 "$R0$R2$\r$\n"
    ${Else}
        StrCpy $R0 "$R0PowerShell not available$\r$\n"
    ${EndIf}
    StrCpy $R0 "$R0$\r$\n"
    
    ; Get recent log entries
    StrCpy $R0 "$R0Recent Log Entries:$\r$\n"
    ${If} ${FileExists} $LogFile
        FileOpen $R3 $LogFile r
        StrCpy $R4 ""
        StrCpy $R5 0
        
        ReadLoop:
            FileRead $R3 $R6
            ${If} ${Errors}
                FileClose $R3
                ${ExitDo}
            ${EndIf}
            IntOp $R5 $R5 + 1
            ${If} $R5 > 50  ; Only show last 50 lines
                StrCpy $R4 "$R4$R6"
            ${EndIf}
            ${DoUntil} ${Errors}
        
        StrCpy $R0 "$R0$R4"
    ${Else}
        StrCpy $R0 "$R0No log file available$\r$\n"
    ${EndIf}
    
    ; Store details
    StrCpy $ErrorDetails "$R0"
FunctionEnd

; Show/hide error details
Function OnShowErrorDetails
    ${If} $ShowingDetails == "false"
        ; Show details
        StrCpy $ShowingDetails "true"
        ${NSD_SetText} $ErrorLogButton "Hide &Details"
        
        ; Show details controls
        GetDlgItem $R0 $ErrorDialog 1000  ; Group box
        ShowWindow $R0 ${SW_SHOW}
        ShowWindow $ErrorDetailsBox ${SW_SHOW}
        
        ; Populate details text box
        ${NSD_SetText} $ErrorDetailsBox $ErrorDetails
        
        ; Resize dialog
        System::Call 'user32::SetWindowPos(i $ErrorDialog, i 0, i 0, i 0, i 320, i 280, i 0x16)'
    ${Else}
        ; Hide details
        StrCpy $ShowingDetails "false"
        ${NSD_SetText} $ErrorLogButton "Show &Details"
        
        ; Hide details controls
        GetDlgItem $R0 $ErrorDialog 1000
        ShowWindow $R0 ${SW_HIDE}
        ShowWindow $ErrorDetailsBox ${SW_HIDE}
        
        ; Resize dialog back
        System::Call 'user32::SetWindowPos(i $ErrorDialog, i 0, i 0, i 0, i 320, i 220, i 0x16)'
    ${EndIf}
FunctionEnd

; Retry operation button
Function OnRetryOperation
    ; Close dialog and return to retry
    StrCpy $R9 "RETRY"
    SendMessage $ErrorDialog ${WM_CLOSE} 0 0
FunctionEnd

; Skip operation button
Function OnSkipOperation
    MessageBox MB_YESNO|MB_ICONQUESTION "Are you sure you want to skip this step?$\n$\nSkipping may cause the installation to fail or result in an incomplete setup." IDYES SkipConfirmed IDNO SkipCancelled
    
    SkipConfirmed:
        StrCpy $R9 "SKIP"
        SendMessage $ErrorDialog ${WM_CLOSE} 0 0
        Goto SkipEnd
    
    SkipCancelled:
        Return
        
    SkipEnd:
FunctionEnd

; Exit installer button
Function OnExitInstaller
    MessageBox MB_YESNO|MB_ICONQUESTION "Are you sure you want to exit the installer?" IDYES ExitConfirmed IDNO ExitCancelled
    
    ExitConfirmed:
        StrCpy $R9 "EXIT"
        SendMessage $ErrorDialog ${WM_CLOSE} 0 0
        Quit
        
    ExitCancelled:
        Return
FunctionEnd

; Log error to file
Function LogError
    Pop $R2  ; Error code
    Pop $R1  ; Error message
    Pop $R0  ; Error title
    
    ; Open log file for append
    FileOpen $R3 $LogFile a
    FileSeek $R3 0 END
    
    ; Write error entry
    FileWrite $R3 "[ERROR] $(^Time) - $R0$\r$\n"
    FileWrite $R3 "Message: $R1$\r$\n"
    FileWrite $R3 "Code: $R2$\r$\n"
    
    ; Add system context
    System::Call 'kernel32::GetLastError()i.R4'
    FileWrite $R3 "Windows Last Error: $R4$\r$\n"
    
    ; Add separator
    FileWrite $R3 "----------------------------------------$\r$\n$\r$\n"
    
    FileClose $R3
FunctionEnd

; Log warning message
!macro LogWarning Message
    Push "${Message}"
    Call LogWarningToFile
!macroend

Function LogWarningToFile
    Pop $R0  ; Warning message
    
    FileOpen $R1 $LogFile a
    FileSeek $R1 0 END
    FileWrite $R1 "[WARNING] $(^Time) - $R0$\r$\n$\r$\n"
    FileClose $R1
FunctionEnd

; Log info message
!macro LogInfo Message
    Push "${Message}"
    Call LogInfoToFile
!macroend

Function LogInfoToFile
    Pop $R0  ; Info message
    
    FileOpen $R1 $LogFile a
    FileSeek $R1 0 END
    FileWrite $R1 "[INFO] $(^Time) - $R0$\r$\n$\r$\n"
    FileClose $R1
FunctionEnd

; Show network error dialog
Function ShowNetworkError
    Push "Network Connection Error"
    Push "Unable to download required components. Please check your internet connection and firewall settings."
    Push "NET_001"
    Call DisplayErrorDialog
FunctionEnd

; Show WSL error dialog
Function ShowWSLError
    Push "WSL2 Installation Error"
    Push "Failed to install or configure Windows Subsystem for Linux 2. This may require administrator privileges or Windows updates."
    Push "WSL_001"
    Call DisplayErrorDialog
FunctionEnd

; Show permissions error dialog
Function ShowPermissionsError
    Push "Insufficient Permissions"
    Push "This installation requires administrator privileges. Please run the installer as an administrator."
    Push "PERM_001"
    Call DisplayErrorDialog
FunctionEnd

; Show disk space error dialog
Function ShowDiskSpaceError
    Push "Insufficient Disk Space"
    Push "There is not enough free disk space to complete the installation. Please free up at least 2GB of disk space."
    Push "DISK_001"
    Call DisplayErrorDialog
FunctionEnd

; Cleanup error handling
Function CleanupErrorHandling
    ; Close log file
    ${If} ${FileExists} $LogFile
        !insertmacro LogInfo "Installation completed"
        
        ; Optionally show log file location
        ${If} ${Silent}
            ; Silent install - don't show log info
        ${Else}
            DetailPrint "Installation log saved to: $LogFile"
        ${EndIf}
    ${EndIf}
FunctionEnd

; Get error code for common Windows errors
Function GetWindowsErrorDescription
    Pop $R0  ; Error code
    
    ${Switch} $R0
        ${Case} "0"
            StrCpy $R1 "Success"
            ${Break}
        ${Case} "2"
            StrCpy $R1 "File not found"
            ${Break}
        ${Case} "3"
            StrCpy $R1 "Path not found"
            ${Break}
        ${Case} "5"
            StrCpy $R1 "Access denied"
            ${Break}
        ${Case} "87"
            StrCpy $R1 "Invalid parameter"
            ${Break}
        ${Case} "1223"
            StrCpy $R1 "Operation cancelled by user"
            ${Break}
        ${Case} "1602"
            StrCpy $R1 "User cancelled installation"
            ${Break}
        ${Case} "1603"
            StrCpy $R1 "Fatal error during installation"
            ${Break}
        ${Case} "1618"
            StrCpy $R1 "Another installation is in progress"
            ${Break}
        ${Default}
            StrCpy $R1 "Unknown error (Code: $R0)"
            ${Break}
    ${EndSwitch}
    
    Push $R1
FunctionEnd