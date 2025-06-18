; Claude Code Windows Installer
; NSIS Script for automated WSL2 + Claude Code installation
; Designed for non-technical users (lawyers, etc.)

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"
!include "WinVer.nsh"
!include "FileFunc.nsh"

; Include our custom UI pages
!include "ui\dependency-check.nsh"
!include "ui\installation-progress.nsh"
!include "ui\error-handler.nsh"

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
!define MUI_ICON "${ASSETS_DIR}\claude-icon.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${ASSETS_DIR}\wizard-sidebar.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${ASSETS_DIR}\wizard-sidebar.bmp"

; Interface Settings
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${ASSETS_DIR}\wizard-header.bmp"
!define MUI_HEADERIMAGE_RIGHT

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

; Global variables
Var DependencyDialog
Var DependencyListBox
Var DependencyStatusLabel
Var ProgressDialog
Var ProgressBar
Var ProgressStatusLabel
Var CurrentOperation
Var InstallationPhase
Var RebootRequired

; Dependencies detection results
Var WSL2Status
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

; Main installer section
Section "Claude Code Installation" SecMain
  SetOutPath "$INSTDIR"
  
  ; Initialize error handling system
  Call InitializeErrorHandling
  !insertmacro LogInfo "Starting Claude Code installation"
  
  ; Extract installer files
  File /r "${BUILD_DIR}\scripts"
  File /r "${BUILD_DIR}\config"
  
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
  
  ; Create shortcuts
  Call CreateShortcuts
  
SectionEnd

; Dependency Check Page
Function DependencyCheckPage
  !insertmacro MUI_HEADER_TEXT "Checking System Dependencies" "Please wait while we scan your system for existing components..."
  
  nsDialogs::Create 1018
  Pop $DependencyDialog
  
  ${If} $DependencyDialog == error
    Abort
  ${EndIf}
  
  ; Status label
  ${NSD_CreateLabel} 0 0 100% 20u "Scanning system for existing dependencies..."
  Pop $DependencyStatusLabel
  
  ; Progress bar for dependency check
  ${NSD_CreateProgressBar} 0 30u 100% 12u ""
  Pop $ProgressBar
  
  ; List box for dependency results
  ${NSD_CreateListBox} 0 50u 100% 120u ""
  Pop $DependencyListBox
  
  ; Start dependency detection
  GetFunctionAddress $0 CheckDependenciesAsync
  
  nsDialogs::Show
FunctionEnd

Function DependencyCheckPageLeave
  ; Process dependency check results
  Call ProcessDependencyResults
FunctionEnd

Function CheckDependenciesAsync
  ; Update progress
  SendMessage $ProgressBar ${PBM_SETPOS} 10 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:🔍 Starting dependency scan..."
  
  ; Run PowerShell dependency detection
  SetDetailsPrint none
  
  ; Check WSL2
  SendMessage $ProgressBar ${PBM_SETPOS} 20 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   Checking WSL2..."
  nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\scripts\powershell\ClaudeCodeInstaller.psm1\"; Test-WSL2Installation | ConvertTo-Json"'
  Pop $0 ; Exit code
  Pop $WSL2Status ; JSON result
  
  ; Check Node.js
  SendMessage $ProgressBar ${PBM_SETPOS} 40 0
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
  SendMessage $ProgressBar ${PBM_SETPOS} 60 0
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
  SendMessage $ProgressBar ${PBM_SETPOS} 80 0
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
  SendMessage $ProgressBar ${PBM_SETPOS} 90 0
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
  SendMessage $ProgressBar ${PBM_SETPOS} 100 0
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
  
  MessageBox MB_YESNO|MB_ICONQUESTION "Ready to install Claude Code.$\n$\nComponents to install: $0$\nEstimated time: $1-$($1+3) minutes$\n$\nContinue with installation?" IDYES +2
  Abort
FunctionEnd

; Installation Progress Page
Function InstallProgressPage
  !insertmacro MUI_HEADER_TEXT "Installing Claude Code" "Please wait while Claude Code is installed and configured..."
  
  nsDialogs::Create 1018
  Pop $ProgressDialog
  
  ${If} $ProgressDialog == error
    Abort
  ${EndIf}
  
  ; Progress bar
  ${NSD_CreateProgressBar} 0 30u 100% 15u ""
  Pop $ProgressBar
  
  ; Status label
  ${NSD_CreateLabel} 0 0 100% 20u "Preparing installation..."
  Pop $ProgressStatusLabel
  
  ; Current operation label
  ${NSD_CreateLabel} 0 50u 100% 20u ""
  Pop $CurrentOperation
  
  nsDialogs::Show
FunctionEnd

Function PerformInstallation
  StrCpy $InstallationPhase "WSL2"
  
  ; Phase 1: WSL2 Installation
  ${If} $SkipWSL2 == "false"
    Call InstallWSL2Phase
  ${EndIf}
  
  ; Phase 2: Alpine Linux
  Call InstallAlpinePhase
  
  ; Phase 3: Node.js (if needed)
  ${If} $SkipNodeJS == "false"
    Call InstallNodeJSPhase
  ${EndIf}
  
  ; Phase 4: Claude Code
  ${If} $SkipClaude == "false"
    Call InstallClaudeCodePhase
  ${EndIf}
  
  ; Phase 5: Configuration
  Call ConfigurationPhase
  
FunctionEnd

Function InstallWSL2Phase
  ${NSD_SetText} $ProgressStatusLabel "Installing Windows Subsystem for Linux 2..."
  ${NSD_SetText} $CurrentOperation "Enabling Windows features..."
  SendMessage $ProgressBar ${PBM_SETPOS} 10 0
  
  ; Use PowerShell module to install WSL2
  nsExec::ExecToLog 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\scripts\powershell\ClaudeCodeInstaller.psm1\"; Install-WSL2"'
  Pop $0
  
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "WSL2 installation failed. Please check the installation log."
    Abort
  ${EndIf}
  
  ; Check if reboot is required
  nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\scripts\powershell\ClaudeCodeInstaller.psm1\"; Test-RebootRequired"'
  Pop $0
  Pop $1
  
  ${If} $1 == "True"
    StrCpy $RebootRequired "true"
  ${EndIf}
  
FunctionEnd

Function InstallAlpinePhase
  ${NSD_SetText} $ProgressStatusLabel "Installing Alpine Linux distribution..."
  ${NSD_SetText} $CurrentOperation "Downloading and configuring Alpine Linux..."
  SendMessage $ProgressBar ${PBM_SETPOS} 40 0
  
  nsExec::ExecToLog 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\scripts\powershell\ClaudeCodeInstaller.psm1\"; Install-AlpineLinux -SetAsDefault"'
  Pop $0
  
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "Alpine Linux installation failed. Please check the installation log."
    Abort
  ${EndIf}
  
FunctionEnd

Function InstallNodeJSPhase
  ${NSD_SetText} $ProgressStatusLabel "Installing Node.js and npm..."
  ${NSD_SetText} $CurrentOperation "Setting up Node.js environment in Alpine Linux..."
  SendMessage $ProgressBar ${PBM_SETPOS} 60 0
  
  ; Run Alpine setup script
  nsExec::ExecToLog 'wsl -d Alpine -- sh /mnt/c/Users/$USERNAME/AppData/Local/ClaudeCode/scripts/bash/alpine-setup.sh'
  Pop $0
  
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "Node.js installation failed. Please check the installation log."
    Abort
  ${EndIf}
  
FunctionEnd

Function InstallClaudeCodePhase
  ${NSD_SetText} $ProgressStatusLabel "Installing Claude Code CLI..."
  ${NSD_SetText} $CurrentOperation "Installing Claude Code via npm..."
  SendMessage $ProgressBar ${PBM_SETPOS} 80 0
  
  ; Install Claude Code via npm in Alpine
  nsExec::ExecToLog 'wsl -d Alpine -- npm install -g @anthropic-ai/claude-code'
  Pop $0
  
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "Claude Code installation failed. Please check the installation log."
    Abort
  ${EndIf}
  
FunctionEnd

Function ConfigurationPhase
  ${NSD_SetText} $ProgressStatusLabel "Finalizing configuration..."
  ${NSD_SetText} $CurrentOperation "Creating shortcuts and registry entries..."
  SendMessage $ProgressBar ${PBM_SETPOS} 90 0
  
  ; Verify installation
  nsExec::ExecToStack 'wsl -d Alpine -- claude --version'
  Pop $0
  Pop $1
  
  ${If} $0 == 0
    ${NSD_SetText} $ProgressStatusLabel "Installation completed successfully!"
    ${NSD_SetText} $CurrentOperation "Claude Code $1 is ready to use."
    SendMessage $ProgressBar ${PBM_SETPOS} 100 0
  ${Else}
    MessageBox MB_OK|MB_ICONSTOP "Installation verification failed. Claude Code may not be working properly."
  ${EndIf}
  
FunctionEnd

Function CreateShortcuts
  ; Create desktop shortcut
  CreateShortCut "$DESKTOP\Claude Code.lnk" "wsl" "-d Alpine claude" "$INSTDIR\claude-icon.ico"
  
  ; Create Start Menu shortcut
  CreateDirectory "$SMPROGRAMS\Claude Code"
  CreateShortCut "$SMPROGRAMS\Claude Code\Claude Code.lnk" "wsl" "-d Alpine claude" "$INSTDIR\claude-icon.ico"
  CreateShortCut "$SMPROGRAMS\Claude Code\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  
FunctionEnd

; Uninstaller section
Section "Uninstall"
  ; Remove shortcuts
  Delete "$DESKTOP\Claude Code.lnk"
  RMDir /r "$SMPROGRAMS\Claude Code"
  
  ; Remove registry entries
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode"
  
  ; Remove installation directory
  RMDir /r "$INSTDIR"
  
  ; Note: We don't remove WSL2, Alpine, or other dependencies as they might be used by other applications
  
SectionEnd

; Installer initialization
Function .onInit
  ; Check if running on supported Windows version
  ${IfNot} ${AtLeastWin10}
    MessageBox MB_OK|MB_ICONSTOP "This installer requires Windows 10 or later."
    Abort
  ${EndIf}
  
  ; Check for x64 architecture
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "This installer requires a 64-bit version of Windows."
    Abort
  ${EndIf}
  
  ; Check for administrator privileges
  UserInfo::GetAccountType
  Pop $0
  ${If} $0 != "Admin"
    MessageBox MB_OK|MB_ICONSTOP "This installer requires administrator privileges. Please right-click and select 'Run as administrator'."
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