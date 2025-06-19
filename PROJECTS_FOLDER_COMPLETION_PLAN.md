# Projects Folder Feature Completion Plan

## Current Status
- ✅ Projects folder selection page implemented
- ✅ Shortcut creation with --cd parameter working  
- ✅ Basic installer builds (108KB) but missing critical components
- ❌ Assets disabled (icons, bitmaps)
- ❌ PowerShell modules disabled 
- ❌ Bash scripts disabled
- ❌ Config files disabled

## Problem Analysis
The installer is currently minimal and won't work properly because:
1. No PowerShell modules = No WSL2 installation automation
2. No bash scripts = No Alpine setup
3. No assets = No professional appearance or proper shortcuts
4. No config = No default settings

## Re-enablement Plan

### Phase 1: Re-enable UI Assets
**Files to modify:** `src/installer/main.nsi` lines 33-41
- Uncomment MUI_ICON definition
- Uncomment MUI_WELCOMEFINISHPAGE_BITMAP  
- Uncomment MUI_HEADERIMAGE definitions
- Test build for asset loading issues

### Phase 2: Re-enable Asset File Extraction  
**Files to modify:** `src/installer/main.nsi` lines 886-888
- Uncomment File commands for generated-images
- Use correct path syntax: `File "generated-images\claude-icon.ico"`
- Test icon availability for shortcuts

### Phase 3: Re-enable PowerShell Module Extraction
**Files to modify:** `src/installer/main.nsi` lines 892-894  
- Uncomment PowerShell script extraction
- Fix path syntax: `File "${BUILD_DIR}\scripts\powershell\ClaudeCodeInstaller.psm1"`
- Ensure build/ directory has the files via Makefile

### Phase 4: Re-enable Bash Script Extraction
**Files to modify:** `src/installer/main.nsi` lines 897-898
- Uncomment bash script extraction  
- Fix path syntax: `File "${BUILD_DIR}\scripts\bash\alpine-setup.sh"`

### Phase 5: Re-enable Config File Extraction
**Files to modify:** `src/installer/main.nsi` lines 901-902
- Uncomment config file extraction
- Fix path syntax: `File "${BUILD_DIR}\config\defaults.json"`

### Phase 6: Update Shortcut Creation with Icons
**Files to modify:** `src/installer/main.nsi` CreateShortcuts function
- Add icon parameter to CreateShortcut commands
- Use: `CreateShortcut "path" "target" "params" "$INSTDIR\generated-images\claude-icon.ico"`

### Phase 7: Build and Debug
- Run `make build` 
- Fix any path resolution errors
- Verify final installer size (~300KB)
- Test on Windows VM if possible

### Phase 8: Version and Release
- Update version number if needed
- Commit with message about projects folder feature
- Tag new version (v1.3.0)
- Create GitHub release with new installer

## Expected Issues and Solutions

### Asset Path Issues
**Problem:** NSIS can't find asset files
**Solution:** Use absolute paths or correct relative paths from build directory

### PowerShell Module Missing  
**Problem:** Build process doesn't copy scripts to build/
**Solution:** Verify Makefile copies src/scripts to build/scripts correctly

### File Syntax Errors
**Problem:** NSIS File command syntax errors
**Solution:** Use proper backslash escaping: `File "path\\file.ext"`

### Size Verification
**Expected final size:** ~300KB (was 108KB minimal)
**Components:** 
- Icons/bitmaps: ~380KB raw, ~200KB compressed
- PowerShell modules: ~50KB  
- Bash scripts: ~10KB
- Config: ~5KB
- Core installer: ~108KB

## Success Criteria
- ✅ Installer builds without errors
- ✅ Final size ~300KB (not 108KB)
- ✅ All assets embedded and accessible
- ✅ PowerShell automation available
- ✅ Projects folder feature working
- ✅ Professional appearance with icons
- ✅ New GitHub release created

## Rollback Plan
If critical issues occur:
1. Keep projects folder changes
2. Revert only problematic asset re-enablement
3. Build minimal working version
4. Debug assets separately

## Context Management
Due to context limits:
1. Focus on one phase at a time
2. Test build after each phase
3. Commit working states
4. Document any issues encountered