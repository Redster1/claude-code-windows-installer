# Claude Development Session Memory

This file contains important context and lessons learned for future Claude sessions.

## Project Context
- Claude Code Windows Installer for non-technical users (lawyers)
- Uses NSIS for Windows installer, PowerShell for Windows automation, Bash for Alpine setup
- Cross-platform development on NixOS targeting Windows
- Architecture: NSIS + PowerShell + WSL2 + Alpine Linux + Node.js + Claude Code CLI

## Key Files
- `src/installer/main.nsi` - Main NSIS installer script
- `src/scripts/powershell/ClaudeCodeInstaller.psm1` - PowerShell automation module  
- `src/scripts/bash/alpine-setup.sh` - Alpine Linux setup script
- `Makefile` - Build system
- `shell.nix` - Development environment

## CRITICAL Build Issues & Solutions

### NSIS Build Path Problems
**Problem**: `make build` fails with "Can't open output file" even though build seems to complete
**Root Cause**: NSIS needs absolute paths, Makefile uses relative paths
**Solution**: Use absolute paths in makensis command:
```bash
nix-shell --run "makensis -DVERSION=1.2.0 -DDIST_DIR=/home/reese/Documents/devprojects/claude-code-windows-installer/dist -DASSETS_DIR=generated-images -DBUILD_DIR=build src/installer/main.nsi"
```

### NSIS Function Parameters  
**Problem**: `Call CheckDistributionForTools "debian" $7` syntax error - "Call expects 1 parameters, got 3"
**Solution**: Use Push/Pop pattern:
```nsis
Push "debian"
Call CheckDistributionForTools  
Pop $7
```

### NSIS Asset Loading
**Problem**: Icon/bitmap files fail to load with "can't open file"
**Root Cause**: Asset files in src/installer/assets are tiny stubs, real files in generated-images/
**Workaround**: Disable asset definitions temporarily:
```nsis
; !define MUI_ICON "generated-images/claude-icon.ico"
```

### Git Operations
**Problem**: dist/ directory is .gitignored
**Solution**: Force add installer: `git add -f dist/ClaudeCodeSetup.exe`

**Problem**: Tag already exists on remote
**Solution**: Delete local tag, create new version: `git tag -d v1.1.0 && git tag -a v1.2.0`

### GitHub Release
**Working Command**:
```bash
gh release create v1.2.0 --title "Title" --notes "Description" dist/ClaudeCodeSetup.exe
```

## Development Environment Rules
- **ALL build commands must run inside**: `nix-shell --run "command"`
- NSIS v3.11, PowerShell 7.5.1, Node.js v22.14.0 available in shell
- Use absolute paths for NSIS output files
- Asset files need proper path resolution (still needs fixing)

## Important Commands
- `nix-shell --run "make build"` - Build installer in Nix environment
- `make dev-setup` - Check development environment
- `make clean` - Clean build artifacts

## Project Status - v1.2.0 Released
- ✅ Smart WSL distribution detection (15+ distros supported)
- ✅ Skip Alpine if compatible distro with claude-code exists  
- ✅ Build issues resolved with absolute paths
- ✅ GitHub release created with installer
- ⚠️ Asset loading still needs fixing for icons/images
- ⚠️ PowerShell module file extraction still disabled (TODO)