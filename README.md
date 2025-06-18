# Claude Code Windows Installer

A user-friendly Windows installer for Claude Code CLI designed specifically for non-technical users, particularly legal professionals. This installer automatically sets up WSL2, Alpine Linux, and Claude Code without requiring any command-line interaction.

## 🎯 Project Goals

- **One-click installation** of Claude Code on Windows
- **No technical knowledge required** - designed for lawyers and professionals
- **Intelligent dependency detection** - respects existing installations
- **Comprehensive error handling** with user-friendly messages
- **Professional installer experience** with progress tracking

## 🏗️ Architecture

### Technology Stack
- **NSIS** - Installer framework for Windows
- **PowerShell** - Windows automation and system management
- **Bash** - Alpine Linux configuration scripts
- **Node.js/JavaScript** - Dependency detection and validation
- **WSL2 + Alpine Linux** - Execution environment for Claude Code

### Project Structure
```
claude-code-windows-installer/
├── src/
│   ├── installer/           # NSIS installer scripts and UI
│   ├── scripts/
│   │   ├── powershell/      # Windows automation modules
│   │   ├── bash/            # Alpine Linux setup scripts
│   │   └── validation/      # Dependency detection
│   ├── config/              # Configuration and defaults
│   └── tests/               # Unit and integration tests
├── build/                   # Build artifacts
├── dist/                    # Distribution packages
├── docs/                    # Documentation
└── tools/                   # Development tools
```

## 🚀 Quick Start

### Prerequisites
- NixOS/Linux development environment
- NSIS (Nullsoft Scriptable Install System)
- PowerShell Core
- Node.js and npm

### Development Setup
```bash
# Enter development environment
nix-shell

# Install dependencies
npm install

# Check development environment
make dev-setup

# Build installer
make build
```

### Using the Development Environment
```bash
# Build the installer
make build

# Run tests
make test

# Clean build artifacts
make clean

# Show help
make help
```

## 📋 Features

### Smart Dependency Detection
The installer intelligently detects existing installations and skips unnecessary components:

- **WSL2** - Checks for existing WSL2 installation and version compatibility
- **Node.js** - Detects Node.js on both Windows and WSL environments
- **Git & Curl** - Identifies existing tools to avoid conflicts
- **Claude Code** - Never overwrites existing Claude Code installations

### User Experience
- **Professional UI** with progress tracking and clear status messages
- **Comprehensive error handling** with actionable solutions
- **Minimal user interaction** - mostly automated process
- **Estimated time display** based on what needs to be installed
- **Detailed logging** for troubleshooting

### Installation Process
1. **System Validation** - Check Windows version, architecture, privileges
2. **Dependency Scan** - Detect existing components and versions
3. **WSL2 Setup** - Install and configure WSL2 (if needed)
4. **Alpine Linux** - Install and configure Alpine distribution
5. **Development Tools** - Install Node.js, Git, Curl (if needed)
6. **Claude Code** - Install Claude Code CLI via npm
7. **Finalization** - Create shortcuts, register uninstaller

## 🧪 Testing

### Unit Tests
```bash
npm test
```

### Integration Tests
```bash
# PowerShell tests (requires Windows VM)
pwsh -File src/tests/run-tests.ps1
```

### Manual Testing
Test the installer on various Windows configurations:
- Clean Windows 10/11 installations
- Systems with existing WSL1/WSL2
- Systems with existing Node.js installations
- Corporate environments with restrictions

## 🔧 Configuration

### Customizing Installation
Edit `src/config/defaults.json` to modify:
- Minimum version requirements
- Installation phases and timing
- UI text and branding
- Error messages and solutions

### Example Configuration
```json
{
  \"dependencies\": {
    \"nodejs\": {
      \"minVersion\": \"18.0.0\",
      \"recommended\": \"20.11.0\"
    }
  },
  \"installation\": {
    \"phases\": [
      {
        \"name\": \"System Validation\",
        \"estimatedMinutes\": 1
      }
    ]
  }
}
```

## 📖 Documentation

- [**SPECIFICATION.md**](SPECIFICATION.md) - Detailed technical specification
- [**PLAN.md**](PLAN.md) - Implementation roadmap and development plan
- **Building Guide** - Instructions for building the installer
- **Testing Guide** - Comprehensive testing procedures

## 🎯 Target Users

### Legal Professionals
- Corporate lawyers needing Claude Code for document analysis
- Solo practitioners wanting AI assistance
- Law firms deploying to multiple machines
- Legal tech teams evaluating Claude Code

### Technical Requirements
- Windows 10 version 2004 (build 19041) or later
- x64 processor architecture
- 8GB RAM minimum (16GB recommended)
- 10GB free disk space
- Internet connection for downloads
- Administrator privileges

## 🚦 Current Status

### Phase 1: Foundation ✅
- [x] Project structure and build system
- [x] Dependency detection engine
- [x] Basic NSIS installer shell
- [x] PowerShell automation modules
- [x] Alpine Linux setup scripts

### Phase 2: Core Installation (In Progress)
- [ ] WSL2 installation automation
- [ ] Error handling and recovery
- [ ] Progress tracking system
- [ ] Reboot handling

### Phase 3: Integration (Planned)
- [ ] Claude Code installation logic
- [ ] Windows integration (shortcuts, etc.)
- [ ] Configuration management

### Phase 4: Polish (Planned)
- [ ] UI/UX improvements
- [ ] Comprehensive testing
- [ ] Documentation completion
- [ ] Code signing setup

## 🤝 Contributing

This project is designed to help legal professionals access Claude Code easily. Contributions are welcome!

### Development Workflow
1. Use the provided Nix development environment
2. Follow the testing procedures
3. Update documentation as needed
4. Test on multiple Windows configurations

### Testing Help Needed
We especially need help testing on:
- Various Windows 10/11 configurations
- Corporate environments with group policies
- Systems with existing development tools
- Different antivirus software configurations

## 📄 License

This project is open source. Please check the LICENSE file for details.

## 🆘 Support

- **GitHub Issues** - Bug reports and feature requests
- **Documentation** - Comprehensive guides and troubleshooting
- **Testing** - Help us test on different Windows configurations

---

**Building bridges between legal professionals and AI technology, one installation at a time.** 🏗️⚖️🤖