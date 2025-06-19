# Claude Code Windows Installer - Image Management

This directory contains tools for managing the visual assets used in the Windows installer. The installer requires three different image formats to provide a professional, branded user experience.

## Quick Start

To update the installer images with a new logo:

```bash
# From project root directory
./tools/scripts/generate-installer-images.sh your-new-logo.png

# Build installer with new images
make build
```

## Generated Image Formats

The script generates three specific image formats required by the NSIS Windows installer:

### 1. Application Icon (`claude-icon.ico`)
- **Purpose**: Main Windows application icon
- **Format**: Multi-resolution ICO file
- **Sizes**: 16×16, 32×32, 48×48, 64×64, 128×128, 256×256 pixels
- **Color**: 32-bit RGBA with transparency support
- **Usage**:
  - Installer executable icon
  - Desktop shortcuts
  - Start Menu entries
  - Add/Remove Programs listing
  - Windows taskbar display

### 2. Wizard Header (`wizard-header.bmp`)
- **Purpose**: Header banner displayed at top of installer pages
- **Format**: Windows BMP (24-bit RGB)
- **Dimensions**: 497×58 pixels (NSIS standard)
- **Color**: No transparency (white background applied)
- **Usage**: Shown on all installer pages except Welcome/Finish

### 3. Wizard Sidebar (`wizard-sidebar.bmp`)
- **Purpose**: Large image on Welcome and Finish pages
- **Format**: Windows BMP (24-bit RGB)  
- **Dimensions**: 164×314 pixels (NSIS standard)
- **Color**: No transparency (white background applied)
- **Usage**: Welcome page and installation complete page

## Script Usage

### Basic Usage
```bash
./tools/scripts/generate-installer-images.sh <source-image.png>
```

### Examples
```bash
# Using a file in current directory
./tools/scripts/generate-installer-images.sh claude-logo.png

# Using absolute path
./tools/scripts/generate-installer-images.sh /path/to/images/my-logo.png

# Using relative path
./tools/scripts/generate-installer-images.sh ../assets/brand-logo.png
```

### Requirements
- **ImageMagick**: The script requires the `magick` command
- **Source Format**: PNG files only (for best transparency handling)
- **Recommended Size**: 512×512 pixels or larger for optimal quality
- **Transparency**: Source image with transparent background works best for ICO generation

### Installation of ImageMagick
```bash
# Ubuntu/Debian
sudo apt install imagemagick

# macOS with Homebrew
brew install imagemagick

# Nix
nix-env -iA nixpkgs.imagemagick

# Windows (via Chocolatey)
choco install imagemagick
```

## Output Structure

All generated images are placed in the `generated-images/` directory:

```
generated-images/
├── claude-icon.ico          # Multi-resolution Windows icon (~120KB)
├── wizard-header.bmp        # NSIS header image (~85KB)
└── wizard-sidebar.bmp       # NSIS sidebar image (~155KB)
```

## Integration with Build System

The build system (Makefile) is configured to use images from `generated-images/`:

```makefile
# Makefile automatically uses generated images
make build    # Builds installer with current images in generated-images/
```

The NSIS installer script (`src/installer/main.nsi`) includes these images and:
- Copies them to the installation directory during install
- Uses them for UI branding during installation
- References them in Windows shortcuts and registry entries
- Removes them during uninstallation

## Script Features

### Validation
- ✅ Checks if ImageMagick is installed
- ✅ Validates input file exists and is PNG format
- ✅ Warns if source image is too small
- ✅ Verifies image integrity before processing

### Error Handling
- ✅ Graceful error messages with color coding
- ✅ Exits cleanly if any step fails
- ✅ Provides troubleshooting guidance

### Output
- ✅ Colored status messages for easy reading
- ✅ File size information for each generated image
- ✅ Completion summary with next steps
- ✅ Progress indicators for each conversion step

## Advanced Usage

### Custom Output Directory
You can modify the script to use a different output directory:

```bash
# Edit the script and change this line:
OUTPUT_DIR="custom-images"
```

### Custom ICO Sizes
To generate different ICO resolutions, modify:

```bash
# Edit the script and change this line:
ICO_SIZES="16,32,48,64,128,256"
```

### Quality Settings
For higher quality BMP output, you can modify the ImageMagick commands in the script:

```bash
# Example: Add quality settings
magick "$source_file" -resize "${dimensions}!" -quality 100 ...
```

## Troubleshooting

### Common Issues

**"ImageMagick not found"**
- Install ImageMagick using package manager
- Ensure `magick` command is in your PATH
- Try `which magick` to verify installation

**"Invalid or corrupted PNG file"**
- Ensure source file is valid PNG format
- Try opening file in image viewer to verify
- Check file permissions are readable

**"Source image is smaller than 256x256"**
- This is just a warning - generation will continue
- For best quality, use larger source images
- Consider using vector formats (SVG) converted to large PNG first

**"Failed to generate [format] file"**
- Check available disk space
- Verify write permissions to output directory
- Ensure ImageMagick supports the output format

### Debug Mode
For detailed output, you can modify the script to show ImageMagick commands:

```bash
# Remove '2>/dev/null' from magick commands in the script
magick "$source_file" -define icon:auto-resize="$ICO_SIZES" "$output_file"
```

## File Specifications

### Technical Requirements

| Asset | Format | Dimensions | Color Depth | Transparency | File Size |
|-------|--------|------------|-------------|--------------|-----------|
| ICO   | ICO    | Multi-res  | 32-bit RGBA | Yes          | ~120KB    |
| Header| BMP    | 497×58     | 24-bit RGB  | No           | ~85KB     |
| Sidebar| BMP   | 164×314    | 24-bit RGB  | No           | ~155KB    |

### Design Guidelines

**Application Icon (ICO)**:
- Should work well at small sizes (16×16)
- Simple, recognizable design
- Good contrast for visibility
- Transparent background preferred

**Header Image (BMP)**:
- Horizontal layout (wide and short)
- Brand logo typically on left side
- Subtle background or gradient
- Professional appearance

**Sidebar Image (BMP)**:
- Vertical layout (tall and narrow)
- Can include artistic elements
- Should complement header design
- Suitable for welcome/completion pages

## Maintenance

### Updating Images
1. Create or obtain new source PNG image
2. Run the generation script: `./tools/scripts/generate-installer-images.sh new-logo.png`
3. Review generated images to ensure quality
4. Test installer build: `make build`
5. Verify images display correctly in installer

### Version Control
- Source PNG files should be committed to repository
- Generated images in `generated-images/` are committed
- Script updates should be documented
- Keep `tools/README.md` updated with any changes

### Backup
Consider keeping backup copies of:
- Original source images (high resolution)
- Vector format files (AI, SVG) if available
- Previous versions of generated images

## See Also

- [Asset Specifications](../asset-specs.md) - Detailed technical requirements
- [Build System](../Makefile) - How images integrate with build process
- [NSIS Documentation](https://nsis.sourceforge.io/Docs/) - NSIS installer system
- [ImageMagick Documentation](https://imagemagick.org/) - Image processing tool