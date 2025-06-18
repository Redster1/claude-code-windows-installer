; Claude Code Windows Installer - Minimal UI for Testing
; Simplified UI pages that will build successfully

!include "nsDialogs.nsh"
!include "LogicLib.nsh"

; Page variables
Var TestDialog
Var TestLabel
Var TestProgressBar
Var TestList

; Simple dependency check page
Function DependencyCheckPage
    !insertmacro MUI_HEADER_TEXT "System Dependencies" "Checking your system for required components..."
    
    nsDialogs::Create 1018
    Pop $TestDialog
    
    ${If} $TestDialog == error
        Abort
    ${EndIf}
    
    ; Status label
    ${NSD_CreateLabel} 0 0 100% 20u "Checking system dependencies..."
    Pop $TestLabel
    
    ; Progress bar
    ${NSD_CreateProgressBar} 0 30u 100% 12u ""
    Pop $TestProgressBar
    SendMessage $TestProgressBar ${PBM_SETRANGE} 0 0x640064
    
    ; Results list
    ${NSD_CreateListBox} 0 50u 100% 120u ""
    Pop $TestList
    
    ; Simulate dependency check
    Call SimpleDepCheck
    
    nsDialogs::Show
FunctionEnd

Function SimpleDepCheck
    SendMessage $TestList ${LB_ADDSTRING} 0 "STR:🔍 Starting dependency scan..."
    SendMessage $TestProgressBar ${PBM_SETPOS} 20 0
    
    SendMessage $TestList ${LB_ADDSTRING} 0 "STR:✅ Windows Version: Compatible"
    SendMessage $TestProgressBar ${PBM_SETPOS} 40 0
    
    SendMessage $TestList ${LB_ADDSTRING} 0 "STR:✅ Administrator Rights: Confirmed"  
    SendMessage $TestProgressBar ${PBM_SETPOS} 60 0
    
    SendMessage $TestList ${LB_ADDSTRING} 0 "STR:📦 WSL2: Will be installed"
    SendMessage $TestProgressBar ${PBM_SETPOS} 80 0
    
    SendMessage $TestList ${LB_ADDSTRING} 0 "STR:✅ Disk Space: Sufficient"
    SendMessage $TestProgressBar ${PBM_SETPOS} 100 0
    
    ${NSD_SetText} $TestLabel "Dependency check completed - ready to install"
FunctionEnd

; Simple installation progress page
Function InstallationProgressPage
    !insertmacro MUI_HEADER_TEXT "Installing Claude Code" "Setting up WSL2, Alpine Linux, and Claude Code CLI..."
    
    nsDialogs::Create 1018
    Pop $TestDialog
    
    ${If} $TestDialog == error
        Abort
    ${EndIf}
    
    ; Status label
    ${NSD_CreateLabel} 0 0 100% 20u "Installing Claude Code for Windows..."
    Pop $TestLabel
    
    ; Progress bar
    ${NSD_CreateProgressBar} 0 30u 100% 12u ""
    Pop $TestProgressBar
    SendMessage $TestProgressBar ${PBM_SETRANGE} 0 0x640064
    
    ; Installation steps
    ${NSD_CreateListBox} 0 50u 100% 120u ""
    Pop $TestList
    
    ; Simulate installation
    Call SimpleInstall
    
    nsDialogs::Show
FunctionEnd

Function SimpleInstall
    SendMessage $TestList ${LB_ADDSTRING} 0 "STR:🚀 Starting Claude Code installation..."
    SendMessage $TestProgressBar ${PBM_SETPOS} 10 0
    
    SendMessage $TestList ${LB_ADDSTRING} 0 "STR:🔧 Installing WSL2 components..."
    SendMessage $TestProgressBar ${PBM_SETPOS} 30 0
    
    SendMessage $TestList ${LB_ADDSTRING} 0 "STR:🏔️ Setting up Alpine Linux..."
    SendMessage $TestProgressBar ${PBM_SETPOS} 60 0
    
    SendMessage $TestList ${LB_ADDSTRING} 0 "STR:🤖 Installing Claude Code CLI..."
    SendMessage $TestProgressBar ${PBM_SETPOS} 90 0
    
    SendMessage $TestList ${LB_ADDSTRING} 0 "STR:✅ Installation completed successfully!"
    SendMessage $TestProgressBar ${PBM_SETPOS} 100 0
    
    ${NSD_SetText} $TestLabel "Claude Code installation completed successfully!"
FunctionEnd

; Page leave functions
Function DependencyCheckPageLeave
FunctionEnd

Function InstallationProgressPageLeave  
FunctionEnd