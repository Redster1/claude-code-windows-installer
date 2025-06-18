; Claude Code Windows Installer
; NSIS Script for automated WSL2 + Claude Code installation
; Designed for non-technical users (lawyers, etc.)

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"
!include "WinVer.nsh"
!include "FileFunc.nsh"
!include "nsDialogs.nsh"

; Installer configuration
Name "Claude Code for Windows"
OutFile "${DIST_DIR}\ClaudeCodeSetup.exe"
InstallDir "$LOCALAPPDATA\ClaudeCode"
RequestExecutionLevel admin

; Version information
!ifndef VERSION
  !define VERSION "1.0.0"
!endif

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "Claude Code for Windows"
VIAddVersionKey "CompanyName" "Claude Code Installer Project"
VIAddVersionKey "LegalCopyright" "© 2024 Claude Code Installer Project"
VIAddVersionKey "FileDescription" "Claude Code Windows Installer"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"

; Modern UI Configuration
!define MUI_ABORTWARNING
; Assets commented out for testing
; !define MUI_ICON "${ASSETS_DIR}\claude-icon.ico"
; !define MUI_WELCOMEFINISHPAGE_BITMAP "${ASSETS_DIR}\wizard-sidebar.bmp" 
; !define MUI_UNWELCOMEFINISHPAGE_BITMAP "${ASSETS_DIR}\wizard-sidebar.bmp"

; Interface Settings
; !define MUI_HEADERIMAGE
; !define MUI_HEADERIMAGE_BITMAP "${ASSETS_DIR}\wizard-header.bmp"
; !define MUI_HEADERIMAGE_RIGHT

; Pages
!insertmacro MUI_PAGE_WELCOME

; Custom dependency check page
Page custom DependencyCheckPage DependencyCheckPageLeave

; Custom installation progress page  
Page custom InstallationProgressPage InstallationProgressPageLeave

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Languages
!insertmacro MUI_LANGUAGE "English"

; Global variables for UI
Var DependencyDialog
Var DependencyListBox
Var DependencyStatusLabel
Var DependencyProgressBar
Var ProgressDialog
Var ProgressBar
Var ProgressStatusLabel
Var CurrentOperation

; System status variables
Var WindowsVersion
Var NodeJSStatus  
Var GitStatus
Var CurlStatus
Var ClaudeStatus

; Installation settings
Var SkipWSL2
Var SkipNodeJS
Var SkipGit
Var SkipCurl
Var SkipClaude
Var RebootRequired

; Custom page functions
Function DependencyCheckPage
  !insertmacro MUI_HEADER_TEXT "System Dependencies" "Checking your system for required components..."
  
  nsDialogs::Create 1018
  Pop $DependencyDialog
  
  ${If} $DependencyDialog == error
    Abort
  ${EndIf}
  
  ; Status label
  ${NSD_CreateLabel} 0 0 100% 20u "Scanning system for existing dependencies..."
  Pop $DependencyStatusLabel
  
  ; Progress bar
  ${NSD_CreateProgressBar} 0 30u 100% 12u ""
  Pop $DependencyProgressBar
  SendMessage $DependencyProgressBar ${PBM_SETRANGE} 0 0x640064
  
  ; Results list
  ${NSD_CreateListBox} 0 50u 100% 120u ""
  Pop $DependencyListBox
  
  ; Start dependency check
  Call CheckDependenciesAsync
  
  nsDialogs::Show
FunctionEnd

Function DependencyCheckPageLeave
  ; Process dependency check results
  Call ProcessDependencyResults
FunctionEnd

Function CheckDependenciesAsync
  ; Update progress
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 10 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:🔍 Starting dependency scan..."
  
  ; Check WSL2
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 20 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   Checking WSL2..."
  nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux | Select-Object -ExpandProperty State"'
  Pop $0 ; Exit code
  Pop $1 ; Result
  ${If} $0 == 0
  ${AndIf} $1 == "Enabled"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ WSL2 found and enabled"
    StrCpy $SkipWSL2 "true"
  ${Else}
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ WSL2 not found or disabled"
    StrCpy $SkipWSL2 "false"
  ${EndIf}
  
  ; Check Node.js
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 40 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   Checking Node.js..."
  nsExec::ExecToStack 'node --version 2>nul'
  Pop $0
  ${If} $0 == 0
    Pop $NodeJSStatus
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Node.js found: $NodeJSStatus"
    StrCpy $SkipNodeJS "true"
  ${Else}
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ Node.js not found"
    StrCpy $SkipNodeJS "false"
  ${EndIf}
  
  ; Check Git
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 60 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   Checking Git..."
  nsExec::ExecToStack 'git --version 2>nul'
  Pop $0
  ${If} $0 == 0
    Pop $GitStatus
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Git found: $GitStatus"
    StrCpy $SkipGit "true"
  ${Else}
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ Git not found"
    StrCpy $SkipGit "false"
  ${EndIf}
  
  ; Check Curl  
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 80 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   Checking Curl..."
  nsExec::ExecToStack 'curl --version 2>nul'
  Pop $0
  ${If} $0 == 0
    Pop $CurlStatus
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Curl found"
    StrCpy $SkipCurl "true"
  ${Else}
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ Curl not found"
    StrCpy $SkipCurl "false"
  ${EndIf}
  
  ; Check Claude Code
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 90 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   Checking Claude Code..."
  nsExec::ExecToStack 'claude --version 2>nul'
  Pop $0
  ${If} $0 == 0
    Pop $ClaudeStatus
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Claude Code found: $ClaudeStatus"
    StrCpy $SkipClaude "true"
  ${Else}
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ Claude Code not found"
    StrCpy $SkipClaude "false"
  ${EndIf}
  
  ; Complete
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 100 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:✅ Dependency scan completed"
  
  ${NSD_SetText} $DependencyStatusLabel "Dependency scan completed. Review results above."
FunctionEnd

Function ProcessDependencyResults
  ; Calculate installation time estimate
  StrCpy $0 0 ; Component counter
  
  ${If} $SkipWSL2 == "false"
    IntOp $0 $0 + 1
  ${EndIf}
  ${If} $SkipNodeJS == "false"
    IntOp $0 $0 + 1
  ${EndIf}
  ${If} $SkipClaude == "false"
    IntOp $0 $0 + 1
  ${EndIf}
  
  ; Estimate 3 minutes per component + base time
  IntOp $1 $0 * 3
  IntOp $1 $1 + 2
  
  IntOp $2 $1 + 3
  MessageBox MB_YESNO|MB_ICONQUESTION "Ready to install Claude Code.$\n$\nComponents to install: $0$\nEstimated time: $1-$2 minutes$\n$\nContinue with installation?" IDYES +2
  Abort
FunctionEnd

Function InstallationProgressPage
  !insertmacro MUI_HEADER_TEXT "Installing Claude Code" "Please wait while Claude Code is installed and configured..."
  
  nsDialogs::Create 1018
  Pop $ProgressDialog
  
  ${If} $ProgressDialog == error
    Abort
  ${EndIf}
  
  ; Progress bar
  ${NSD_CreateProgressBar} 0 30u 100% 15u ""
  Pop $ProgressBar
  SendMessage $ProgressBar ${PBM_SETRANGE} 0 0x640064
  
  ; Status label
  ${NSD_CreateLabel} 0 0 100% 20u "Preparing installation..."
  Pop $ProgressStatusLabel
  
  ; Current operation label
  ${NSD_CreateLabel} 0 50u 100% 20u ""
  Pop $CurrentOperation
  
  nsDialogs::Show
FunctionEnd

Function InstallationProgressPageLeave
FunctionEnd

; Main installer section
Section "Claude Code Installation" SecMain
  SetOutPath "$INSTDIR"
  
  ; Initialize installation
  DetailPrint "Starting Claude Code installation"
  
  ; Extract installer files (commented out for testing)
  ; File /r "${BUILD_DIR}/scripts/*"
  ; File /r "${BUILD_DIR}/config/*"
  
  ; Start installation process
  Call PerformInstallation
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Registry entries for Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "DisplayName" "Claude Code for Windows"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "DisplayIcon" "$INSTDIR\claude-icon.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "Publisher" "Claude Code Installer Project"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "NoRepair" 1
  
  ; Create shortcuts (commented out for testing)
  ; Call CreateShortcuts
  
SectionEnd

; Installation functions
Function PerformInstallation
  ; Update progress page
  ${NSD_SetText} $ProgressStatusLabel "Installing Claude Code components..."
  ${NSD_SetText} $CurrentOperation "Simulating installation for testing..."
  SendMessage $ProgressBar ${PBM_SETPOS} 50 0
  
  DetailPrint "Installation simulation - UI testing mode"
  DetailPrint "This is a test build to validate the UI"
  DetailPrint "Full automation will be enabled in production build"
  
  ; Complete progress
  ${NSD_SetText} $ProgressStatusLabel "Installation completed successfully!"
  ${NSD_SetText} $CurrentOperation "Claude Code is ready to use."
  SendMessage $ProgressBar ${PBM_SETPOS} 100 0
FunctionEnd

Function CreateShortcuts
  DetailPrint "Creating shortcuts..."
FunctionEnd

; Uninstaller section
Section "Uninstall"
  ; Remove files
  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR"
  
  ; Remove registry entries
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode"
SectionEnd

Function .onInit
  ; Detect Windows version
  ${WinVerGetMajor} $R0
  ${WinVerGetMinor} $R1
  ${WinVerGetBuild} $R2
  StrCpy $WindowsVersion "$R0.$R1 (Build $R2)"
  
  ; Basic compatibility check
  ${IfNot} ${AtLeastWin10}
    MessageBox MB_OK|MB_ICONSTOP "This installer requires Windows 10 or later."
    Abort
  ${EndIf}
  
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "This installer requires 64-bit Windows."
    Abort
  ${EndIf}
  
  ; Check for admin rights
  UserInfo::GetAccountType
  Pop $0
  ${If} $0 != "Admin"
    MessageBox MB_OK|MB_ICONSTOP "This installer requires administrator privileges.$\nPlease run as administrator."
    Abort
  ${EndIf}
  
  ; Initialize variables
  StrCpy $RebootRequired "false"
  StrCpy $SkipWSL2 "false"
  StrCpy $SkipNodeJS "false"
  StrCpy $SkipGit "false"
  StrCpy $SkipCurl "false"
  StrCpy $SkipClaude "false"
FunctionEnd