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
; Assets enabled with generated images
!define MUI_ICON "${ASSETS_DIR}/claude-icon.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${ASSETS_DIR}/wizard-sidebar.bmp" 
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${ASSETS_DIR}/wizard-sidebar.bmp"

; Interface Settings
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${ASSETS_DIR}/wizard-header.bmp"
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
  ; Initialize detection variables
  StrCpy $SkipWSL2 "false"
  StrCpy $SkipNodeJS "false"
  StrCpy $SkipGit "false"
  StrCpy $SkipCurl "false"
  StrCpy $SkipClaude "false"
  
  ; Update progress
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 5 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:🔍 Starting comprehensive dependency scan..."
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   Checking both Windows and WSL environments..."
  
  ; Check WSL2 using PowerShell module (most comprehensive)
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 15 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:📦 Checking WSL2 installation..."
  Call CheckWSL2Comprehensive
  
  ; Check Node.js in both Windows and WSL
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 30 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:📦 Checking Node.js (Windows + WSL)..."
  Call CheckNodeJSDual
  
  ; Check Git in both Windows and WSL
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 50 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:📦 Checking Git (Windows + WSL)..."
  Call CheckGitDual
  
  ; Check Curl in both Windows and WSL
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 70 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:📦 Checking Curl (Windows + WSL)..."
  Call CheckCurlDual
  
  ; Check Claude Code in both Windows and WSL (most important!)
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 85 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:🤖 Checking Claude Code (Windows + WSL)..."
  Call CheckClaudeCodeDual
  
  ; Complete scan
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 100 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:✅ Comprehensive dependency scan completed"
  
  ${NSD_SetText} $DependencyStatusLabel "Dependency scan completed. Review detailed results above."
FunctionEnd

Function CheckWSL2Comprehensive
  ; Direct WSL check (don't assume PowerShell modules exist on fresh install)
  nsExec::ExecToStack 'wsl --status 2>nul'
  Pop $0
  ${If} $0 == 0
    nsExec::ExecToStack 'wsl --version 2>nul'
    Pop $0
    Pop $1 ; Version output
    
    ${If} $0 == 0
      SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ WSL2 detected via direct check"
      StrCpy $SkipWSL2 "true"
    ${Else}
      SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ⚠️ WSL installed but version unclear"
      StrCpy $SkipWSL2 "false"
    ${EndIf}
  ${Else}
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ WSL2 not installed or not accessible"
    StrCpy $SkipWSL2 "false"
  ${EndIf}
FunctionEnd

Function CheckNodeJSDual
  StrCpy $5 "false" ; Found flag
  
  ; Check Windows Node.js
  nsExec::ExecToStack 'node --version 2>nul'
  Pop $0
  ${If} $0 == 0
    Pop $1 ; Version
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Node.js in Windows: $1"
    StrCpy $5 "true"
    StrCpy $NodeJSStatus "$1 (Windows)"
  ${EndIf}
  
  ; Check WSL Node.js (if WSL is available)
  ${If} $SkipWSL2 == "true"
    nsExec::ExecToStack 'wsl -- node --version 2>/dev/null'
    Pop $0
    ${If} $0 == 0
      Pop $2 ; WSL Version
      SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Node.js in WSL: $2"
      StrCpy $5 "true"
      ; Prefer WSL version if both exist
      StrCpy $NodeJSStatus "$2 (WSL)"
    ${EndIf}
  ${EndIf}
  
  ${If} $5 == "true"
    StrCpy $SkipNodeJS "true"
  ${Else}
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ Node.js not found in Windows or WSL"
    StrCpy $SkipNodeJS "false"
  ${EndIf}
FunctionEnd

Function CheckGitDual
  StrCpy $5 "false" ; Found flag
  
  ; Check Windows Git
  nsExec::ExecToStack 'git --version 2>nul'
  Pop $0
  ${If} $0 == 0
    Pop $1 ; Version
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Git in Windows: $1"
    StrCpy $5 "true"
    StrCpy $GitStatus "$1 (Windows)"
  ${EndIf}
  
  ; Check WSL Git (if WSL is available)
  ${If} $SkipWSL2 == "true"
    nsExec::ExecToStack 'wsl -- git --version 2>/dev/null'
    Pop $0
    ${If} $0 == 0
      Pop $2 ; WSL Version
      SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Git in WSL: $2"
      StrCpy $5 "true"
      ; Keep Windows version if both, as it's more useful for installer
      ${If} $GitStatus == ""
        StrCpy $GitStatus "$2 (WSL)"
      ${EndIf}
    ${EndIf}
  ${EndIf}
  
  ${If} $5 == "true"
    StrCpy $SkipGit "true"
  ${Else}
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ Git not found in Windows or WSL"
    StrCpy $SkipGit "false"
  ${EndIf}
FunctionEnd

Function CheckCurlDual
  StrCpy $5 "false" ; Found flag
  
  ; Check Windows Curl
  nsExec::ExecToStack 'curl --version 2>nul'
  Pop $0
  ${If} $0 == 0
    Pop $1 ; Version
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Curl in Windows (built-in)"
    StrCpy $5 "true"
    StrCpy $CurlStatus "Windows built-in"
  ${EndIf}
  
  ; Check WSL Curl (if WSL is available)
  ${If} $SkipWSL2 == "true"
    nsExec::ExecToStack 'wsl -- curl --version 2>/dev/null'
    Pop $0
    ${If} $0 == 0
      Pop $2 ; WSL Version
      SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Curl in WSL"
      StrCpy $5 "true"
      ; Keep Windows version as primary
      ${If} $CurlStatus == ""
        StrCpy $CurlStatus "WSL"
      ${EndIf}
    ${EndIf}
  ${EndIf}
  
  ${If} $5 == "true"
    StrCpy $SkipCurl "true"
  ${Else}
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ Curl not found in Windows or WSL"
    StrCpy $SkipCurl "false"
  ${EndIf}
FunctionEnd

Function CheckClaudeCodeDual
  StrCpy $5 "false" ; Found flag
  StrCpy $6 "" ; Location found
  
  ; Check Windows Claude Code
  nsExec::ExecToStack 'claude --version 2>nul'
  Pop $0
  ${If} $0 == 0
    Pop $1 ; Version
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Claude Code in Windows: $1"
    StrCpy $5 "true"
    StrCpy $6 "Windows"
    StrCpy $ClaudeStatus "$1 (Windows)"
  ${EndIf}
  
  ; Check WSL Claude Code (MOST IMPORTANT - user said it's installed in WSL!)
  ${If} $SkipWSL2 == "true"
    ; Try default WSL distribution
    nsExec::ExecToStack 'wsl -- claude --version 2>/dev/null'
    Pop $0
    ${If} $0 == 0
      Pop $2 ; WSL Version
      SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Claude Code in WSL: $2"
      StrCpy $5 "true"
      StrCpy $6 "WSL"
      StrCpy $ClaudeStatus "$2 (WSL)"
    ${Else}
      ; Try specific Debian distribution (user mentioned Debian)
      nsExec::ExecToStack 'wsl -d debian -- claude --version 2>/dev/null'
      Pop $0
      ${If} $0 == 0
        Pop $3 ; Debian Version
        SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Claude Code in WSL (Debian): $3"
        StrCpy $5 "true"
        StrCpy $6 "WSL-Debian"
        StrCpy $ClaudeStatus "$3 (WSL-Debian)"
      ${Else}
        ; Try other common distribution names
        nsExec::ExecToStack 'wsl -d Ubuntu -- claude --version 2>/dev/null'
        Pop $0
        ${If} $0 == 0
          Pop $4 ; Ubuntu Version
          SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Claude Code in WSL (Ubuntu): $4"
          StrCpy $5 "true"
          StrCpy $6 "WSL-Ubuntu"
          StrCpy $ClaudeStatus "$4 (WSL-Ubuntu)"
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${EndIf}
  
  ${If} $5 == "true"
    StrCpy $SkipClaude "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Claude Code detected in $6 - installation not needed!"
  ${Else}
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ Claude Code not found in Windows, WSL, Debian, or Ubuntu"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   💡 Will install Claude Code in Alpine Linux"
    StrCpy $SkipClaude "false"
  ${EndIf}
FunctionEnd

Function ProcessDependencyResults
  ; Calculate what needs to be installed
  StrCpy $0 0 ; Component counter
  StrCpy $7 "" ; Components list
  StrCpy $8 "" ; Found components list
  
  ; Count and list what needs installation
  ${If} $SkipWSL2 == "false"
    IntOp $0 $0 + 1
    StrCpy $7 "$7• WSL2 and kernel updates$\n"
  ${Else}
    StrCpy $8 "$8• WSL2 (already installed)$\n"
  ${EndIf}
  
  ${If} $SkipNodeJS == "false"
    IntOp $0 $0 + 1
    StrCpy $7 "$7• Node.js runtime$\n"
  ${Else}
    StrCpy $8 "$8• Node.js ($NodeJSStatus)$\n"
  ${EndIf}
  
  ${If} $SkipGit == "false"
    StrCpy $7 "$7• Git version control$\n"
  ${Else}
    StrCpy $8 "$8• Git ($GitStatus)$\n"
  ${EndIf}
  
  ${If} $SkipCurl == "false"
    StrCpy $7 "$7• Curl download tool$\n"
  ${Else}
    StrCpy $8 "$8• Curl ($CurlStatus)$\n"
  ${EndIf}
  
  ${If} $SkipClaude == "false"
    IntOp $0 $0 + 1
    StrCpy $7 "$7• Claude Code CLI$\n"
  ${Else}
    StrCpy $8 "$8• Claude Code ($ClaudeStatus)$\n"
  ${EndIf}
  
  ; Always need Alpine Linux for consistent environment
  ${If} $SkipWSL2 == "false"
    StrCpy $7 "$7• Alpine Linux distribution$\n"
  ${Else}
    IntOp $0 $0 + 1
    StrCpy $7 "$7• Alpine Linux distribution$\n"
  ${EndIf}
  
  ; Calculate time estimate
  IntOp $1 $0 * 3  ; 3 minutes per major component
  IntOp $1 $1 + 2  ; Base overhead time
  IntOp $2 $1 + 3  ; Upper time estimate
  
  ; Create comprehensive installation dialog
  StrCpy $9 "Claude Code Installation Summary$\n$\n"
  
  ${If} $8 != ""
    StrCpy $9 "$9✅ Found existing components:$\n$8$\n"
  ${EndIf}
  
  ${If} $0 > 0
    StrCpy $9 "$9📦 Components to install:$\n$7$\n"
    StrCpy $9 "$9⏱️ Estimated time: $1-$2 minutes$\n"
    ${If} $SkipWSL2 == "false"
      StrCpy $9 "$9⚠️  System reboot may be required for WSL2$\n"
    ${EndIf}
  ${Else}
    StrCpy $9 "$9🎉 All components already installed!$\n$\n"
    StrCpy $9 "$9The installer will verify configuration and$\n"
    StrCpy $9 "$9create shortcuts for easy access.$\n$\n"
    StrCpy $9 "$9⏱️ Estimated time: 1-2 minutes$\n"
  ${EndIf}
  
  StrCpy $9 "$9$\nContinue with installation?"
  
  MessageBox MB_YESNO|MB_ICONQUESTION "$9" IDYES +2
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
  
  ; Extract installer files to installation directory
  SetOutPath "$INSTDIR"
  
  ; Extract generated images
  SetOutPath "$INSTDIR\generated-images"
  File "${ASSETS_DIR}\claude-icon.ico"
  File "${ASSETS_DIR}\wizard-header.bmp"
  File "${ASSETS_DIR}\wizard-sidebar.bmp"
  
  ; TODO: Fix file extraction syntax - temporarily disabled for testing
  ; Extract PowerShell scripts
  ; SetOutPath "$INSTDIR\scripts\powershell"
  ; File "${BUILD_DIR}\scripts\powershell\ClaudeCodeInstaller.psm1"
  ; File "${BUILD_DIR}\scripts\powershell\ProgressTracker.psm1"
  
  ; Extract bash scripts  
  ; SetOutPath "$INSTDIR\scripts\bash"
  ; File "${BUILD_DIR}\scripts\bash\alpine-setup.sh"
  
  ; Extract configuration files
  ; SetOutPath "$INSTDIR\config"
  ; File "${BUILD_DIR}\config\defaults.json"
  
  ; Start installation process
  Call PerformInstallation
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Registry entries for Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "DisplayName" "Claude Code for Windows"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "DisplayIcon" "$INSTDIR\generated-images\claude-icon.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "Publisher" "Claude Code Installer Project"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "NoRepair" 1
  
  ; Create shortcuts
  Call CreateShortcuts
  
SectionEnd

; Installation functions
Function PerformInstallation
  ; Initialize progress
  ${NSD_SetText} $ProgressStatusLabel "Installing Claude Code components..."
  ${NSD_SetText} $CurrentOperation "Validating system requirements..."
  SendMessage $ProgressBar ${PBM_SETPOS} 2 0
  
  DetailPrint "Starting Claude Code installation on fresh Windows system"
  
  ; Step 0: Validate system requirements using PowerShell module
  DetailPrint "Validating system requirements..."
  Call ValidateSystemRequirements
  
  ${NSD_SetText} $CurrentOperation "Starting installation..."
  SendMessage $ProgressBar ${PBM_SETPOS} 5 0
  
  ; Step 1: Install WSL2 if needed (30% of progress)
  ${If} $SkipWSL2 == "false"
    ${NSD_SetText} $CurrentOperation "Installing WSL2..."
    SendMessage $ProgressBar ${PBM_SETPOS} 10 0
    Call InstallWSL2Features
    SendMessage $ProgressBar ${PBM_SETPOS} 30 0
  ${Else}
    DetailPrint "WSL2 already installed, skipping"
    SendMessage $ProgressBar ${PBM_SETPOS} 30 0
  ${EndIf}
  
  ; Step 2: Install Alpine Linux distribution (20% of progress)
  ${NSD_SetText} $CurrentOperation "Setting up Alpine Linux..."
  SendMessage $ProgressBar ${PBM_SETPOS} 40 0
  Call InstallAlpineLinux
  SendMessage $ProgressBar ${PBM_SETPOS} 50 0
  
  ; Step 3: Install Node.js in Alpine if needed (20% of progress)
  ${If} $SkipNodeJS == "false"
    ${NSD_SetText} $CurrentOperation "Installing Node.js in Alpine Linux..."
    SendMessage $ProgressBar ${PBM_SETPOS} 60 0
    Call InstallNodeJSInAlpine
    SendMessage $ProgressBar ${PBM_SETPOS} 70 0
  ${Else}
    DetailPrint "Compatible Node.js found, skipping installation"
    SendMessage $ProgressBar ${PBM_SETPOS} 70 0
  ${EndIf}
  
  ; Step 4: Install Claude Code CLI (20% of progress)
  ${If} $SkipClaude == "false"
    ${NSD_SetText} $CurrentOperation "Installing Claude Code CLI..."
    SendMessage $ProgressBar ${PBM_SETPOS} 80 0
    Call InstallClaudeCodeCLI
    SendMessage $ProgressBar ${PBM_SETPOS} 90 0
  ${Else}
    DetailPrint "Claude Code already installed, skipping"
    SendMessage $ProgressBar ${PBM_SETPOS} 90 0
  ${EndIf}
  
  ; Step 5: Create Windows shortcuts and finalize (10% of progress)
  ${NSD_SetText} $CurrentOperation "Creating shortcuts and finalizing..."
  SendMessage $ProgressBar ${PBM_SETPOS} 95 0
  Call CreateShortcuts
  
  ; Complete installation
  ${NSD_SetText} $ProgressStatusLabel "Installation completed successfully!"
  ${NSD_SetText} $CurrentOperation "Claude Code is ready to use."
  SendMessage $ProgressBar ${PBM_SETPOS} 100 0
  DetailPrint "Claude Code installation completed successfully"
FunctionEnd

; WSL2 Installation Function - Using PowerShell Module
Function InstallWSL2Features
  DetailPrint "Installing WSL2 using comprehensive PowerShell module..."
  
  ; TODO: Use PowerShell module when file extraction is fixed
  ; For now, use basic WSL2 installation
  DetailPrint "Installing WSL2 using basic method (PowerShell modules disabled for testing)..."
  nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "try { Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart; Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart; Write-Output \"WSL2 features enabled\"; exit 0 } catch { Write-Error $_.Exception.Message; exit 1 }"'
  Pop $0 ; Exit code
  Pop $1 ; Output message
  
  DetailPrint "WSL2 installation result: $1"
  
  ${If} $0 == 1
    ; Installation failed
    MessageBox MB_OK|MB_ICONSTOP "WSL2 Installation Failed:$\n$\n$1$\n$\nPlease check system requirements and try again."
    Abort
  ${ElseIf} $0 == 2
    ; Reboot required
    StrCpy $RebootRequired "true"
    DetailPrint "WSL2 installation completed - system reboot required"
    MessageBox MB_YESNO|MB_ICONQUESTION "WSL2 has been installed successfully but requires a system reboot to complete.$\n$\nWould you like to reboot now and continue installation afterward?$\n$\n(Click No to reboot manually later)" IDYES RebootNow IDNO RebootLater
    
    RebootNow:
      DetailPrint "Scheduling installation continuation after reboot..."
      ; TODO: Implement reboot continuation logic
      MessageBox MB_OK|MB_ICONINFORMATION "The system will reboot now. After reboot, please run the installer again to continue.$\n$\nWSL2 installation is complete - the installer will detect this and continue with Claude Code setup."
      Reboot
    
    RebootLater:
      MessageBox MB_OK|MB_ICONINFORMATION "Please reboot your system and run the installer again to continue with Claude Code installation.$\n$\nWSL2 has been installed successfully."
      Abort
  ${Else}
    ; Installation succeeded without reboot
    DetailPrint "WSL2 installation completed successfully"
    StrCpy $RebootRequired "false"
  ${EndIf}
FunctionEnd

; Alpine Linux Installation Function - Using PowerShell Module
Function InstallAlpineLinux
  DetailPrint "Installing and configuring Alpine Linux using PowerShell module..."
  
  ; TODO: Use PowerShell module when file extraction is fixed  
  ; For now, use basic Alpine installation
  DetailPrint "Installing Alpine using basic method (PowerShell modules disabled for testing)..."
  nsExec::ExecToStack 'wsl --install -d Alpine'
  Pop $0 ; Exit code
  Pop $1 ; Output message
  
  DetailPrint "Alpine installation result: $1"
  
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "Alpine Linux Installation Failed:$\n$\n$1$\n$\nPlease check WSL2 is working and try again."
    Abort
  ${Else}
    DetailPrint "Alpine Linux installed successfully"
    
    ; TODO: Run Alpine setup script when file extraction is fixed
    DetailPrint "Basic Alpine installation completed (setup script disabled for testing)"
  ${EndIf}
FunctionEnd

; Node.js Installation in Alpine Function
Function InstallNodeJSInAlpine
  DetailPrint "Verifying Node.js installation in Alpine Linux..."
  
  ; Check if Node.js is already installed from Alpine setup script
  nsExec::ExecToStack 'wsl -d Alpine -- node --version'
  Pop $0
  Pop $1
  
  ${If} $0 == 0
    DetailPrint "Node.js already available: $1"
    ; Check if version is adequate
    nsExec::ExecToStack 'wsl -d Alpine -- npm --version'
    Pop $2
    Pop $3
    ${If} $2 == 0
      DetailPrint "npm already available: $3"
      DetailPrint "Node.js environment is ready"
      Return
    ${EndIf}
  ${EndIf}
  
  ; Install Node.js if not available or insufficient
  DetailPrint "Installing Node.js and npm in Alpine Linux..."
  nsExec::ExecToLog 'wsl -d Alpine -- sh -c "apk update && apk add nodejs npm"'
  Pop $0
  ${If} $0 != 0
    DetailPrint "Error installing Node.js in Alpine: $0"
    MessageBox MB_OK|MB_ICONSTOP "Failed to install Node.js in Alpine Linux. Error code: $0$\n$\nPlease check Alpine Linux is working properly."
    Abort
  ${EndIf}
  
  ; Verify final installation
  nsExec::ExecToStack 'wsl -d Alpine -- node --version'
  Pop $0
  Pop $1
  ${If} $0 == 0
    DetailPrint "Node.js installed successfully: $1"
  ${Else}
    DetailPrint "Warning: Could not verify Node.js installation"
  ${EndIf}
FunctionEnd

; Claude Code CLI Installation Function
Function InstallClaudeCodeCLI
  DetailPrint "Installing Claude Code CLI in Alpine Linux..."
  
  ; Ensure npm is configured properly for global installations
  DetailPrint "Configuring npm environment..."
  nsExec::ExecToLog 'wsl -d Alpine -- sh -c "mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global"'
  
  ; Install Claude Code CLI globally in Alpine
  DetailPrint "Installing @anthropic-ai/claude-code..."
  nsExec::ExecToLog 'wsl -d Alpine -- npm install -g @anthropic-ai/claude-code'
  Pop $0
  ${If} $0 != 0
    DetailPrint "Error installing Claude Code CLI: $0"
    ; Try alternative installation method
    DetailPrint "Trying alternative npm installation..."
    nsExec::ExecToLog 'wsl -d Alpine -- sh -c "export PATH=$PATH:~/.npm-global/bin && npm install -g @anthropic-ai/claude-code"'
    Pop $1
    ${If} $1 != 0
      MessageBox MB_OK|MB_ICONSTOP "Failed to install Claude Code CLI. Error codes: $0, $1$\n$\nPlease verify:$\n- Internet connection is working$\n- npm is properly configured$\n- Alpine Linux has sufficient disk space"
      Abort
    ${EndIf}
  ${EndIf}
  
  ; Verify Claude Code installation and PATH
  DetailPrint "Verifying Claude Code installation..."
  nsExec::ExecToStack 'wsl -d Alpine -- sh -c "export PATH=$PATH:~/.npm-global/bin && claude --version"'
  Pop $0
  Pop $1
  ${If} $0 == 0
    DetailPrint "Claude Code CLI installed successfully: $1"
    ; Ensure PATH is configured for future use
    nsExec::ExecToLog 'wsl -d Alpine -- sh -c "echo \"export PATH=\\$PATH:~/.npm-global/bin\" >> ~/.bashrc"'
    nsExec::ExecToLog 'wsl -d Alpine -- sh -c "echo \"export PATH=\\$PATH:~/.npm-global/bin\" >> ~/.profile"'
    DetailPrint "Claude Code CLI is ready to use"
  ${Else}
    DetailPrint "Warning: Could not verify Claude Code installation"
    MessageBox MB_OK|MB_ICONEXCLAMATION "Claude Code installation completed but verification failed.$\n$\nYou may need to configure your PATH manually in Alpine Linux:$\nexport PATH=$$PATH:~/.npm-global/bin"
  ${EndIf}
FunctionEnd

; System Requirements Validation Function
Function ValidateSystemRequirements
  DetailPrint "Validating system requirements using PowerShell module..."
  
  ; TODO: Import PowerShell module when file extraction is fixed
  ; For now, use basic validation
  DetailPrint "Performing basic system validation (PowerShell modules disabled for testing)..."
  nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "if ([System.Environment]::OSVersion.Version.Build -lt 19041) { Write-Error \"Windows build too old\"; exit 1 } else { Write-Output \"Basic system validation passed\" }"'
  Pop $0 ; Exit code
  Pop $1 ; Output
  
  ${If} $0 != 0
    DetailPrint "System requirements validation failed: $1"
    MessageBox MB_OK|MB_ICONSTOP "System Requirements Validation Failed:$\n$\n$1$\n$\nPlease resolve these issues and run the installer again."
    Abort
  ${Else}
    DetailPrint "System requirements validation passed: $1"
  ${EndIf}
FunctionEnd

; Windows Shortcuts Creation Function
Function CreateShortcuts
  DetailPrint "Creating Windows shortcuts..."
  
  ; Create desktop shortcut
  CreateShortCut "$DESKTOP\Claude Code.lnk" "wsl" "-d Alpine -- claude" "$INSTDIR\generated-images\claude-icon.ico"
  
  ; Create Start Menu shortcuts
  CreateDirectory "$SMPROGRAMS\Claude Code"
  CreateShortCut "$SMPROGRAMS\Claude Code\Claude Code.lnk" "wsl" "-d Alpine -- claude" "$INSTDIR\generated-images\claude-icon.ico"
  CreateShortCut "$SMPROGRAMS\Claude Code\Claude Code Terminal.lnk" "wsl" "-d Alpine" "$INSTDIR\generated-images\claude-icon.ico"
  CreateShortCut "$SMPROGRAMS\Claude Code\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  
  DetailPrint "Shortcuts created successfully"
FunctionEnd

; Uninstaller section
Section "Uninstall"
  ; Remove files
  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR\generated-images"
  RMDir /r "$INSTDIR"
  
  ; Remove shortcuts
  Delete "$DESKTOP\Claude Code.lnk"
  RMDir /r "$SMPROGRAMS\Claude Code"
  
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