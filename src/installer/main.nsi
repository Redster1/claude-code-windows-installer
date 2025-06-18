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
  ; Try PowerShell module first (most accurate) - use fallback path approach
  nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "try { $$ModulePath = Join-Path $$env:LOCALAPPDATA \"ClaudeCode\scripts\powershell\ClaudeCodeInstaller.psm1\"; if (Test-Path $$ModulePath) { Import-Module $$ModulePath -Force; Test-WSL2Installation | ConvertTo-Json -Compress } else { \"{}\" } } catch { \"{}\" }"'
  Pop $0 ; Exit code
  Pop $1 ; JSON result
  
  ${If} $0 == 0
  ${AndIf} $1 != ""
  ${AndIf} $1 != "{}"
    ; Parse PowerShell JSON result
    ${If} $1 != ""
      ; Check if WSL2 is installed from JSON
      nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "try { (\'$1\' | ConvertFrom-Json).Installed } catch { \'false\' }"'
      Pop $0
      Pop $2 ; Installed status
      
      ${If} $2 == "True"
        ; Get version and distributions
        nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "try { (\'$1\' | ConvertFrom-Json).Version } catch { \'Unknown\' }"'
        Pop $0
        Pop $3 ; Version
        
        nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "try { (\'$1\' | ConvertFrom-Json).Distributions.Count } catch { 0 }"'
        Pop $0
        Pop $4 ; Distribution count
        
        SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ WSL2 installed: Version $3"
        SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   📋 Found $4 WSL distribution(s)"
        StrCpy $SkipWSL2 "true"
        Return
      ${EndIf}
    ${EndIf}
  ${EndIf}
  
  ; Fallback to direct WSL check
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