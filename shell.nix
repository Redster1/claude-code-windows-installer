# Claude Code Installer Development Environment
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Core build tools
    nsis
    powershell
    nodejs
    
    # Development tools
    git
    gnumake
    
    # Testing and virtualization
    wine64
    qemu
    libvirt
    
    # Python for tooling
    python3
    python3Packages.pytest
    python3Packages.requests
    
    # Utilities
    jq
    curl
    wget
  ];
  
  shellHook = ''
    echo "🚀 Claude Code Installer Development Environment"
    echo "================================================"
    echo ""
    echo "Available commands:"
    echo "  make help     - Show build system help"
    echo "  make dev-setup - Check development environment"
    echo "  make build    - Build installer"
    echo "  make test     - Run tests"
    echo ""
    echo "Development tools:"
    echo "  NSIS:        $(makensis -VERSION 2>/dev/null || echo 'Not available')"
    echo "  PowerShell:  $(pwsh --version 2>/dev/null || echo 'Not available')"
    echo "  Node.js:     $(node --version 2>/dev/null || echo 'Not available')"
    echo ""
    
    # Set up development aliases
    alias build="make build"
    alias test="make test"
    alias clean="make clean"
    
    # Create initial npm package.json if it doesn't exist
    if [ ! -f package.json ]; then
      echo "Creating package.json..."
      npm init -y >/dev/null 2>&1
    fi
    
    echo "Environment ready! Run 'make help' for build commands."
  '';
  
  # Environment variables
  CLAUDE_INSTALLER_DEV = "1";
  NSIS_HOME = "${pkgs.nsis}";
}