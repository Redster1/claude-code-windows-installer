#!/bin/bash
# Claude Code Installer - Alpine Linux Setup Script
# Configures Alpine Linux environment for Claude Code

set -euo pipefail

# Configuration
REQUIRED_NODE_VERSION="18.0.0"
REQUIRED_NPM_VERSION="9.0.0"
LOG_FILE="/tmp/claude-code-setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)  echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$LOG_FILE" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$LOG_FILE" ;;
    esac
}

# Progress tracking
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local percent=$((current * 100 / total))
    
    printf "\r[%3d%%] %s" $percent "$message"
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# Version comparison function
version_ge() {
    # Returns 0 if version1 >= version2
    printf '%s\n%s' "$2" "$1" | sort -C -V
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check existing tools
check_existing_tools() {
    log INFO "Checking for existing tools..."
    
    local tools=("curl" "git" "node" "npm" "bash" "nano")
    local missing=()
    local existing=()
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            existing+=("$tool")
            log INFO "✓ Found: $tool"
        else
            missing+=("$tool")
            log WARN "✗ Missing: $tool"
        fi
    done
    
    echo "${missing[@]}"
}

# Update package repositories
update_repositories() {
    log INFO "Updating Alpine package repositories..."
    
    if apk update >/dev/null 2>&1; then
        log SUCCESS "Package repositories updated"
    else
        log ERROR "Failed to update package repositories"
        exit 1
    fi
    
    # Upgrade existing packages
    if apk upgrade >/dev/null 2>&1; then
        log SUCCESS "System packages upgraded"
    else
        log WARN "Some packages could not be upgraded"
    fi
}

# Install essential tools with existence checks
install_essential_tools() {
    log INFO "Installing essential tools..."
    local tools_to_install=()
    
    # Check each tool individually
    command_exists curl || tools_to_install+=("curl")
    command_exists git || tools_to_install+=("git")
    command_exists bash || tools_to_install+=("bash")
    command_exists nano || tools_to_install+=("nano")
    
    if [ ${#tools_to_install[@]} -eq 0 ]; then
        log SUCCESS "All essential tools already installed"
        return 0
    fi
    
    log INFO "Installing: ${tools_to_install[*]}"
    if apk add --no-cache "${tools_to_install[@]}" >/dev/null 2>&1; then
        log SUCCESS "Essential tools installed successfully"
    else
        log ERROR "Failed to install essential tools"
        exit 1
    fi
}

# Install or validate Node.js
install_nodejs() {
    log INFO "Checking Node.js installation..."
    
    if command_exists node; then
        local current_version
        current_version=$(node --version | sed 's/v//')
        log INFO "Found Node.js version: $current_version"
        
        if version_ge "$current_version" "$REQUIRED_NODE_VERSION"; then
            log SUCCESS "Node.js version $current_version is compatible (>= $REQUIRED_NODE_VERSION)"
            
            # Check npm too
            if command_exists npm; then
                local npm_version
                npm_version=$(npm --version)
                log INFO "Found npm version: $npm_version"
                
                if version_ge "$npm_version" "$REQUIRED_NPM_VERSION"; then
                    log SUCCESS "npm version $npm_version is compatible (>= $REQUIRED_NPM_VERSION)"
                    return 0
                else
                    log WARN "npm version $npm_version is too old, upgrading..."
                fi
            fi
        else
            log WARN "Node.js version $current_version is too old (< $REQUIRED_NODE_VERSION), upgrading..."
        fi
    else
        log INFO "Node.js not found, installing..."
    fi
    
    # Install Node.js and npm
    log INFO "Installing Node.js and npm..."
    if apk add --no-cache nodejs npm >/dev/null 2>&1; then
        local installed_node_version
        local installed_npm_version
        installed_node_version=$(node --version | sed 's/v//')
        installed_npm_version=$(npm --version)
        
        log SUCCESS "Node.js $installed_node_version and npm $installed_npm_version installed"
        
        # Verify versions meet requirements
        if version_ge "$installed_node_version" "$REQUIRED_NODE_VERSION" && version_ge "$installed_npm_version" "$REQUIRED_NPM_VERSION"; then
            log SUCCESS "Installed versions meet requirements"
        else
            log ERROR "Installed versions do not meet requirements"
            exit 1
        fi
    else
        log ERROR "Failed to install Node.js and npm"
        exit 1
    fi
}

# Configure npm for global installations
configure_npm() {
    log INFO "Configuring npm environment..."
    
    # Create npm global directory if it doesn't exist
    local npm_global_dir="$HOME/.npm-global"
    if [ ! -d "$npm_global_dir" ]; then
        mkdir -p "$npm_global_dir"
        log INFO "Created npm global directory: $npm_global_dir"
    fi
    
    # Configure npm to use this directory
    npm config set prefix "$npm_global_dir" 2>/dev/null || {
        log WARN "Could not set npm prefix, using default"
    }
    
    # Add to PATH if not already there
    if ! echo "$PATH" | grep -q "$npm_global_dir/bin"; then
        echo "export PATH=\$PATH:$npm_global_dir/bin" >> "$HOME/.bashrc"
        echo "export PATH=\$PATH:$npm_global_dir/bin" >> "$HOME/.profile"
        export PATH="$PATH:$npm_global_dir/bin"
        log INFO "Added npm global bin directory to PATH"
    fi
    
    log SUCCESS "npm environment configured"
}

# Create user account if needed
setup_user_account() {
    log INFO "Setting up user account..."
    
    local username="claudeuser"
    
    # Check if user exists
    if id "$username" >/dev/null 2>&1; then
        log INFO "User $username already exists"
    else
        log INFO "Creating user account: $username"
        if adduser -D -s /bin/bash "$username" >/dev/null 2>&1; then
            log SUCCESS "User $username created successfully"
        else
            log WARN "Could not create user $username, continuing with current user"
        fi
    fi
}

# Configure shell environment
configure_environment() {
    log INFO "Configuring shell environment..."
    
    # Ensure .bashrc exists
    touch "$HOME/.bashrc"
    touch "$HOME/.profile"
    
    # Add Claude Code helpful aliases and functions
    local bashrc_additions="
# Claude Code Installer additions
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Claude Code helper function
claude-help() {
    echo \"Claude Code Quick Reference:\"
    echo \"  claude --help          - Show help\"
    echo \"  claude --version       - Show version\"
    echo \"  claude login           - Login to Claude\"
    echo \"  claude <your-prompt>   - Start a conversation\"
}

# Add npm global bin to PATH (if not already added)
if [[ ! \"\$PATH\" == *\"\$HOME/.npm-global/bin\"* ]]; then
    export PATH=\"\$PATH:\$HOME/.npm-global/bin\"
fi
"
    
    # Only add if not already present
    if ! grep -q "Claude Code Installer additions" "$HOME/.bashrc" 2>/dev/null; then
        echo "$bashrc_additions" >> "$HOME/.bashrc"
        log INFO "Added helpful aliases and functions to .bashrc"
    fi
    
    log SUCCESS "Shell environment configured"
}

# Verify installation
verify_installation() {
    log INFO "Verifying installation..."
    
    local verification_failed=false
    
    # Check essential tools
    local tools=("curl" "git" "node" "npm")
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            local version
            case $tool in
                node) version=$(node --version) ;;
                npm) version=$(npm --version) ;;
                git) version=$(git --version | awk '{print $3}') ;;
                curl) version=$(curl --version | head -n1 | awk '{print $2}') ;;
            esac
            log SUCCESS "✓ $tool: $version"
        else
            log ERROR "✗ $tool: Not found"
            verification_failed=true
        fi
    done
    
    # Test npm global installation capability
    log INFO "Testing npm global installation capability..."
    if npm list -g --depth=0 >/dev/null 2>&1; then
        log SUCCESS "npm global installation is working"
    else
        log WARN "npm global installation may have issues"
    fi
    
    if [ "$verification_failed" = true ]; then
        log ERROR "Installation verification failed"
        exit 1
    else
        log SUCCESS "Installation verification completed successfully"
    fi
}

# Main installation function
main() {
    log INFO "Starting Claude Code Alpine Linux setup..."
    log INFO "Log file: $LOG_FILE"
    
    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    # Installation steps
    local total_steps=7
    local current_step=0
    
    # Step 1: Update repositories
    ((current_step++))
    show_progress $current_step $total_steps "Updating package repositories..."
    update_repositories
    
    # Step 2: Check existing tools
    ((current_step++))
    show_progress $current_step $total_steps "Checking existing tools..."
    missing_tools=$(check_existing_tools)
    
    # Step 3: Install essential tools
    ((current_step++))
    show_progress $current_step $total_steps "Installing essential tools..."
    install_essential_tools
    
    # Step 4: Install Node.js
    ((current_step++))
    show_progress $current_step $total_steps "Setting up Node.js..."
    install_nodejs
    
    # Step 5: Configure npm
    ((current_step++))
    show_progress $current_step $total_steps "Configuring npm..."
    configure_npm
    
    # Step 6: Setup user environment
    ((current_step++))
    show_progress $current_step $total_steps "Configuring environment..."
    setup_user_account
    configure_environment
    
    # Step 7: Verify installation
    ((current_step++))
    show_progress $current_step $total_steps "Verifying installation..."
    verify_installation
    
    log SUCCESS "Alpine Linux setup completed successfully!"
    log INFO "You can now install Claude Code with: npm install -g @anthropic-ai/claude-code"
    log INFO "Log file saved at: $LOG_FILE"
}

# Error handling
trap 'log ERROR "Script failed at line $LINENO. Exit code: $?"' ERR

# Script entry point
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi