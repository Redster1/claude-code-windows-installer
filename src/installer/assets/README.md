# Claude Code Installer Assets

This directory contains assets for the NSIS installer UI.

## Required Assets

### Icons
- `claude-icon.ico` - Main application icon (32x32, 48x48, 256x256)
- Used in installer window title, shortcuts, and Add/Remove Programs

### Installer Bitmaps
- `wizard-sidebar.bmp` - Welcome/Finish page sidebar (164x314 pixels)
- `wizard-header.bmp` - Header image for installer pages (150x57 pixels)

## Asset Specifications

### Wizard Sidebar (164x314)
- Used on Welcome and Finish pages
- Should contain Claude Code branding
- Professional appearance suitable for legal professionals
- Colors: Blue/white theme recommended

### Wizard Header (150x57)
- Small header image for internal pages
- Should complement sidebar design
- Minimal text, focus on logo/branding

### Icon Requirements
- .ICO format with multiple sizes
- 16x16, 32x32, 48x48, 256x256 recommended
- Transparent background
- Should be recognizable at small sizes

## Current Status

**Placeholder assets created** - These are temporary files for development.
For production, high-quality professional assets should be created.

## Asset Creation Tools

- **Icons**: Use tools like IcoFX, Greenfish Icon Editor, or online converters
- **Bitmaps**: Photoshop, GIMP, or any image editor supporting BMP format
- **Design**: Follow Windows installer design guidelines for professional appearance

## Integration

Assets are referenced in main.nsi:
```nsis
!define MUI_ICON "${ASSETS_DIR}\claude-icon.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${ASSETS_DIR}\wizard-sidebar.bmp"
!define MUI_HEADERIMAGE_BITMAP "${ASSETS_DIR}\wizard-header.bmp"
```

Update ASSETS_DIR variable in build system to point to this directory.