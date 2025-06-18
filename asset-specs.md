# Claude Code Windows Installer - Asset Specifications

## Required Assets for Professional Windows Installer

The Windows installer requires several visual assets to provide a professional, polished user experience. Currently, the assets in `src/installer/assets/` are placeholder files that need to be replaced with proper graphics.

## Asset Requirements

### 1. Application Icon (`claude-icon.ico`)

**Purpose**: Main application icon used throughout Windows
**Current Status**: ❌ Placeholder file (46 bytes - empty/invalid)
**Required Specifications**:
- **Format**: Windows ICO format (.ico)
- **Sizes**: Multi-resolution icon containing:
  - 16x16 pixels (small icons)
  - 32x32 pixels (standard desktop)
  - 48x48 pixels (large icons)
  - 64x64 pixels (extra large)
  - 128x128 pixels (jumbo icons)
  - 256x256 pixels (high DPI displays)
- **Color Depth**: 32-bit RGBA (with transparency support)
- **Design**: Claude Code branding/logo
- **Usage**:
  - Installer executable icon
  - Desktop shortcuts
  - Start Menu entries
  - Add/Remove Programs listing
  - Taskbar display
- **File Size**: Typically 50-200KB for multi-resolution ICO

### 2. Wizard Header Image (`wizard-header.bmp`)

**Purpose**: Header image displayed at the top of installer pages
**Current Status**: ❌ Placeholder file
**Required Specifications**:
- **Format**: Windows BMP format (.bmp)
- **Dimensions**: 497 x 58 pixels (standard NSIS header size)
- **Color Depth**: 24-bit RGB (no transparency)
- **Design Guidelines**:
  - Claude Code logo/branding on the left
  - Professional gradient or solid background
  - Text reading "Claude Code for Windows" or similar
  - Consistent with overall brand identity
  - High contrast for readability
- **File Size**: ~85KB uncompressed BMP
- **Usage**: Displayed on all installer pages except Welcome/Finish

### 3. Wizard Sidebar Image (`wizard-sidebar.bmp`)

**Purpose**: Large image displayed on Welcome and Finish pages
**Current Status**: ❌ Placeholder file  
**Required Specifications**:
- **Format**: Windows BMP format (.bmp)
- **Dimensions**: 164 x 314 pixels (standard NSIS sidebar size)
- **Color Depth**: 24-bit RGB (no transparency)
- **Design Guidelines**:
  - Vertical orientation artwork
  - Claude Code branding/imagery
  - Professional appearance suitable for business users
  - Can include stylized graphics, abstract designs, or product screenshots
  - Should complement the header image design
- **File Size**: ~150KB uncompressed BMP
- **Usage**: Welcome page and Installation complete page

## Design Considerations

### Brand Consistency
- All assets should follow consistent color scheme
- Typography should match Claude Code brand guidelines
- Professional appearance suitable for legal/business environments

### Technical Requirements
- All images must be uncompressed BMP format (NSIS requirement)
- ICO file must be properly formatted Windows icon
- Exact pixel dimensions required (NSIS is strict about sizing)
- Colors should look good on both light and dark Windows themes

### Accessibility
- High contrast ratios for text elements
- Clear, readable fonts at small sizes
- Recognizable iconography that works in grayscale

## Alternative Solutions

If custom assets aren't available, consider:

### Option 1: Disable Assets (Current Approach)
- Remove all asset references from installer
- Use default Windows installer appearance
- Functional but less professional appearance

### Option 2: Generic Professional Assets
- Use minimal, text-based designs
- Simple gradients with product name
- Professional blue/gray color schemes
- Focus on clarity over branding

### Option 3: Community/Open Source Assets
- Find CC-licensed professional installer graphics
- Adapt existing NSIS template designs
- Ensure licensing compatibility

## Implementation Priority

1. **High Priority**: `claude-icon.ico` - Essential for Windows integration
2. **Medium Priority**: `wizard-header.bmp` - Improves professional appearance
3. **Low Priority**: `wizard-sidebar.bmp` - Nice to have for polished look

## Testing Requirements

Once assets are created:
- Test ICO file displays correctly in Windows Explorer
- Verify header image displays properly in installer
- Check sidebar image alignment on Welcome/Finish pages
- Test on different Windows versions (10/11)
- Verify appearance on high DPI displays

## File Locations

Assets should be placed in:
```
src/installer/assets/
├── claude-icon.ico          # Multi-resolution Windows icon
├── wizard-header.bmp        # 497x58 header image  
└── wizard-sidebar.bmp       # 164x314 sidebar image
```

## Technical Notes

- NSIS requires exact BMP format (no PNG/JPG substitutes)
- ICO files must be properly formatted (not just renamed PNG files)
- Build system will fail if assets are missing or invalid format
- Assets are embedded in the final installer executable
- Total asset size should be kept reasonable (<1MB combined)