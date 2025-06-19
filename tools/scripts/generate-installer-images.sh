#!/bin/bash

# Claude Code Windows Installer - Image Generator
# ===============================================
# 
# This script converts a source PNG image into all the required formats for the Windows installer:
# 1. Multi-resolution ICO file for application icon
# 2. NSIS wizard header image (BMP format)
# 3. NSIS wizard sidebar image (BMP format)
#
# USAGE:
#   ./tools/scripts/generate-installer-images.sh <source-image.png>
#
# REQUIREMENTS:
#   - ImageMagick (magick command)
#   - Source image should be high resolution (recommended: 512x512 or larger)
#   - Source image should have transparent background for best ICO results
#
# OUTPUT:
#   All images are placed in: generated-images/
#   - claude-icon.ico (multi-resolution: 16x16, 32x32, 48x48, 64x64, 128x128, 256x256)
#   - wizard-header.bmp (497x58 pixels, 24-bit RGB)
#   - wizard-sidebar.bmp (164x314 pixels, 24-bit RGB)

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OUTPUT_DIR="generated-images"
ICO_SIZES="16,32,48,64,128,256"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate source image
validate_source_image() {
    local source_file="$1"
    
    # Check if file exists
    if [[ ! -f "$source_file" ]]; then
        print_error "Source file '$source_file' not found"
        return 1
    fi
    
    # Check if file is a PNG
    if [[ ! "$source_file" =~ \.png$ ]]; then
        print_error "Source file must be a PNG image"
        return 1
    fi
    
    # Check image dimensions using ImageMagick
    local dimensions
    dimensions=$(magick identify -format "%wx%h" "$source_file" 2>/dev/null)
    if [[ -z "$dimensions" ]]; then
        print_error "Invalid or corrupted PNG file"
        return 1
    fi
    
    print_status "Source image: $source_file ($dimensions)"
    
    # Parse dimensions
    local width height
    width=$(echo "$dimensions" | cut -d'x' -f1)
    height=$(echo "$dimensions" | cut -d'x' -f2)
    
    # Warn if image is too small
    if [[ $width -lt 256 || $height -lt 256 ]]; then
        print_warning "Source image is smaller than 256x256. Consider using a larger image for better quality."
    fi
    
    return 0
}

# Function to create output directory
setup_output_directory() {
    if [[ -d "$OUTPUT_DIR" ]]; then
        print_status "Output directory '$OUTPUT_DIR' already exists"
    else
        print_status "Creating output directory: $OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR"
    fi
}

# Function to generate multi-resolution ICO file
generate_ico_file() {
    local source_file="$1"
    local output_file="$OUTPUT_DIR/claude-icon.ico"
    
    print_status "Generating multi-resolution ICO file..."
    print_status "  Sizes: $ICO_SIZES pixels"
    print_status "  Format: 32-bit RGBA with transparency"
    
    # Generate ICO with multiple resolutions
    if magick "$source_file" -define icon:auto-resize="$ICO_SIZES" "$output_file" 2>/dev/null; then
        local file_size
        file_size=$(du -h "$output_file" | cut -f1)
        print_success "ICO file created: $output_file ($file_size)"
    else
        print_error "Failed to generate ICO file"
        return 1
    fi
}

# Function to generate wizard header BMP
generate_header_bmp() {
    local source_file="$1"
    local output_file="$OUTPUT_DIR/wizard-header.bmp"
    local dimensions="497x58"
    
    print_status "Generating NSIS wizard header image..."
    print_status "  Dimensions: $dimensions pixels"
    print_status "  Format: 24-bit RGB BMP (no transparency)"
    
    # Generate header BMP with exact dimensions
    if magick "$source_file" \
        -resize "${dimensions}!" \
        -background white \
        -alpha remove \
        -type TrueColor \
        -depth 24 \
        BMP3:"$output_file" 2>/dev/null; then
        
        local file_size
        file_size=$(du -h "$output_file" | cut -f1)
        print_success "Header BMP created: $output_file ($file_size)"
    else
        print_error "Failed to generate header BMP"
        return 1
    fi
}

# Function to generate wizard sidebar BMP
generate_sidebar_bmp() {
    local source_file="$1"
    local output_file="$OUTPUT_DIR/wizard-sidebar.bmp"
    local dimensions="164x314"
    
    print_status "Generating NSIS wizard sidebar image..."
    print_status "  Dimensions: $dimensions pixels"  
    print_status "  Format: 24-bit RGB BMP (no transparency)"
    
    # Generate sidebar BMP with exact dimensions
    if magick "$source_file" \
        -resize "${dimensions}!" \
        -background white \
        -alpha remove \
        -type TrueColor \
        -depth 24 \
        BMP3:"$output_file" 2>/dev/null; then
        
        local file_size
        file_size=$(du -h "$output_file" | cut -f1)
        print_success "Sidebar BMP created: $output_file ($file_size)"
    else
        print_error "Failed to generate sidebar BMP"
        return 1
    fi
}

# Function to display completion summary
show_completion_summary() {
    echo
    print_success "=== IMAGE GENERATION COMPLETE ==="
    echo
    print_status "Generated files in '$OUTPUT_DIR/':"
    
    if [[ -f "$OUTPUT_DIR/claude-icon.ico" ]]; then
        local ico_size
        ico_size=$(du -h "$OUTPUT_DIR/claude-icon.ico" | cut -f1)
        echo "  ✅ claude-icon.ico ($ico_size) - Application icon for Windows"
    fi
    
    if [[ -f "$OUTPUT_DIR/wizard-header.bmp" ]]; then
        local header_size  
        header_size=$(du -h "$OUTPUT_DIR/wizard-header.bmp" | cut -f1)
        echo "  ✅ wizard-header.bmp ($header_size) - NSIS installer header"
    fi
    
    if [[ -f "$OUTPUT_DIR/wizard-sidebar.bmp" ]]; then
        local sidebar_size
        sidebar_size=$(du -h "$OUTPUT_DIR/wizard-sidebar.bmp" | cut -f1)
        echo "  ✅ wizard-sidebar.bmp ($sidebar_size) - NSIS installer sidebar"
    fi
    
    echo
    print_status "NEXT STEPS:"
    echo "  1. Review the generated images to ensure they look correct"
    echo "  2. Run 'make build' to build the installer with the new images"
    echo "  3. Test the installer to verify the images display properly"
    echo
}

# Main function
main() {
    echo "Claude Code Windows Installer - Image Generator"
    echo "=============================================="
    echo
    
    # Check arguments
    if [[ $# -ne 1 ]]; then
        print_error "Usage: $0 <source-image.png>"
        echo
        echo "Example:"
        echo "  $0 my-logo.png"
        echo "  $0 /path/to/claude-code-logo.png"
        exit 1
    fi
    
    local source_file="$1"
    
    # Validate prerequisites
    print_status "Checking prerequisites..."
    
    if ! command_exists magick; then
        print_error "ImageMagick not found. Please install ImageMagick first."
        echo
        echo "Installation options:"
        echo "  - Ubuntu/Debian: sudo apt install imagemagick"  
        echo "  - macOS: brew install imagemagick"
        echo "  - Nix: nix-env -iA nixpkgs.imagemagick"
        exit 1
    fi
    
    print_success "ImageMagick found: $(magick -version | head -n1)"
    
    # Validate source image
    if ! validate_source_image "$source_file"; then
        exit 1
    fi
    
    # Setup output directory
    setup_output_directory
    
    # Generate all image formats
    print_status "Starting image generation process..."
    echo
    
    if ! generate_ico_file "$source_file"; then
        exit 1
    fi
    
    if ! generate_header_bmp "$source_file"; then
        exit 1
    fi
    
    if ! generate_sidebar_bmp "$source_file"; then
        exit 1
    fi
    
    # Show completion summary
    show_completion_summary
}

# Run main function with all arguments
main "$@"