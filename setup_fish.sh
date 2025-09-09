#!/bin/bash

#============================================================================
# Fish Shell Setup Script
# Installs and configures Fish shell with custom dotfiles
#============================================================================

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
FISH_CONFIG_DIR="$HOME/.config/fish"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

#============================================================================
# OS Detection
#============================================================================

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    log_info "Detected OS: $OS"
}

#============================================================================
# Fish Installation
#============================================================================

install_fish_macos() {
    log_info "Installing Fish shell on macOS..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ -d "/opt/homebrew" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        else
            export PATH="/usr/local/bin:$PATH"
        fi
    fi
    
    # Install Fish
    if ! command -v fish &> /dev/null; then
        brew install fish
        log_success "Fish shell installed via Homebrew"
    else
        log_info "Fish shell already installed"
    fi
}

install_fish_linux() {
    log_info "Installing Fish shell on Linux..."
    
    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        log_error "Cannot detect Linux distribution"
        exit 1
    fi
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y fish
            ;;
        fedora|centos|rhel)
            sudo dnf install -y fish
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm fish
            ;;
        *)
            log_error "Unsupported Linux distribution: $DISTRO"
            log_info "Please install Fish shell manually and re-run this script"
            exit 1
            ;;
    esac
    
    log_success "Fish shell installed"
}

install_fish() {
    case $OS in
        macos)
            install_fish_macos
            ;;
        linux)
            install_fish_linux
            ;;
    esac
}

#============================================================================
# Configuration Setup
#============================================================================

setup_fish_config() {
    log_info "Setting up Fish configuration..."
    
    # Create Fish config directory
    mkdir -p "$FISH_CONFIG_DIR"
    mkdir -p "$FISH_CONFIG_DIR/functions"
    
    # Backup existing config if it exists
    if [ -f "$FISH_CONFIG_DIR/config.fish" ]; then
        log_warning "Backing up existing Fish config to config.fish.backup"
        cp "$FISH_CONFIG_DIR/config.fish" "$FISH_CONFIG_DIR/config.fish.backup"
    fi
    
    # Create symlink to our config
    log_info "Creating symlink to dotfiles Fish config..."
    ln -sf "$DOTFILES_DIR/fish/config.fish" "$FISH_CONFIG_DIR/config.fish"
    
    # Create symlinks for functions
    log_info "Setting up Fish functions..."
    for func_file in "$DOTFILES_DIR/fish/functions"/*.fish; do
        if [ -f "$func_file" ]; then
            func_name=$(basename "$func_file")
            ln -sf "$func_file" "$FISH_CONFIG_DIR/functions/$func_name"
        fi
    done
    
    log_success "Fish configuration setup complete"
}

#============================================================================
# Plugin Installation
#============================================================================

install_fish_plugins() {
    log_info "Installing Fish plugins..."
    
    # Install Fisher (Fish plugin manager) if not already installed
    if ! fish -c "type -q fisher" 2>/dev/null; then
        log_info "Installing Fisher plugin manager..."
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
        log_success "Fisher plugin manager installed"
    else
        log_info "Fisher plugin manager already installed"
    fi
    
    # Install useful plugins
    log_info "Installing Fish plugins via Fisher..."
    fish -c "fisher install jethrokuan/z"  # Directory jumping
    fish -c "fisher install PatrickF1/fzf.fish"  # FZF integration
    fish -c "fisher install franciscolourenco/done"  # Notification when command finishes
    fish -c "fisher install jorgebucaran/autopair.fish"  # Autopair brackets
    
    log_success "Fish plugins installed"
}

#============================================================================
# Shell Configuration
#============================================================================

setup_shell() {
    log_info "Configuring Fish as default shell..."
    
    # Get Fish path
    FISH_PATH=$(which fish)
    
    # Add Fish to /etc/shells if not already there
    if ! grep -q "$FISH_PATH" /etc/shells 2>/dev/null; then
        log_info "Adding Fish to /etc/shells..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells
    fi
    
    # Change default shell to Fish
    if [ "$SHELL" != "$FISH_PATH" ]; then
        log_info "Setting Fish as default shell..."
        chsh -s "$FISH_PATH"
        log_success "Default shell changed to Fish"
        log_warning "Please log out and log back in for the shell change to take effect"
    else
        log_info "Fish is already the default shell"
    fi
}

#============================================================================
# Final Setup
#============================================================================

create_env_file() {
    # Create .env file if it doesn't exist
    if [ ! -f "$HOME/.env" ]; then
        log_info "Creating ~/.env file..."
        touch "$HOME/.env"
        echo "# Environment variables" >> "$HOME/.env"
        echo "# Add your custom environment variables here" >> "$HOME/.env"
        log_success "Created ~/.env file"
    else
        log_info "~/.env file already exists"
    fi
}

test_fish_config() {
    log_info "Testing Fish configuration..."
    
    # Test if Fish config loads without errors
    if fish -c "exit" 2>/dev/null; then
        log_success "Fish configuration loads successfully"
    else
        log_error "Fish configuration has errors"
        log_info "You can test manually by running: fish"
        return 1
    fi
}

show_completion_message() {
    log_success "🐟 Fish shell setup completed!"
    echo ""
    echo "Next steps:"
    echo "==========="
    echo "1. Start a new terminal session or run: exec fish"
    echo "2. Test the configuration with: fish_toggle_mode"
    echo "3. Try some key bindings (Ctrl+G for git, Ctrl+R for history search)"
    echo "4. Customize your ~/.env file for environment variables"
    echo ""
    echo "Available modes:"
    echo "- fish_set_mode fastest   # Minimal setup for speed"
    echo "- fish_set_mode balanced  # Good balance of features and speed (default)"
    echo "- fish_set_mode full      # All features enabled"
    echo ""
    echo "For help with key bindings, press Ctrl+H in Fish"
    echo ""
    echo "Configuration files:"
    echo "- Main config: ~/.config/fish/config.fish -> $DOTFILES_DIR/fish/config.fish"
    echo "- Functions: ~/.config/fish/functions/ -> $DOTFILES_DIR/fish/functions/"
    echo "- Environment: ~/.env"
}

#============================================================================
# Main Installation Process
#============================================================================

main() {
    echo "🐟 Fish Shell Setup Script"
    echo "=========================="
    echo ""
    
    # Check if running from dotfiles directory
    if [ ! -d "$DOTFILES_DIR/fish" ]; then
        log_error "Fish configuration directory not found at $DOTFILES_DIR/fish"
        log_error "Please run this script from your dotfiles directory"
        exit 1
    fi
    
    detect_os
    
    # Check for required dependencies
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        log_error "git is required but not installed"
        exit 1
    fi
    
    # Main installation steps
    install_fish
    setup_fish_config
    install_fish_plugins
    create_env_file
    setup_shell
    test_fish_config
    
    show_completion_message
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

tmux source-file ~/.tmux.conf