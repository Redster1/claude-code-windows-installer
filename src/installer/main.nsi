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

; Custom projects folder selection page
Page custom ProjectsFolderPage ProjectsFolderPageLeave

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
Var SkipAlpine
Var CompatibleDistribution
Var RebootRequired

; Projects folder configuration
Var ProjectsFolderPath
Var ProjectsFolderName
Var ProjectsFolderDialog
Var ProjectsFolderPathEdit
Var ProjectsFolderBrowseButton
Var ProjectsFolderLabel
Var ProjectsFolderNameEdit
Var ProjectsFolderPreview


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
  StrCpy $SkipAlpine "false"
  StrCpy $CompatibleDistribution ""
  
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
  
  ; Check for compatible WSL distribution (NEW - this determines if we need Alpine)
  SendMessage $DependencyProgressBar ${PBM_SETPOS} 95 0
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:🔧 Checking for compatible WSL distribution..."
  Call CheckCompatibleWSLDistribution
  
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

Function CheckCompatibleWSLDistribution
  ; This function determines if we have a WSL distribution that already has all required tools
  ; If so, we can skip installing Alpine Linux entirely
  
  ${If} $SkipWSL2 == "false"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ⚠️ WSL2 not available - Alpine Linux will be needed"
    StrCpy $SkipAlpine "false"
    Return
  ${EndIf}
  
  ; Get list of available WSL distributions
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🔍 Scanning available WSL distributions..."
  nsExec::ExecToStack 'wsl --list --quiet 2>nul'
  Pop $0
  ${If} $0 != 0
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ⚠️ Could not list WSL distributions - Alpine will be installed"
    StrCpy $SkipAlpine "false"
    Return
  ${EndIf}
  
  ; Check common distributions: default, debian, ubuntu, fedora, opensuse
  StrCpy $7 "" ; Will store compatible distribution name
  
  ; Try default distribution first
  Push ""
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution $7
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: $7"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  ; Try specific known distributions
  Push "debian"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "debian"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Debian"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "Ubuntu"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "Ubuntu"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Ubuntu"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "fedora"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "fedora"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Fedora"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "openSUSE-Leap"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "openSUSE-Leap"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: openSUSE Leap"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "openSUSE-Tumbleweed"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "openSUSE-Tumbleweed"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: openSUSE Tumbleweed"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "Arch"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "Arch"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Arch Linux"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "CentOS"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "CentOS"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: CentOS"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "RHEL"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "RHEL"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Red Hat Enterprise Linux"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "OracleLinux"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "OracleLinux"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Oracle Linux"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "SLES"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "SLES"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: SUSE Linux Enterprise Server"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "kali-linux"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "kali-linux"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Kali Linux"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "Pengwin"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "Pengwin"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Pengwin"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "Ubuntu-18.04"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "Ubuntu-18.04"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Ubuntu 18.04"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "Ubuntu-20.04"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "Ubuntu-20.04"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Ubuntu 20.04"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  Push "Ubuntu-22.04"
  Call CheckDistributionForTools
  Pop $7
  ${If} $7 != ""
    StrCpy $CompatibleDistribution "Ubuntu-22.04"
    StrCpy $SkipAlpine "true"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ✅ Compatible distribution found: Ubuntu 22.04"
    SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   🎯 Alpine Linux installation not needed!"
    Return
  ${EndIf}
  
  ; No compatible distribution found
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   ❌ No existing distribution has all required tools"
  SendMessage $DependencyListBox ${LB_ADDSTRING} 0 "STR:   💡 Will install Alpine Linux with all tools"
  StrCpy $SkipAlpine "false"
  StrCpy $CompatibleDistribution ""
FunctionEnd

Function CheckDistributionForTools
  ; Input: distribution name on stack (empty for default)
  ; Output: pushes result on stack (distribution name if compatible, empty if not)
  Pop $8 ; Distribution name
  
  StrCpy $9 "" ; Initialize output as empty
  
  ; Build WSL command
  StrCpy $6 "wsl"
  ${If} $8 != ""
    StrCpy $6 "$6 -d $8"
  ${EndIf}
  
  ; Check for Claude Code (most important)
  nsExec::ExecToStack '$6 -- claude --version 2>/dev/null'
  Pop $0
  ${If} $0 != 0
    Push $9 ; Push empty result
    Return ; Claude Code not found, this distribution is not compatible
  ${EndIf}
  
  ; Check for Node.js
  nsExec::ExecToStack '$6 -- node --version 2>/dev/null'
  Pop $0
  ${If} $0 != 0
    Push $9 ; Push empty result
    Return ; Node.js not found
  ${EndIf}
  
  ; Check for Git
  nsExec::ExecToStack '$6 -- git --version 2>/dev/null'
  Pop $0
  ${If} $0 != 0
    Push $9 ; Push empty result
    Return ; Git not found
  ${EndIf}
  
  ; Check for Curl
  nsExec::ExecToStack '$6 -- curl --version 2>/dev/null'
  Pop $0
  ${If} $0 != 0
    Push $9 ; Push empty result
    Return ; Curl not found
  ${EndIf}
  
  ; All tools found - this distribution is compatible!
  ${If} $8 != ""
    StrCpy $9 $8
  ${Else}
    StrCpy $9 "default"
  ${EndIf}
  
  Push $9 ; Push the result
FunctionEnd

Function ProjectsFolderPage
  !insertmacro MUI_HEADER_TEXT "Claude Code Projects Folder Setup" "Choose where Claude Code will create and access your projects."
  
  nsDialogs::Create 1018
  Pop $ProjectsFolderDialog
  
  ${If} $ProjectsFolderDialog == error
    Abort
  ${EndIf}
  
  ; Explanatory label
  ${NSD_CreateLabel} 0 0 100% 20u "Claude Code will create a dedicated folder for your projects. You can customize the location and name below."
  Pop $ProjectsFolderLabel
  
  ; Base path label and edit field
  ${NSD_CreateLabel} 0 30u 20% 12u "Location:"
  Pop $0
  
  ${NSD_CreateText} 22% 28u 65% 14u "$ProjectsFolderPath"
  Pop $ProjectsFolderPathEdit
  
  ; Browse button
  ${NSD_CreateButton} 89% 28u 11% 14u "Browse..."
  Pop $ProjectsFolderBrowseButton
  ${NSD_OnClick} $ProjectsFolderBrowseButton OnBrowseProjectsFolder
  
  ; Folder name label and edit field
  ${NSD_CreateLabel} 0 50u 20% 12u "Folder Name:"
  Pop $0
  
  ${NSD_CreateText} 22% 48u 65% 14u "$ProjectsFolderName"
  Pop $ProjectsFolderNameEdit
  ${NSD_OnChange} $ProjectsFolderNameEdit OnProjectsFolderNameChange
  
  ; Preview label
  ${NSD_CreateLabel} 0 70u 100% 12u "Full Path: $ProjectsFolderPath"
  Pop $ProjectsFolderPreview
  
  ; Help text
  ${NSD_CreateLabel} 0 90u 100% 40u "This folder will be created during installation and Claude Code shortcuts will open directly in this location. You can change this later by editing the shortcuts or using a different folder when launching Claude Code."
  Pop $0
  
  ; Initialize preview
  Call UpdateProjectsPreview
  
  nsDialogs::Show
FunctionEnd

Function ProjectsFolderPageLeave
  ; Get the current values from the edit controls
  ${NSD_GetText} $ProjectsFolderPathEdit $0
  ${NSD_GetText} $ProjectsFolderNameEdit $1
  
  ; Remove trailing backslash if present
  StrCpy $2 $0 1 -1
  ${If} $2 == "\"
    StrCpy $0 $0 -1
  ${EndIf}
  
  ; Validate folder name (remove invalid characters)
  StrCpy $ProjectsFolderName $1
  Call ValidateProjectsFolderName
  
  ; Build full path
  StrCpy $ProjectsFolderPath "$0\$ProjectsFolderName"
  
  ; Validate the path
  Call ValidateProjectsPath
FunctionEnd

Function OnBrowseProjectsFolder
  nsDialogs::SelectFolderDialog "Select the parent folder for Claude Code Projects:" $ProjectsFolderPath
  Pop $0
  
  ${If} $0 != ""
    StrCpy $ProjectsFolderPath "$0"
    ${NSD_SetText} $ProjectsFolderPathEdit "$0"
    Call UpdateProjectsPreview
  ${EndIf}
FunctionEnd

Function OnProjectsFolderNameChange
  ${NSD_GetText} $ProjectsFolderNameEdit $ProjectsFolderName
  Call UpdateProjectsPreview
FunctionEnd

Function UpdateProjectsPreview
  ; Get current base path and folder name
  ${NSD_GetText} $ProjectsFolderPathEdit $0
  ${NSD_GetText} $ProjectsFolderNameEdit $1
  
  ; Remove trailing backslash if present
  StrCpy $2 $0 1 -1
  ${If} $2 == "\"
    StrCpy $0 $0 -1
  ${EndIf}
  
  ; Update preview
  ${NSD_SetText} $ProjectsFolderPreview "Full Path: $0\$1"
FunctionEnd

Function ValidateProjectsFolderName
  ; Basic validation - ensure it's not empty
  ; Windows will handle invalid characters during folder creation
  
  ; Check if empty
  StrLen $0 $ProjectsFolderName
  ${If} $0 == 0
    StrCpy $ProjectsFolderName "Claude Code Projects"
  ${EndIf}
  
  ; If the name is just spaces, reset to default
  StrCmp $ProjectsFolderName " " 0 +2
    StrCpy $ProjectsFolderName "Claude Code Projects"
FunctionEnd

Function ValidateProjectsPath
  ; Basic path validation - check if parent directory exists
  ; More detailed validation would be done during actual folder creation
  DetailPrint "Projects folder will be created at: $ProjectsFolderPath"
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
  
  ; Alpine Linux installation (only if no compatible distribution exists)
  ${If} $SkipAlpine == "false"
    IntOp $0 $0 + 1
    StrCpy $7 "$7• Alpine Linux distribution$\n"
  ${Else}
    StrCpy $8 "$8• Alpine Linux (compatible distribution found: $CompatibleDistribution)$\n"
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
  
  ; Extract PowerShell scripts
  SetOutPath "$INSTDIR\scripts\powershell"
  File "${BUILD_DIR}\scripts\powershell\ClaudeCodeInstaller.psm1"
  File "${BUILD_DIR}\scripts\powershell\ProgressTracker.psm1"
  
  ; Extract bash scripts  
  SetOutPath "$INSTDIR\scripts\bash"
  File "${BUILD_DIR}\scripts\bash\alpine-setup.sh"
  
  ; Extract configuration files
  SetOutPath "$INSTDIR\config"
  File "${BUILD_DIR}\config\defaults.json"
  
  ; Extract template files
  SetOutPath "$INSTDIR\templates"
  File "${BUILD_DIR}\templates\CLAUDE.md.template"
  
  ; Start installation process
  Call PerformInstallation
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Registry entries for Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "DisplayName" "Claude Code for Windows"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "UninstallString" "$INSTDIR\Uninstall.exe"
  ; WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "DisplayIcon" "$INSTDIR\generated-images\claude-icon.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "Publisher" "Claude Code Installer Project"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "ProjectsFolder" "$ProjectsFolderPath"
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
  
  ; Step 2: Install Alpine Linux distribution (20% of progress) - only if needed
  ${If} $SkipAlpine == "false"
    ${NSD_SetText} $CurrentOperation "Setting up Alpine Linux..."
    SendMessage $ProgressBar ${PBM_SETPOS} 40 0
    Call InstallAlpineLinux
    SendMessage $ProgressBar ${PBM_SETPOS} 50 0
  ${Else}
    DetailPrint "Compatible WSL distribution found ($CompatibleDistribution), skipping Alpine installation"
    ${NSD_SetText} $CurrentOperation "Using existing WSL distribution: $CompatibleDistribution"
    SendMessage $ProgressBar ${PBM_SETPOS} 50 0
  ${EndIf}
  
  ; Step 3: Install Node.js in target distribution if needed (20% of progress)
  ${If} $SkipNodeJS == "false"
    ${If} $CompatibleDistribution != ""
      ${NSD_SetText} $CurrentOperation "Installing Node.js in $CompatibleDistribution..."
      DetailPrint "Installing Node.js in existing distribution: $CompatibleDistribution"
    ${Else}
      ${NSD_SetText} $CurrentOperation "Installing Node.js in Alpine Linux..."
      DetailPrint "Installing Node.js in Alpine Linux"
    ${EndIf}
    SendMessage $ProgressBar ${PBM_SETPOS} 60 0
    Call InstallNodeJSInDistribution
    SendMessage $ProgressBar ${PBM_SETPOS} 70 0
  ${Else}
    DetailPrint "Compatible Node.js found, skipping installation"
    SendMessage $ProgressBar ${PBM_SETPOS} 70 0
  ${EndIf}
  
  ; Step 4: Install Claude Code CLI (20% of progress)
  ${If} $SkipClaude == "false"
    ${If} $CompatibleDistribution != ""
      ${NSD_SetText} $CurrentOperation "Installing Claude Code CLI in $CompatibleDistribution..."
      DetailPrint "Installing Claude Code in existing distribution: $CompatibleDistribution"
    ${Else}
      ${NSD_SetText} $CurrentOperation "Installing Claude Code CLI in Alpine..."
      DetailPrint "Installing Claude Code in Alpine Linux"
    ${EndIf}
    SendMessage $ProgressBar ${PBM_SETPOS} 80 0
    Call InstallClaudeCodeInDistribution
    SendMessage $ProgressBar ${PBM_SETPOS} 90 0
  ${Else}
    DetailPrint "Claude Code already installed, skipping"
    SendMessage $ProgressBar ${PBM_SETPOS} 90 0
  ${EndIf}
  
  ; Step 5: Create Claude Code Projects folder
  ${NSD_SetText} $CurrentOperation "Creating Claude Code Projects folder..."
  SendMessage $ProgressBar ${PBM_SETPOS} 92 0
  Call CreateProjectsFolder
  
  ; Step 6: Create Windows shortcuts and finalize (8% of progress)
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
  
  ; Use PowerShell module for sophisticated WSL2 installation
  nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\scripts\powershell\ClaudeCodeInstaller.psm1\"; try { $result = Install-WSL2 -SkipIfExists; if ($result) { Write-Output \"WSL2_SUCCESS\"; exit 0 } else { Write-Output \"WSL2_FAILED\"; exit 1 } } catch { Write-Output \"WSL2_ERROR\"; exit 1 }"'
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
  DetailPrint "Installing and configuring Alpine Linux using comprehensive PowerShell module..."
  
  ; Use PowerShell module for sophisticated Alpine installation and configuration
  nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\scripts\powershell\ClaudeCodeInstaller.psm1\"; try { $result = Install-AlpineLinux -SkipIfExists -SetAsDefault; if ($result) { Write-Output \"ALPINE_SUCCESS\"; exit 0 } else { Write-Output \"ALPINE_FAILED\"; exit 1 } } catch { Write-Output \"ALPINE_ERROR\"; exit 1 }"'
  Pop $0 ; Exit code
  Pop $1 ; Output message
  
  DetailPrint "Alpine installation result: $1"
  
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "Alpine Linux Installation Failed:$\n$\n$1$\n$\nPlease check WSL2 is working and try again."
    Abort
  ${Else}
    DetailPrint "Alpine Linux installed and configured successfully"
  ${EndIf}
FunctionEnd

; Node.js Installation in Distribution Function
Function InstallNodeJSInDistribution
  ; Determine target distribution
  StrCpy $5 "Alpine"
  ${If} $CompatibleDistribution != ""
    ${If} $CompatibleDistribution == "default"
      StrCpy $5 ""
    ${Else}
      StrCpy $5 $CompatibleDistribution
    ${EndIf}
  ${EndIf}
  
  DetailPrint "Verifying Node.js installation in WSL distribution: $5"
  
  ; Build WSL command
  StrCpy $6 "wsl"
  ${If} $5 != ""
    StrCpy $6 "$6 -d $5"
  ${EndIf}
  
  ; Check if Node.js is already installed
  nsExec::ExecToStack '$6 -- node --version'
  Pop $0
  Pop $1
  
  ${If} $0 == 0
    DetailPrint "Node.js already available: $1"
    ; Check if version is adequate
    nsExec::ExecToStack '$6 -- npm --version'
    Pop $2
    Pop $3
    ${If} $2 == 0
      DetailPrint "npm already available: $3"
      DetailPrint "Node.js environment is ready"
      Return
    ${EndIf}
  ${EndIf}
  
  ; Install Node.js if not available or insufficient
  DetailPrint "Installing Node.js and npm in WSL distribution: $5"
  
  ; Use distribution-specific package manager
  ${If} $5 == "Alpine"
    nsExec::ExecToLog '$6 -- sh -c "apk update && apk add nodejs npm"'
  ${ElseIf} $5 == "debian"
  ${OrIf} $5 == "Ubuntu"
  ${OrIf} $5 == "Ubuntu-18.04"
  ${OrIf} $5 == "Ubuntu-20.04"
  ${OrIf} $5 == "Ubuntu-22.04"
  ${OrIf} $5 == "kali-linux"
  ${OrIf} $5 == "Pengwin"
    nsExec::ExecToLog '$6 -- sh -c "apt update && apt install -y nodejs npm"'
  ${ElseIf} $5 == "fedora"
  ${OrIf} $5 == "CentOS"
  ${OrIf} $5 == "RHEL"
  ${OrIf} $5 == "OracleLinux"
    nsExec::ExecToLog '$6 -- sh -c "dnf install -y nodejs npm"'
  ${ElseIf} $5 == "openSUSE-Leap"
  ${OrIf} $5 == "openSUSE-Tumbleweed"
  ${OrIf} $5 == "SLES"
    nsExec::ExecToLog '$6 -- sh -c "zypper install -y nodejs npm"'
  ${ElseIf} $5 == "Arch"
    nsExec::ExecToLog '$6 -- sh -c "pacman -S --noconfirm nodejs npm"'
  ${Else}
    ; Try common package managers for unknown distributions
    nsExec::ExecToLog '$6 -- sh -c "apt update && apt install -y nodejs npm || dnf install -y nodejs npm || zypper install -y nodejs npm || pacman -S --noconfirm nodejs npm || apk add nodejs npm"'
  ${EndIf}
  
  Pop $0
  ${If} $0 != 0
    DetailPrint "Error installing Node.js in $5: $0"
    MessageBox MB_OK|MB_ICONSTOP "Failed to install Node.js in WSL distribution $5. Error code: $0$\n$\nPlease check the distribution is working properly."
    Abort
  ${EndIf}
  
  ; Verify final installation
  nsExec::ExecToStack '$6 -- node --version'
  Pop $0
  Pop $1
  ${If} $0 == 0
    DetailPrint "Node.js installed successfully: $1"
  ${Else}
    DetailPrint "Warning: Could not verify Node.js installation"
  ${EndIf}
FunctionEnd

; Claude Code CLI Installation Function
Function InstallClaudeCodeInDistribution
  ; Determine target distribution
  StrCpy $5 "Alpine"
  ${If} $CompatibleDistribution != ""
    ${If} $CompatibleDistribution == "default"
      StrCpy $5 ""
    ${Else}
      StrCpy $5 $CompatibleDistribution
    ${EndIf}
  ${EndIf}
  
  DetailPrint "Installing Claude Code CLI in WSL distribution: $5"
  
  ; Build WSL command
  StrCpy $6 "wsl"
  ${If} $5 != ""
    StrCpy $6 "$6 -d $5"
  ${EndIf}
  
  ; Ensure npm is configured properly for global installations
  DetailPrint "Configuring npm environment..."
  nsExec::ExecToLog '$6 -- sh -c "mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global"'
  
  ; Install Claude Code CLI globally
  DetailPrint "Installing @anthropic-ai/claude-code..."
  nsExec::ExecToLog '$6 -- npm install -g @anthropic-ai/claude-code'
  Pop $0
  ${If} $0 != 0
    DetailPrint "Error installing Claude Code CLI: $0"
    ; Try alternative installation method
    DetailPrint "Trying alternative npm installation..."
    nsExec::ExecToLog '$6 -- sh -c "export PATH=$PATH:~/.npm-global/bin && npm install -g @anthropic-ai/claude-code"'
    Pop $1
    ${If} $1 != 0
      MessageBox MB_OK|MB_ICONSTOP "Failed to install Claude Code CLI. Error codes: $0, $1$\n$\nPlease verify:$\n- Internet connection is working$\n- npm is properly configured$\n- WSL distribution has sufficient disk space"
      Abort
    ${EndIf}
  ${EndIf}
  
  ; Verify Claude Code installation and PATH
  DetailPrint "Verifying Claude Code installation..."
  nsExec::ExecToStack '$6 -- sh -c "export PATH=$PATH:~/.npm-global/bin && claude --version"'
  Pop $0
  Pop $1
  ${If} $0 == 0
    DetailPrint "Claude Code CLI installed successfully: $1"
    ; Ensure PATH is configured for future use
    nsExec::ExecToLog '$6 -- sh -c "echo \"export PATH=\\$PATH:~/.npm-global/bin\" >> ~/.bashrc"'
    nsExec::ExecToLog '$6 -- sh -c "echo \"export PATH=\\$PATH:~/.npm-global/bin\" >> ~/.profile"'
    DetailPrint "Claude Code CLI is ready to use"
  ${Else}
    DetailPrint "Warning: Could not verify Claude Code installation"
    MessageBox MB_OK|MB_ICONEXCLAMATION "Claude Code installation completed but verification failed.$\n$\nYou may need to configure your PATH manually in the WSL distribution:$\nexport PATH=$$PATH:~/.npm-global/bin"
  ${EndIf}
FunctionEnd

; System Requirements Validation Function
Function ValidateSystemRequirements
  DetailPrint "Validating system requirements using comprehensive PowerShell module..."
  
  ; Use PowerShell module for comprehensive system validation
  nsExec::ExecToStack 'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module \"$INSTDIR\scripts\powershell\ClaudeCodeInstaller.psm1\"; try { $result = Test-SystemRequirements; if ($result) { Write-Output \"VALIDATION_PASSED\"; exit 0 } else { Write-Output \"VALIDATION_FAILED\"; exit 1 } } catch { Write-Output \"VALIDATION_ERROR\"; exit 1 }"'
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

; Claude Code Projects Folder Creation Function
Function CreateProjectsFolder
  DetailPrint "Creating Claude Code Projects folder..."
  
  ; Check if the projects folder already exists
  ${If} ${FileExists} "$ProjectsFolderPath\*.*"
    DetailPrint "Projects folder already exists: $ProjectsFolderPath"
  ${Else}
    DetailPrint "Creating projects folder: $ProjectsFolderPath"
    
    ; Create the directory
    CreateDirectory "$ProjectsFolderPath"
    
    ; Verify creation was successful
    ${If} ${FileExists} "$ProjectsFolderPath\*.*"
      DetailPrint "Projects folder created successfully: $ProjectsFolderPath"
      
      ; Create a welcome README file in the projects folder
      FileOpen $0 "$ProjectsFolderPath\README.txt" w
      ${If} $0 != ""
        FileWrite $0 "Welcome to your Claude Code Projects folder!$\r$\n$\r$\n"
        FileWrite $0 "This folder was created by the Claude Code Windows Installer.$\r$\n"
        FileWrite $0 "You can use this folder to organize your Claude Code projects.$\r$\n$\r$\n"
        FileWrite $0 "The Claude Code shortcuts are configured to open directly in this folder.$\r$\n$\r$\n"
        FileWrite $0 "To change the working directory, you can either:$\r$\n"
        FileWrite $0 "- Edit the shortcut properties to change the '--cd' parameter$\r$\n"
        FileWrite $0 "- Use 'cd' commands within Claude Code to navigate elsewhere$\r$\n$\r$\n"
        FileWrite $0 "Happy coding with Claude!$\r$\n"
        FileClose $0
        DetailPrint "Created README.txt in projects folder"
      ${EndIf}
      
      ; Copy CLAUDE.md template to projects folder
      DetailPrint "Creating CLAUDE.md in projects folder..."
      CopyFiles "$INSTDIR\templates\CLAUDE.md.template" "$ProjectsFolderPath\CLAUDE.md"
      ${If} ${FileExists} "$ProjectsFolderPath\CLAUDE.md"
        DetailPrint "Created CLAUDE.md in projects folder"
      ${Else}
        DetailPrint "Warning: Could not create CLAUDE.md in projects folder"
      ${EndIf}
    ${Else}
      DetailPrint "Warning: Could not create projects folder: $ProjectsFolderPath"
      MessageBox MB_OK|MB_ICONEXCLAMATION "Warning: Could not create the projects folder at:$\n$\n$ProjectsFolderPath$\n$\nYou may need to create this folder manually or run the installer as administrator."
    ${EndIf}
  ${EndIf}
FunctionEnd

; Windows Shortcuts Creation Function
Function CreateShortcuts
  DetailPrint "Creating Windows shortcuts..."
  
  ; Determine target distribution for shortcuts
  StrCpy $5 "Alpine"
  ${If} $CompatibleDistribution != ""
    ${If} $CompatibleDistribution != "default"
      StrCpy $5 $CompatibleDistribution
    ${Else}
      StrCpy $5 "default"
    ${EndIf}
  ${EndIf}
  
  DetailPrint "Creating shortcuts for WSL distribution: $5"
  
  ; Build command arguments for shortcuts
  ${If} $5 == "default"
    StrCpy $6 '--cd "$ProjectsFolderPath" -- claude'
    StrCpy $7 '--cd "$ProjectsFolderPath"'
  ${Else}
    StrCpy $6 '--cd "$ProjectsFolderPath" -d $5 -- claude'
    StrCpy $7 '--cd "$ProjectsFolderPath" -d $5'
  ${EndIf}
  
  ; Create desktop shortcut with projects folder as working directory
  CreateShortCut "$DESKTOP\Claude Code.lnk" "wsl.exe" "$6" "$INSTDIR\generated-images\claude-icon.ico"
  
  ; Create Start Menu shortcuts
  CreateDirectory "$SMPROGRAMS\Claude Code"
  CreateShortCut "$SMPROGRAMS\Claude Code\Claude Code.lnk" "wsl.exe" "$6" "$INSTDIR\generated-images\claude-icon.ico"
  CreateShortCut "$SMPROGRAMS\Claude Code\Claude Code Terminal.lnk" "wsl.exe" "$7" "$INSTDIR\generated-images\claude-icon.ico"
  
  CreateShortCut "$SMPROGRAMS\Claude Code\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  
  DetailPrint "Shortcuts created successfully"
FunctionEnd

; Uninstaller section
Section "Uninstall"
  ; Remove files
  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR\generated-images"
  RMDir /r "$INSTDIR\scripts"
  RMDir /r "$INSTDIR\config"
  RMDir /r "$INSTDIR\templates"
  RMDir /r "$INSTDIR"
  
  ; Remove shortcuts
  Delete "$DESKTOP\Claude Code.lnk"
  RMDir /r "$SMPROGRAMS\Claude Code"
  
  ; Ask user about removing Claude Code Projects folder
  ; Try to read the projects folder path from registry (if we stored it during installation)
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCode" "ProjectsFolder"
  ${If} $0 != ""
    ${AndIf} ${FileExists} "$0\*.*"
    MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to remove your Claude Code Projects folder and all its contents?$\n$\nLocation: $0$\n$\nWarning: This will permanently delete all your projects!" IDYES RemoveProjects IDNO KeepProjects
    
    RemoveProjects:
      RMDir /r "$0"
      ${If} ${FileExists} "$0\*.*"
        MessageBox MB_OK|MB_ICONEXCLAMATION "Could not completely remove the projects folder. Some files may still remain at:$\n$\n$0"
      ${EndIf}
      Goto EndProjectsRemoval
      
    KeepProjects:
      MessageBox MB_OK|MB_ICONINFORMATION "Your Claude Code Projects folder has been preserved at:$\n$\n$0"
      Goto EndProjectsRemoval
      
    EndProjectsRemoval:
  ${EndIf}
  
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
  StrCpy $SkipAlpine "false"
  StrCpy $CompatibleDistribution ""
  
  ; Initialize projects folder variables
  StrCpy $ProjectsFolderName "Claude Code Projects"
  StrCpy $ProjectsFolderPath "$DOCUMENTS\Claude Code Projects"
FunctionEnd