#!/bin/bash
# GitHub Copilot Setup Script for Vim/Neovim
# This script installs and configures GitHub Copilot for both Vim and Neovim

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update Node.js to latest version
update_nodejs() {
    local os=$(detect_os)
    
    print_status "Installing/updating Node.js to latest version (v22.x)..."
    
    case $os in
        "macos")
            if has_brew; then
                print_status "Using Homebrew to update Node.js..."
                brew update
                if brew list node &>/dev/null; then
                    brew upgrade node
                else
                    brew install node
                fi
                print_success "Node.js updated via Homebrew"
            else
                print_warning "Homebrew not found. Please install Homebrew or update Node.js manually"
                return 1
            fi
            ;;
        "linux")
            if has_apt; then
                print_status "Using NodeSource repository to install Node.js v22.x..."
                # Remove current Node.js repo (optional but recommended)
                sudo rm -f /etc/apt/sources.list.d/nodesource.list
                
                # Add the latest Node.js (v22.x) repo
                curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
                
                # Install Node.js
                sudo apt-get install -y nodejs
                print_success "Node.js v22.x installed via NodeSource"
            elif has_yum_dnf; then
                print_status "Installing Node.js via package manager..."
                if command_exists dnf; then
                    sudo dnf install -y nodejs npm
                else
                    sudo yum install -y nodejs npm
                fi
                print_success "Node.js installed via yum/dnf"
            else
                print_warning "No supported package manager found. Please install Node.js manually"
                return 1
            fi
            ;;
        *)
            print_warning "Unsupported OS. Please install Node.js manually"
            return 1
            ;;
    esac
}

# Check Node.js version
check_nodejs() {
    if command_exists node; then
        local node_version=$(node --version | sed 's/v//')
        local major_version=$(echo $node_version | cut -d. -f1)
        if [ "$major_version" -ge 18 ]; then
            print_success "Node.js $node_version found (required: >=18)"
            
            # Ask user if they want to update to latest
            echo ""
            read -p "Do you want to update Node.js to the latest version (v22.x)? (y/N): " update_choice
            if [[ "$update_choice" =~ ^[Yy]$ ]]; then
                update_nodejs
                # Re-check version after update
                if command_exists node; then
                    local new_version=$(node --version | sed 's/v//')
                    print_success "Node.js updated to version $new_version"
                fi
            fi
            return 0
        else
            print_error "Node.js version $node_version found, but version 18 or higher is required"
            echo ""
            read -p "Do you want to update Node.js to the latest version (v22.x)? (y/N): " update_choice
            if [[ "$update_choice" =~ ^[Yy]$ ]]; then
                update_nodejs
                return 0
            else
                return 1
            fi
        fi
    else
        print_error "Node.js not found"
        echo ""
        read -p "Do you want to install Node.js (v22.x)? (y/N): " install_choice
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            update_nodejs
            return 0
        else
            print_error "Please install Node.js 18 or higher"
            return 1
        fi
    fi
}

# Check Vim version
check_vim() {
    if command_exists vim; then
        local vim_version=$(vim --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1)
        print_success "Vim $vim_version found"
        return 0
    else
        print_warning "Vim not found"
        return 1
    fi
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Check if Homebrew is available (macOS)
has_brew() {
    command_exists brew
}

# Check if apt is available (Ubuntu/Debian)
has_apt() {
    command_exists apt
}

# Check if yum/dnf is available (RHEL/CentOS/Fedora)
has_yum_dnf() {
    command_exists yum || command_exists dnf
}

# Update Neovim to latest version
update_neovim() {
    local os=$(detect_os)
    
    print_status "Updating Neovim to latest version..."
    
    case $os in
        "macos")
            if has_brew; then
                print_status "Using Homebrew to update Neovim..."
                brew update
                if brew list neovim &>/dev/null; then
                    brew upgrade neovim
                else
                    brew install neovim
                fi
                print_success "Neovim updated via Homebrew"
            else
                print_warning "Homebrew not found. Please install Homebrew or update Neovim manually"
                return 1
            fi
            ;;
        "linux")
            if has_apt; then
                print_status "Using apt to update Neovim..."
                sudo apt update
                sudo apt install -y neovim
                print_success "Neovim updated via apt"
            elif has_yum_dnf; then
                if command_exists dnf; then
                    print_status "Using dnf to update Neovim..."
                    sudo dnf install -y neovim
                else
                    print_status "Using yum to update Neovim..."
                    sudo yum install -y neovim
                fi
                print_success "Neovim updated via yum/dnf"
            else
                print_warning "No supported package manager found. Please update Neovim manually"
                return 1
            fi
            ;;
        *)
            print_warning "Unsupported OS. Please update Neovim manually"
            return 1
            ;;
    esac
}

# Check Neovim version
check_neovim() {
    if command_exists nvim; then
        local nvim_version=$(nvim --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        print_success "Neovim $nvim_version found"
        
        # Ask user if they want to update
        echo ""
        read -p "Do you want to update Neovim to the latest version? (y/N): " update_choice
        if [[ "$update_choice" =~ ^[Yy]$ ]]; then
            update_neovim
            # Re-check version after update
            if command_exists nvim; then
                local new_version=$(nvim --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
                print_success "Neovim updated to version $new_version"
            fi
        fi
        return 0
    else
        print_warning "Neovim not found"
        echo ""
        read -p "Do you want to install Neovim? (y/N): " install_choice
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            update_neovim
            return 0
        else
            return 1
        fi
    fi
}

# Install Copilot for Vim
install_copilot_vim() {
    local vim_dir="$HOME/.vim/pack/github/start"
    print_status "Installing GitHub Copilot for Vim..."
    
    mkdir -p "$vim_dir"
    
    if [ -d "$vim_dir/copilot.vim" ]; then
        print_warning "Copilot for Vim already exists. Updating..."
        cd "$vim_dir/copilot.vim" && git pull
    else
        git clone https://github.com/github/copilot.vim "$vim_dir/copilot.vim"
        print_success "GitHub Copilot for Vim installed successfully"
    fi
}

# Install Copilot for Neovim
install_copilot_neovim() {
    local nvim_dir="$HOME/.config/nvim/pack/github/start"
    print_status "Installing GitHub Copilot for Neovim..."
    
    mkdir -p "$nvim_dir"
    
    if [ -d "$nvim_dir/copilot.vim" ]; then
        print_warning "Copilot for Neovim already exists. Updating..."
        cd "$nvim_dir/copilot.vim" && git pull
    else
        git clone https://github.com/github/copilot.vim "$nvim_dir/copilot.vim"
        print_success "GitHub Copilot for Neovim installed successfully"
    fi
}

# Add Copilot configuration to vimrc
configure_vim() {
    local vimrc="$HOME/.vimrc"
    local config_marker="\" === GitHub Copilot Configuration ==="
    
    if [ -f "$vimrc" ] && grep -q "$config_marker" "$vimrc"; then
        print_warning "Copilot configuration already exists in $vimrc"
        return
    fi
    
    print_status "Adding Copilot configuration to $vimrc..."
    
    cat >> "$vimrc" << 'EOF'

" === GitHub Copilot Configuration ===
" Enable Copilot for specific filetypes (optional)
" let g:copilot_filetypes = {
"   \ '*': v:false,
"   \ 'python': v:true,
"   \ 'javascript': v:true,
"   \ 'typescript': v:true,
"   \ 'markdown': v:true,
"   \ 'vim': v:true,
"   \ 'shell': v:true,
"   \ }

" Disable Copilot for large files (>100KB)
autocmd BufReadPre *
  \ let f = getfsize(expand("<afile>")) |
  \ if f > 100000 | let b:copilot_enabled = v:false | endif

" Copilot keybindings
" Tab to accept suggestion (default)
" Ctrl+] to dismiss suggestion
" Alt+] to accept word
" Alt+\ to accept line

" Optional: Disable Copilot on startup (uncomment to use)
" autocmd VimEnter * Copilot disable
EOF
    
    print_success "Copilot configuration added to $vimrc"
}

# Add Copilot configuration to init.vim
configure_neovim() {
    local init_vim="$HOME/.config/nvim/init.vim"
    local config_marker="\" === GitHub Copilot Configuration ==="
    
    # Create nvim config directory if it doesn't exist
    mkdir -p "$HOME/.config/nvim"
    
    if [ -f "$init_vim" ] && grep -q "$config_marker" "$init_vim"; then
        print_warning "Copilot configuration already exists in $init_vim"
        return
    fi
    
    print_status "Adding Copilot configuration to $init_vim..."
    
    cat >> "$init_vim" << 'EOF'

" === GitHub Copilot Configuration ===
" Enable Copilot for specific filetypes (optional)
" let g:copilot_filetypes = {
"   \ '*': v:false,
"   \ 'python': v:true,
"   \ 'javascript': v:true,
"   \ 'typescript': v:true,
"   \ 'markdown': v:true,
"   \ 'vim': v:true,
"   \ 'shell': v:true,
"   \ }

" Disable Copilot for large files (>100KB)
autocmd BufReadPre *
  \ let f = getfsize(expand("<afile>")) |
  \ if f > 100000 | let b:copilot_enabled = v:false | endif

" Copilot keybindings
" Tab to accept suggestion (default)
" Ctrl+] to dismiss suggestion
" Alt+] to accept word
" Alt+\ to accept line

" Optional: Disable Copilot on startup (uncomment to use)
" autocmd VimEnter * Copilot disable
EOF
    
    print_success "Copilot configuration added to $init_vim"
}

# Show setup instructions
show_setup_instructions() {
    echo ""
    echo "=================================================="
    echo "🎉 GitHub Copilot Installation Complete!"
    echo "=================================================="
    echo ""
    echo "📋 Next Steps:"
    echo ""
    echo "1. Open Vim or Neovim"
    echo "2. Run: :Copilot setup"
    echo "   This will guide you through authentication"
    echo ""
    echo "3. Enable Copilot: :Copilot enable"
    echo ""
    echo "4. Start coding! Press Tab to accept suggestions"
    echo ""
    echo "🔧 Useful Commands:"
    echo "   :Copilot status     - Check status"
    echo "   :Copilot enable     - Enable Copilot"
    echo "   :Copilot disable    - Disable Copilot"
    echo "   :Copilot panel      - Open suggestion panel"
    echo ""
    echo "⌨️  Keybindings:"
    echo "   Tab                 - Accept suggestion"
    echo "   Ctrl+]              - Dismiss suggestion"
    echo "   Alt+]               - Accept word"
    echo "   Alt+\\               - Accept line"
    echo ""
    echo "📖 For more info: https://github.com/github/copilot.vim"
    echo "=================================================="
}

# Main function
main() {
    echo "🚀 Setting up GitHub Copilot for Vim/Neovim..."
    echo ""
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! command_exists git; then
        print_error "Git not found. Please install git first."
        exit 1
    fi
    
    if ! check_nodejs; then
        print_error "Please install Node.js 18 or higher before continuing."
        exit 1
    fi
    
    local has_vim=false
    local has_neovim=false
    
    if check_vim; then
        has_vim=true
    fi
    
    if check_neovim; then
        has_neovim=true
    fi
    
    if [ "$has_vim" = false ] && [ "$has_neovim" = false ]; then
        print_error "Neither Vim nor Neovim found. Please install at least one of them."
        exit 1
    fi
    
    echo ""
    
    # Install Copilot
    if [ "$has_vim" = true ]; then
        install_copilot_vim
        configure_vim
    fi
    
    if [ "$has_neovim" = true ]; then
        install_copilot_neovim
        configure_neovim
    fi
    
    show_setup_instructions
}

# Run main function
main "$@"
