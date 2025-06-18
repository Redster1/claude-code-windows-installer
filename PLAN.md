# Claude Code Windows Installer - Implementation Plan

## Phase 0: Development Environment Setup (Days 1-2)

### Linux Development Setup
```bash
# Install NSIS on NixOS
nix-env -iA nixpkgs.nsis

# Install PowerShell Core
nix-env -iA nixpkgs.powershell

# Development tools
nix-env -iA nixpkgs.git nixpkgs.nodejs nixpkgs.vscode

# Windows testing VM
nix-env -iA nixpkgs.qemu nixpkgs.libvirt
```

### Project Structure
```
claude-code-installer/
├── src/
│   ├── installer/
│   │   ├── main.nsi          # NSIS installer script
│   │   ├── ui/               # Custom UI pages
│   │   └── assets/           # Icons, images
│   ├── scripts/
│   │   ├── powershell/       # Windows automation
│   │   ├── bash/             # Alpine/WSL scripts
│   │   └── validation/       # Pre-install checks
│   ├── config/
│   │   └── defaults.json     # Default configurations
│   └── tests/
│       ├── unit/
│       └── integration/
├── build/
├── dist/
├── docs/
├── tools/
│   └── test-harness/         # Windows test automation
└── README.md
```

### Development Tools Setup
- **Version Control**: Git with conventional commits
- **Build System**: GNU Make + NSIS
- **Testing**: Jest for unit tests, custom PowerShell test harness
- **CI/CD**: GitHub Actions with Windows runners
- **Documentation**: Markdown + MkDocs

## Phase 1: Core Infrastructure (Days 3-7)

### 1.1 Dependency Detection System
```javascript
// src/scripts/validation/dependency-detector.js
class DependencyDetector {
  constructor() {
    this.dependencies = {
      wsl2: { minVersion: '2.0.0', required: true },
      nodejs: { minVersion: '18.0.0', required: false },
      git: { minVersion: '2.30.0', required: false },
      curl: { minVersion: '7.70.0', required: false }
    };
  }

  async detectAll() {
    const results = {};
    for (const [dep, config] of Object.entries(this.dependencies)) {
      results[dep] = await this.detect(dep, config);
    }
    return results;
  }

  async detect(dependency, config) {
    // Implementation for each dependency
  }
}
```

### 1.2 PowerShell Module Structure
```powershell
# src/scripts/powershell/ClaudeCodeInstaller.psm1
function Test-SystemRequirements {
    [CmdletBinding()]
    param()
    
    $requirements = @{
        WindowsVersion = Test-WindowsVersion
        Architecture = Test-Architecture
        DiskSpace = Test-DiskSpace
        AdminRights = Test-AdminRights
        Network = Test-NetworkConnectivity
    }
    
    return $requirements
}

function Install-WSL2 {
    [CmdletBinding()]
    param(
        [switch]$SkipIfExists
    )
    
    # Smart installation logic
}
```

### 1.3 NSIS Installer Foundation
```nsis
; src/installer/main.nsi
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

Name "Claude Code for Windows"
OutFile "${DIST_DIR}\ClaudeCodeSetup.exe"
InstallDir "$LOCALAPPDATA\ClaudeCode"

; Version info
VIProductVersion "${VERSION}"
VIAddVersionKey "ProductName" "Claude Code for Windows"
VIAddVersionKey "CompanyName" "Anthropic"

; Modern UI Configuration
!define MUI_ABORTWARNING
!define MUI_ICON "${ASSETS_DIR}\claude-icon.ico"

; Custom pages
Page custom DependencyCheckPage
Page custom ProgressPage
```

## Phase 2: Installation Logic (Days 8-14)

### 2.1 Modular Installation Components

#### WSL2 Manager
```powershell
# src/scripts/powershell/WSL2Manager.ps1
class WSL2Manager {
    [bool] IsInstalled() {
        $wslStatus = & wsl --status 2>$null
        return $LASTEXITCODE -eq 0
    }
    
    [version] GetVersion() {
        $version = & wsl --version | Select-String -Pattern "WSL version: ([\d\.]+)"
        return [version]$matches[1]
    }
    
    [void] Install() {
        if ($this.IsInstalled()) {
            Write-Log "WSL2 already installed"
            return
        }
        
        # Enable features
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
        
        # Download and install kernel
        $this.InstallKernel()
    }
}
```

#### Alpine Setup Manager
```bash
#!/bin/bash
# src/scripts/bash/alpine-setup.sh

set -euo pipefail

# Configuration
REQUIRED_NODE_VERSION="18.0.0"
REQUIRED_NPM_VERSION="9.0.0"

# Functions
check_existing_tools() {
    local tools=("curl" "git" "node" "npm")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    echo "${missing[@]}"
}

install_node_if_needed() {
    if command -v node &> /dev/null; then
        local current_version=$(node --version | sed 's/v//')
        if version_ge "$current_version" "$REQUIRED_NODE_VERSION"; then
            echo "Node.js $current_version already installed"
            return 0
        fi
    fi
    
    echo "Installing Node.js..."
    apk add --no-cache nodejs npm
}
```

### 2.2 Progress Tracking System
```javascript
// src/installer/progress-tracker.js
class ProgressTracker {
    constructor(totalSteps) {
        this.totalSteps = totalSteps;
        this.currentStep = 0;
        this.stepDetails = [];
    }
    
    updateProgress(stepName, status, details = {}) {
        this.currentStep++;
        const progress = (this.currentStep / this.totalSteps) * 100;
        
        this.stepDetails.push({
            name: stepName,
            status: status,
            timestamp: new Date(),
            details: details
        });
        
        // Update UI
        this.notifyUI(progress, stepName, status);
    }
    
    notifyUI(progress, stepName, status) {
        // NSIS plugin call to update progress bar
        // PowerShell event for status updates
    }
}
```

## Phase 3: User Interface Implementation (Days 15-18)

### 3.1 NSIS Custom UI Pages
```nsis
; src/installer/ui/dependency-check.nsh
Function DependencyCheckPage
    nsDialogs::Create 1018
    Pop $0
    
    ${NSD_CreateLabel} 0 0 100% 20u "Checking system dependencies..."
    Pop $DependencyLabel
    
    ${NSD_CreateProgressBar} 0 30u 100% 12u ""
    Pop $ProgressBar
    
    ${NSD_CreateListBox} 0 50u 100% 100u ""
    Pop $DependencyList
    
    ; Start dependency check in background
    GetFunctionAddress $0 CheckDependenciesAsync
    nsExec::ExecToLog 'powershell.exe -File "$INSTDIR\scripts\check-deps.ps1"'
    
    nsDialogs::Show
FunctionEnd
```

### 3.2 Error Handling UI
```nsis
; src/installer/ui/error-handler.nsh
!macro ShowError ErrorTitle ErrorMessage ErrorCode
    MessageBox MB_OK|MB_ICONEXCLAMATION "${ErrorTitle}$\n$\n${ErrorMessage}$\n$\nError Code: ${ErrorCode}"
    
    ; Log error
    FileOpen $0 "$INSTDIR\install.log" a
    FileWrite $0 "[ERROR] ${ErrorCode}: ${ErrorMessage}$\r$\n"
    FileClose $0
!macroend
```

## Phase 4: Testing Framework (Days 19-22)

### 4.1 Unit Testing Setup
```javascript
// src/tests/unit/dependency-detector.test.js
describe('DependencyDetector', () => {
    let detector;
    
    beforeEach(() => {
        detector = new DependencyDetector();
    });
    
    test('detects WSL2 installation', async () => {
        // Mock PowerShell execution
        jest.spyOn(child_process, 'exec').mockImplementation((cmd, cb) => {
            if (cmd.includes('wsl --status')) {
                cb(null, 'WSL version: 2.0.9.0', '');
            }
        });
        
        const result = await detector.detect('wsl2');
        expect(result.installed).toBe(true);
        expect(result.version).toBe('2.0.9.0');
    });
});
```

### 4.2 Integration Testing
```powershell
# src/tests/integration/full-install.ps1
Describe "Full Installation Flow" {
    BeforeAll {
        # Setup test environment
        $script:TestVM = New-TestVM -Name "ClaudeCodeTest" -Windows10
        $script:TestVM.Start()
    }
    
    It "Completes installation on clean Windows 10" {
        $result = Invoke-Command -VMName $script:TestVM.Name -ScriptBlock {
            & "C:\ClaudeCodeSetup.exe" /S /D=C:\TestInstall
            $LASTEXITCODE
        }
        
        $result | Should -Be 0
    }
    
    It "Claude Code launches after installation" {
        $claudeExists = Invoke-Command -VMName $script:TestVM.Name -ScriptBlock {
            Test-Path "C:\TestInstall\claude.exe"
        }
        
        $claudeExists | Should -Be $true
    }
}
```

## Phase 5: Build and Release Pipeline (Days 23-25)

### 5.1 Build Script
```makefile
# Makefile
VERSION := 1.0.0
BUILD_DIR := build
DIST_DIR := dist
NSIS := makensis

.PHONY: all clean build sign test

all: clean build sign

clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)

build: prepare
	$(NSIS) -DVERSION=$(VERSION) \
	        -DDIST_DIR=$(DIST_DIR) \
	        -DASSETS_DIR=src/installer/assets \
	        src/installer/main.nsi

prepare:
	mkdir -p $(BUILD_DIR) $(DIST_DIR)
	cp -r src/scripts $(BUILD_DIR)/
	
sign:
	# Sign with certificate (Windows only)
	@echo "Code signing must be done on Windows"

test:
	npm test
	pwsh -File src/tests/run-tests.ps1
```

### 5.2 GitHub Actions CI/CD
```yaml
# .github/workflows/build.yml
name: Build and Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install NSIS
        run: sudo apt-get update && sudo apt-get install -y nsis
      
      - name: Build installer
        run: make build
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: installer-unsigned
          path: dist/

  test-windows:
    needs: build-linux
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Download installer
        uses: actions/download-artifact@v3
        with:
          name: installer-unsigned
      
      - name: Run tests
        run: |
          Import-Module Pester
          Invoke-Pester src/tests/integration -OutputFormat NUnitXml
```

## Phase 6: Documentation and Support (Days 26-28)

### 6.1 User Documentation Structure
```
docs/
├── user-guide/
│   ├── quick-start.md
│   ├── troubleshooting.md
│   └── faq.md
├── admin-guide/
│   ├── group-policy.md
│   ├── silent-install.md
│   └── network-requirements.md
├── developer/
│   ├── architecture.md
│   ├── contributing.md
│   └── testing.md
└── legal/
    ├── privacy-policy.md
    └── terms-of-use.md
```

### 6.2 Automated Documentation Generation
```javascript
// tools/generate-docs.js
const fs = require('fs');
const path = require('path');

function generateErrorReference() {
    const errors = require('../src/config/error-codes.json');
    let markdown = '# Error Code Reference\n\n';
    
    for (const [code, details] of Object.entries(errors)) {
        markdown += `## Error ${code}: ${details.title}\n\n`;
        markdown += `**Description:** ${details.description}\n\n`;
        markdown += `**Solution:** ${details.solution}\n\n`;
        markdown += '---\n\n';
    }
    
    fs.writeFileSync('docs/user-guide/error-reference.md', markdown);
}
```

## Development Timeline

### Week 1-2: Foundation
- [ ] Set up NixOS development environment
- [ ] Create project structure
- [ ] Implement dependency detection
- [ ] Basic NSIS installer shell

### Week 3-4: Core Installation
- [ ] WSL2 automation
- [ ] Alpine setup scripts
- [ ] Progress tracking system
- [ ] Error handling framework

### Week 5: Integration
- [ ] Claude Code installation logic
- [ ] Configuration management
- [ ] Windows shortcuts/registry

### Week 6: Testing
- [ ] Unit test suite
- [ ] Windows VM testing
- [ ] Performance optimization
- [ ] Bug fixes

### Week 7: Polish
- [ ] UI/UX improvements
- [ ] Documentation
- [ ] Code signing setup
- [ ] Release preparation

### Week 8: Release
- [ ] Final testing
- [ ] Release packaging
- [ ] Distribution setup
- [ ] Launch materials

## Key Development Considerations

### 1. Cross-Platform Development on NixOS

**Development Workflow:**
```nix
# shell.nix for reproducible dev environment
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nsis
    powershell
    nodejs
    wine64
    qemu
    
    # Testing tools
    python3
    python3Packages.pytest
  ];
  
  shellHook = ''
    echo "Claude Code Installer Dev Environment"
    echo "Run 'make build' to create installer"
  '';
}
```

### 2. Testing Strategy Without Windows

**Mock Testing Approach:**
```javascript
// Mock WSL commands for Linux testing
class WSLMock {
    constructor() {
        this.distributions = ['Alpine', 'Ubuntu'];
        this.version = '2.0.9.0';
    }
    
    exec(command) {
        if (command.includes('--list')) {
            return this.distributions.join('\n');
        }
        if (command.includes('--version')) {
            return `WSL version: ${this.version}`;
        }
    }
}
```

### 3. Continuous Integration

**Multi-Stage Testing:**
1. **Linux Stage**: Build, unit tests, static analysis
2. **Windows Stage**: Integration tests, installer validation
3. **Release Stage**: Code signing, distribution packaging

## Risk Mitigation Strategies

### Technical Risks
1. **NSIS Limitations**
   - Mitigation: Use external PowerShell for complex logic
   - Fallback: Consider WiX Toolset if needed

2. **WSL2 API Changes**
   - Mitigation: Version detection and compatibility layer
   - Fallback: Multiple installation strategies

3. **Antivirus Interference**
   - Mitigation: Early vendor communication
   - Fallback: Detailed exclusion documentation

### Development Risks
1. **Limited Windows Testing**
   - Mitigation: Automated VM testing
   - Solution: GitHub Actions Windows runners

2. **Debugging Challenges**
   - Mitigation: Comprehensive logging
   - Solution: Remote Windows test machine

## Success Metrics

- **Development Velocity**: 2-3 features per week
- **Test Coverage**: >80% for critical paths
- **Build Time**: <5 minutes
- **Installer Size**: <50MB
- **Installation Success Rate**: >95%

## Next Steps

1. **Immediate Actions:**
   - Set up Git repository
   - Create development environment
   - Start dependency detector implementation

2. **Week 1 Deliverables:**
   - Working NSIS build system
   - Basic installer that shows UI
   - Dependency detection prototype

3. **Communication:**
   - Weekly progress updates
   - Demo after each phase
   - Early testing with target users
