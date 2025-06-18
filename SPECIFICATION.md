# Claude Code Windows Installer - Technical Specification

## Project Overview

### Purpose
Create a user-friendly Windows installer (.exe) that enables non-technical users (specifically lawyers) to install and run Claude Code without any terminal or command-line interaction. The installer will automatically set up WSL2, Alpine Linux, and Claude Code in a seamless, one-click (ideally, but not required) experience.

### Target Audience
- Legal professionals with minimal technical expertise
- Windows users who cannot or will not switch operating systems
- Users without Node.js, npm, or development tools installed
- Users who prefer GUI interfaces over command-line tools

### Success Criteria
- ✅ Installation completes without user needing to open a terminal
- ✅ Claude Code launches successfully post-installation
- ✅ Works on standard Windows 10/11 business environments
- ✅ Installation time under 15 minutes on typical hardware
- ✅ Uninstall removes all components cleanly
- ✅ 95%+ success rate across target Windows configurations

## Technical Requirements

### Minimum System Requirements
- **OS**: Windows 10 version 2004 (Build 19041) or Windows 11
- **Architecture**: x64 processor
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free disk space
- **Network**: Internet connection for downloads
- **Privileges**: Administrator access (UAC elevation)

### Prerequisites Validation
- Check Windows version compatibility
- Verify x64 architecture
- Confirm available disk space
- Test internet connectivity
- Validate user has admin rights
- Check for existing WSL installations
- Scan for conflicting virtualization software
- **Detect existing dependencies (WSL2, Node.js, Git, Curl)**
- **Version compatibility checks for existing tools**

### Dependencies
- Windows Subsystem for Linux (WSL2)
- Alpine Linux distribution
- Node.js LTS (to be installed in Alpine)
- npm package manager
- Claude Code CLI package

## Installation Architecture

### Technology Stack
- **Installer Framework**: NSIS (Nullsoft Scriptable Install System) or WiX Toolset
- **Scripting**: PowerShell for Windows operations
- **WSL Management**: wsl.exe commands via PowerShell
- **Progress Tracking**: Custom progress dialog with real-time updates
- **Error Handling**: Comprehensive logging and user-friendly error messages

### Component Breakdown

#### 1. Pre-Installation Validator
```
├── System Requirements Checker
├── Prerequisites Validator  
├── Conflict Detection Engine
├── Disk Space Analyzer
├── Network Connectivity Tester
├── Existing Dependency Scanner (WSL2, Node.js, Git, Curl)
└── Version Compatibility Validator
```

#### 2. WSL2 Installation Engine
```
├── Windows Feature Enabler (WSL, Virtual Machine Platform)
├── WSL2 Kernel Installer (skip if existing compatible version)
├── System Reboot Handler
├── WSL Configuration Manager
├── Alpine Linux Distribution Installer (skip if existing)
└── Existing WSL Distribution Validator
```

#### 3. Alpine Linux Setup Engine
```
├── Package Manager Updater (apk)
├── Essential Tools Installer (curl, git, etc.) - skip if existing
├── Node.js LTS Installer (skip if compatible version exists)
├── npm Configuration (skip if existing)
├── Environment Setup
└── Dependency Version Compatibility Checker
```

#### 4. Claude Code Installation Engine
```
├── Claude Code CLI Installer (npm install -g @anthropic-ai/claude-code)
├── Configuration File Generator
├── Desktop Shortcut Creator
├── Start Menu Entry Creator
└── Quick Launch Setup
```

#### 5. Post-Installation Validator
```
├── Installation Verification
├── Claude Code Launch Test
├── Configuration Validation
└── Success Notification
```

## Dependency Detection and Version Management

### Existing Dependency Detection Strategy

The installer must be designed to coexist with existing development environments without disrupting user configurations or overwriting newer versions of dependencies.

#### Detection Logic Flow
```
┌─────────────────────────────────────┐
│  Pre-Installation Dependency Scan  │
│                                     │
│  1. WSL2 Detection                  │
│     ├── Check Windows features      │
│     ├── Validate WSL kernel version │
│     └── List existing distributions │
│                                     │
│  2. Node.js Detection               │
│     ├── Check Windows Node.js       │
│     ├── Check WSL Node.js           │
│     ├── Validate version compat.    │
│     └── Check npm configuration     │
│                                     │
│  3. Essential Tools Detection       │
│     ├── Git (Windows & WSL)         │
│     ├── Curl (Windows & WSL)        │
│     ├── Other dev tools             │
│     └── PATH configurations         │
│                                     │
│  4. Claude Code Detection           │
│     ├── Global npm installation     │
│     ├── Local project installations │
│     ├── Version compatibility       │
│     └── Configuration files         │
└─────────────────────────────────────┘
```

#### Version Compatibility Matrix
| Dependency | Minimum Required | Recommended | Skip Installation If |
|------------|------------------|-------------|---------------------|
| WSL2 | WSL 2 | Latest | WSL 2 enabled with compatible kernel |
| Node.js | v18.0.0 | v20.x LTS | v18.0.0+ already installed |
| npm | v9.0.0 | v10.x | v9.0.0+ already installed |
| Git | v2.30.0 | Latest | v2.30.0+ already installed |
| Curl | v7.70.0 | Latest | v7.70.0+ already installed |
| Claude Code | Any | Latest | Any version already installed |

#### Smart Installation Decisions
```powershell
# Example detection logic for Node.js
function Test-NodeJsCompatibility {
    $nodeVersion = $null
    $npmVersion = $null
    
    # Check Windows Node.js
    try {
        $nodeVersion = (node --version 2>$null) -replace 'v', ''
        $npmVersion = (npm --version 2>$null)
    }
    catch {
        Write-Host "Node.js not found on Windows"
    }
    
    # Check WSL Node.js
    try {
        $wslNodeVersion = (wsl -- node --version 2>$null) -replace 'v', ''
        $wslNpmVersion = (wsl -- npm --version 2>$null)
    }
    catch {
        Write-Host "Node.js not found in WSL"
    }
    
    # Version comparison logic
    $requiredNodeVersion = "18.0.0"
    
    if ($nodeVersion -and ([version]$nodeVersion -ge [version]$requiredNodeVersion)) {
        return @{
            Skip = $true
            Reason = "Compatible Node.js v$nodeVersion found on Windows"
            Location = "Windows"
        }
    }
    
    if ($wslNodeVersion -and ([version]$wslNodeVersion -ge [version]$requiredNodeVersion)) {
        return @{
            Skip = $true
            Reason = "Compatible Node.js v$wslNodeVersion found in WSL"
            Location = "WSL"
        }
    }
    
    return @{
        Skip = $false
        Reason = "No compatible Node.js installation found"
        RequiredAction = "Install Node.js v$requiredNodeVersion+ in Alpine Linux"
    }
}
```

#### User Communication for Existing Dependencies
When existing compatible dependencies are found, the installer should clearly communicate this to users:

```
┌─────────────────────────────────────┐
│  Dependency Check Results           │
│                                     │
│  ✓ WSL2 - Compatible version found  │
│    Version: WSL 2.0.9.0             │
│    Status: Will use existing        │
│                                     │
│  ✓ Node.js - Compatible version     │
│    Version: v20.11.0 (Windows)      │
│    Status: Will use existing        │
│                                     │
│  ⚠ Git - Version too old            │
│    Found: v2.25.0                   │
│    Required: v2.30.0+               │
│    Status: Will upgrade in WSL      │
│                                     │
│  ✗ Claude Code - Not installed      │
│    Status: Will install             │
│                                     │
│  Estimated time: 3-5 minutes        │
│  (Reduced due to existing deps)     │
│                                     │
│  [Continue]           [Cancel]      │
└─────────────────────────────────────┘
```

### Non-Destructive Installation Principles

#### 1. Preservation of Existing Configurations
- **Never overwrite** existing configuration files
- **Backup** any configurations that must be modified
- **Merge** new settings with existing ones where possible
- **Prompt** user for conflict resolution when necessary

#### 2. Path and Environment Management
- **Detect** existing PATH modifications
- **Append** to PATH rather than replace
- **Use** WSL-specific configurations to avoid Windows conflicts
- **Validate** PATH changes don't break existing functionality

#### 3. Package Manager Isolation
- **Use** Alpine's package manager for WSL dependencies
- **Avoid** conflicting with Windows package managers
- **Respect** existing npm global configurations
- **Create** separate npm directories if needed

#### 4. Version Coexistence Strategy
- **Multiple Node.js versions**: Use WSL-isolated installation
- **Multiple Git installations**: Prefer WSL Git for Claude Code
- **Claude Code versions**: Support multiple project-specific versions

## Detailed Installation Flow

### Phase 1: Pre-Installation (2-3 minutes)
1. **Welcome Screen**
   - Project introduction
   - System requirements overview
   - Installation time estimate
   - Privacy policy and terms

2. **System Validation**
   ```
   ✓ Checking Windows version compatibility
   ✓ Verifying system architecture (x64)
   ✓ Confirming available disk space (10GB+)
   ✓ Testing internet connectivity
   ✓ Validating administrator privileges
   ✓ Scanning for existing WSL installations
   ✓ Checking for virtualization conflicts
   ✓ Detecting existing dependencies (WSL2, Node.js, Git, Curl)
   ✓ Validating existing dependency versions
   ```

3. **Installation Path Selection**
   - Default: `C:\Users\{Username}\AppData\Local\ClaudeCode\`
   - Custom path option for advanced users
   - Path validation and creation

### Phase 2: WSL2 Setup (5-8 minutes or skip if existing)
1. **Windows Features Activation** *(Skip if WSL2 already enabled)*
   ```powershell
   # Check if features already enabled
   Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
   Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
   
   # Only enable if not already active
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

2. **WSL2 Kernel Installation** *(Skip if compatible version exists)*
   ```powershell
   # Check existing WSL version
   wsl --status
   
   # Only install if needed
   - Download latest WSL2 kernel update
   - Silent installation: `wsl_update_x64.msi /quiet`
   - Set WSL2 as default version
   ```

3. **Reboot Handling** *(Only if changes were made)*
   - Check if reboot is required based on actual changes
   - Schedule installer continuation post-reboot
   - User notification with countdown timer

4. **Alpine Linux Installation** *(Skip if existing compatible distribution)*
   ```bash
   # Check existing distributions
   wsl --list --verbose
   
   # Only install if needed
   wsl --install -d Alpine
   wsl --set-default Alpine
   ```

### Phase 3: Linux Environment Setup (3-4 minutes or less if existing)
1. **Alpine Linux Configuration**
   ```bash
   # Update package repositories (always do this)
   apk update && apk upgrade
   
   # Check for existing tools before installing
   command -v curl >/dev/null 2>&1 || apk add curl
   command -v git >/dev/null 2>&1 || apk add git
   command -v bash >/dev/null 2>&1 || apk add bash
   command -v nano >/dev/null 2>&1 || apk add nano
   
   # Create user account (non-root) - skip if exists
   id -u claudeuser >/dev/null 2>&1 || adduser -D -s /bin/bash claudeuser
   ```

2. **Node.js Installation** *(Skip if compatible version exists)*
   ```bash
   # Check for existing Node.js installation
   if ! command -v node >/dev/null 2>&1; then
       echo "Installing Node.js and npm..."
       apk add nodejs npm
   else
       NODE_VERSION=$(node --version | cut -d'v' -f2)
       REQUIRED_VERSION="18.0.0"
       if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
           echo "Compatible Node.js version found: $NODE_VERSION"
       else
           echo "Node.js version $NODE_VERSION is too old, upgrading..."
           apk add nodejs npm
       fi
   fi
   
   # Verify installation
   node --version
   npm --version
   ```

3. **Environment Configuration** *(Skip existing configurations)*
   - Check existing PATH variables before modifying
   - Configure npm global directory (skip if already configured)
   - Create necessary directories (skip if they exist)

### Phase 4: Claude Code Installation (2-3 minutes or skip if existing)
1. **Claude Code CLI Installation** *(Skip if compatible version exists)*
   ```bash
   # Check if Claude Code is already installed
   if command -v claude >/dev/null 2>&1; then
       CLAUDE_VERSION=$(claude --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
       echo "Claude Code found: version $CLAUDE_VERSION"
       
       # Check if version is compatible (you can define minimum version)
       REQUIRED_VERSION="1.0.0"  # Adjust as needed
       if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$CLAUDE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
           echo "Compatible Claude Code version found, skipping installation"
       else
           echo "Claude Code version $CLAUDE_VERSION is too old, upgrading..."
           npm install -g @anthropic-ai/claude-code
       fi
   else
       echo "Installing Claude Code..."
       npm install -g @anthropic-ai/claude-code
   fi
   ```

2. **Configuration Setup**
   - Create default configuration files
   - Set up authentication placeholders
   - Configure working directories

3. **Windows Integration**
   - Create desktop shortcut
   - Add Start Menu entry
   - Register file associations (if applicable)
   - Create quick launch scripts

### Phase 5: Verification & Completion (1 minute)
1. **Installation Verification**
   ```bash
   claude --version
   claude --help
   ```

2. **Test Launch**
   - Execute minimal Claude Code command
   - Verify WSL2 and Alpine communication
   - Confirm all components are functional

3. **Success Notification**
   - Installation summary
   - Next steps guide
   - Launch Claude Code option

## User Experience Design

### Installation Wizard UI

#### Welcome Screen
```
┌─────────────────────────────────────┐
│  Claude Code for Windows Setup     │
│                                     │
│  Welcome to the Claude Code        │
│  installation wizard.              │
│                                     │
│  This will install:                │
│  • Windows Subsystem for Linux 2   │
│  • Alpine Linux                    │
│  • Claude Code CLI                 │
│                                     │
│  Estimated time: 10-15 minutes     │
│                                     │
│  [Cancel]           [Next >]       │
└─────────────────────────────────────┘
```

#### Progress Screen
```
┌─────────────────────────────────────┐
│  Installing Claude Code...          │
│                                     │
│  Current Step: Installing WSL2     │
│  ████████░░░░░░░░░░  40%           │
│                                     │
│  ✓ System validation complete      │
│  ✓ Downloaded WSL2 kernel          │
│  → Installing Windows features     │
│    Alpine Linux setup              │
│    Claude Code installation        │
│                                     │
│  [Cancel]                          │
└─────────────────────────────────────┘
```

### Error Handling Strategy

#### Common Error Scenarios
1. **Insufficient Privileges**
   ```
   ❌ Administrator access required
   
   This installer needs administrator privileges to:
   • Enable Windows features (WSL2)
   • Install system components
   • Create shortcuts and registry entries
   
   Please right-click the installer and select
   "Run as administrator"
   
   [Retry]  [Cancel]
   ```

2. **Incompatible Windows Version**
   ```
   ❌ Windows version not supported
   
   Claude Code requires:
   • Windows 10 version 2004 (Build 19041) or later
   • Windows 11 (any version)
   
   Your system: Windows 10 Build 18363
   
   Please update Windows and try again.
   
   [Check for Updates]  [Cancel]
   ```

3. **Network Connectivity Issues**
   ```
   ❌ Internet connection required
   
   The installer needs to download:
   • WSL2 kernel update (~100MB)
   • Alpine Linux (~5MB)
   • Node.js packages (~50MB)
   
   Please check your internet connection and try again.
   
   [Retry]  [Cancel]
   ```

4. **Disk Space Insufficient**
   ```
   ❌ Insufficient disk space
   
   Required: 10GB free space
   Available: 3.2GB
   
   Please free up disk space or choose a different
   installation location.
   
   [Choose Location]  [Cancel]
   ```

## Security Considerations

### Code Signing
- Sign the installer executable with a valid certificate
- Include company information and version details
- Ensure Windows SmartScreen compatibility

### Antivirus Compatibility
- Test with major antivirus solutions (Windows Defender, Norton, McAfee)
- Implement antivirus exclusion recommendations
- Provide whitelisting instructions if needed

### Network Security
- Use HTTPS for all downloads
- Verify download integrity with checksums
- Implement certificate pinning for critical downloads

### User Data Protection
- Minimal data collection during installation
- Clear privacy policy
- Secure temporary file handling
- Clean removal of temporary files

## Testing Strategy

### Target Test Environments
1. **Windows 10 Pro (Build 19041)** - Clean install
2. **Windows 10 Home (Build 19042)** - With existing software
3. **Windows 11 Pro** - Domain-joined corporate environment
4. **Windows 11 Home** - Consumer environment with antivirus

### Test Scenarios

#### Happy Path Testing
- ✅ Clean Windows installation
- ✅ Installation with standard user account
- ✅ Installation with existing WSL1
- ✅ Installation over previous version

#### Edge Case Testing
- ❌ Limited disk space scenarios
- ❌ Network interruption during download
- ❌ Antivirus interference
- ❌ Corporate proxy environments
- ❌ Non-English Windows installations
- ❌ Systems with virtualization conflicts

#### Dependency Coexistence Testing
- ✅ **Existing WSL1** - Upgrade to WSL2 without breaking existing distributions
- ✅ **Existing WSL2** - Use existing installation, add Alpine distribution
- ✅ **Existing Node.js** (Windows) - Use existing compatible version
- ✅ **Existing Node.js** (WSL) - Use existing compatible version in target distribution
- ✅ **Older Node.js versions** - Install newer version in Alpine without affecting Windows
- ✅ **Multiple WSL distributions** - Don't interfere with Ubuntu, Debian, etc.
- ✅ **Existing Git configurations** - Preserve .gitconfig files and SSH keys
- ✅ **Corporate npm configurations** - Respect existing registries and proxies
- ✅ **Existing Claude Code** - Skip installation, validate compatibility
- ❌ **Version conflicts** - Handle incompatible dependency versions gracefully
- ❌ **Corrupted installations** - Detect and handle partial/broken dependency installs

#### Stress Testing
- Multiple simultaneous installations
- Installation on slow hardware
- Installation with limited RAM
- Network throttling scenarios

### Acceptance Criteria
- ✅ 95% success rate across test environments
- ✅ Installation completes in under 15 minutes
- ✅ Claude Code launches successfully post-install
- ✅ Clean uninstallation removes all components
- ✅ No conflicts with existing software

## Distribution Strategy

### Packaging
- Single executable installer (.exe)
- Embedded resources (no external dependencies)
- Digital signature and certificate validation
- Version information and metadata

### Distribution Channels
1. **Primary**: Direct download from project website
2. **Secondary**: GitHub releases
3. **Future**: Microsoft Store (if approved)

### Update Mechanism
- Built-in update checker
- Automatic update notifications
- Incremental update support
- Rollback capability for failed updates

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Set up development environment
- [ ] Create basic installer shell (NSIS/WiX)
- [ ] Implement system validation logic
- [ ] Create UI mockups and designs

### Phase 2: Core Installation (Week 3-4)
- [ ] WSL2 installation automation
- [ ] Alpine Linux setup scripts
- [ ] Error handling framework
- [ ] Progress tracking system

### Phase 3: Claude Code Integration (Week 5)
- [ ] Node.js and npm installation
- [ ] Claude Code CLI installation
- [ ] Configuration file generation
- [ ] Windows integration (shortcuts, etc.)

### Phase 4: Testing & Polish (Week 6-7)
- [ ] Comprehensive testing across environments
- [ ] UI/UX refinement
- [ ] Performance optimization
- [ ] Documentation creation

### Phase 5: Release Preparation (Week 8)
- [ ] Code signing setup
- [ ] Final testing and validation
- [ ] Distribution package creation
- [ ] Launch documentation

## Risk Mitigation

### High-Risk Items
1. **WSL2 Installation Failures**
   - Mitigation: Comprehensive pre-checks, clear error messages
   - Fallback: Manual installation guide

2. **Antivirus False Positives**
   - Mitigation: Code signing, antivirus vendor communication
   - Fallback: Exclusion instructions, support documentation

3. **Corporate Environment Restrictions**
   - Mitigation: Group Policy compatibility testing
   - Fallback: IT administrator installation guide

4. **Network Connectivity Issues**
   - Mitigation: Offline installation option (larger package)
   - Fallback: Manual download links and instructions

### Success Metrics
- Installation success rate > 95%
- User satisfaction score > 4.5/5
- Support tickets < 5% of installations
- Installation time < 15 minutes average

## Support and Documentation

### User Documentation
- Quick Start Guide
- Troubleshooting FAQ
- Video installation walkthrough
- Legal profession use cases

### Technical Documentation
- System Administrator Guide
- Group Policy deployment instructions
- Network requirements documentation
- Uninstallation procedures

### Support Resources
- GitHub Issues for bug reports
- Email support for lawyers
- Community forum
- Video tutorials library

---
See PLAN.MD for the plan to implement this spec.

*This specification document will be updated as the project evolves and requirements are refined.*
