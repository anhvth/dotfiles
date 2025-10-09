#!/usr/bin/env bash
#============================================================================
# Comprehensive Setup Script for macOS and Ubuntu
# Supports interactive and non-interactive modes
#============================================================================

set -euo pipefail

#============================================================================
# Configuration
#============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/dotfiles}"
AUTO_YES=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-y|--yes] [-h|--help]"
            echo "  -y, --yes    Non-interactive mode (auto-confirm all prompts)"
            echo "  -h, --help   Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

#============================================================================
# Icons and Colors
#============================================================================

ICON_SUCCESS="✅"
ICON_INFO="ℹ️ "
ICON_WARN="⚠️ "
ICON_ERROR="❌"
ICON_CHECK="🔍"
ICON_PACKAGE="📦"
ICON_CONFIG="⚙️ "
ICON_PLUGIN="🔌"
ICON_DOWNLOAD="⬇️ "
ICON_GIT="📚"
ICON_SHELL="🐚"
ICON_PYTHON="🐍"
ICON_SETUP="🚀"
ICON_UPDATE="🔄"
ICON_OS="💻"

# Colors
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

#============================================================================
# Logging Functions
#============================================================================

log_success() {
    echo -e "${GREEN}${ICON_SUCCESS} $1${NC}"
}

log_info() {
    echo -e "${BLUE}$1${NC}"
}

log_warning() {
    echo -e "${YELLOW}$1${NC}"
}

log_error() {
    echo -e "${RED}$1${NC}" >&2
}

#============================================================================
# OS Detection and Package Manager Functions
#============================================================================

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

has_brew() {
    command_exists brew
}

has_apt() {
    command_exists apt-get
}

detect_sudo() {
    if [[ "$(id -u)" -eq 0 ]]; then
        export BOOTSTRAP_SUDO=""
        log_info "${ICON_INFO} Running as root."
    elif command_exists sudo; then
        export BOOTSTRAP_SUDO="sudo"
        log_info "${ICON_INFO} Using sudo for privileged operations."
    else
        export BOOTSTRAP_SUDO=""
        log_warning "${ICON_WARN} Not root and sudo not available. Some operations may fail."
    fi
}

#============================================================================
# User Confirmation Function
#============================================================================

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$AUTO_YES" == true ]]; then
        log_info "${ICON_INFO} Auto-confirming: $prompt"
        return 0
    fi
    
    local response
    if [[ "$default" == "y" ]]; then
        read -r -p "$prompt [Y/n]: " response
        response=${response:-y}
    else
        read -r -p "$prompt [y/N]: " response
        response=${response:-n}
    fi
    
    [[ "$response" =~ ^[Yy] ]]
}

#============================================================================
# Package Installation Functions
#============================================================================

apt_update() {
    log_info "${ICON_UPDATE} Updating package list..."
    ${BOOTSTRAP_SUDO} apt-get update -qq
    log_success "${ICON_UPDATE} Package list updated."
}

apt_install() {
    local packages=("$@")
    log_info "${ICON_PACKAGE} Installing: ${packages[*]}"
    ${BOOTSTRAP_SUDO} apt-get install -y -qq "${packages[@]}"
    log_success "${ICON_PACKAGE} Installed: ${packages[*]}"
}

add_apt_repository() {
    local repo="$1"
    log_info "${ICON_PACKAGE} Adding repository: $repo"
    ${BOOTSTRAP_SUDO} add-apt-repository -y "$repo"
    log_success "${ICON_PACKAGE} Repository added: $repo"
}

brew_install() {
    local packages=("$@")
    log_info "${ICON_PACKAGE} Installing via Homebrew: ${packages[*]}"
    brew install "${packages[@]}"
    log_success "${ICON_PACKAGE} Installed: ${packages[*]}"
}

brew_update() {
    log_info "${ICON_UPDATE} Updating Homebrew..."
    brew update
    log_success "${ICON_UPDATE} Homebrew updated."
}

#============================================================================
# Configuration Linking Functions
#============================================================================

link_config() {
    local source_line="$1"
    local target_file="$2"
    
    # Create directory if needed
    local target_dir=$(dirname "$target_file")
    mkdir -p "$target_dir"
    
    # Check if already configured
    if [[ -f "$target_file" ]] && grep -qF "$source_line" "$target_file"; then
        log_info "${ICON_CHECK} Already configured: $target_file"
        return 0
    fi
    
    # Write configuration
    echo "$source_line" > "$target_file"
    log_success "${ICON_CONFIG} Configured: $target_file"
}

copy_file() {
    local src="$1"
    local dest="$2"
    
    local dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"
    
    if [[ -f "$src" ]]; then
        cp "$src" "$dest"
        log_success "${ICON_CONFIG} Copied: $src → $dest"
    else
        log_warning "${ICON_WARN} Source not found: $src"
    fi
}

#============================================================================
# Installation Functions
#============================================================================

install_core_packages() {
    local os=$(detect_os)
    
    log_info "${ICON_SETUP} Installing core packages..."
    
    if [[ "$os" == "macos" ]]; then
        if ! has_brew; then
            log_error "${ICON_ERROR} Homebrew not found. Please install from https://brew.sh/"
            exit 1
        fi
        brew_update
        brew_install zsh neovim tmux ripgrep fzf the_silver_searcher git curl node
    else
        apt_update
        add_apt_repository ppa:neovim-ppa/stable
        apt_update
        apt_install zsh neovim tmux ripgrep fzf silversearcher-ag git curl build-essential \
                    software-properties-common python3-neovim
    fi
    
    log_success "${ICON_PACKAGE} Core packages installed."
}

# Install uv (Python package manager) for macOS and Ubuntu
install_uv() {
    log_info "${ICON_DOWNLOAD} Installing uv (Python toolchain manager)..."

    if command_exists uv; then
        log_success "${ICON_CHECK} uv already installed."
        return 0
    fi

    local os=$(detect_os)
    if [[ "$os" == "macos" ]]; then
        if has_brew; then
            log_info "${ICON_PACKAGE} Installing uv via Homebrew..."
            brew_install uv
        else
            log_warning "${ICON_WARN} Homebrew not found. Falling back to official install script."
            curl -fsSL https://astral.sh/uv/install.sh | sh
        fi
    else
        # Ubuntu/Linux: prefer official installer (fast, no system Python changes)
        if command_exists curl; then
            curl -fsSL https://astral.sh/uv/install.sh | sh
        else
            apt_update
            apt_install curl
            curl -fsSL https://astral.sh/uv/install.sh | sh
        fi
    fi

    # Ensure ~/.local/bin is in PATH for current session
    if [[ -d "${HOME}/.local/bin" ]] && [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
        export PATH="${HOME}/.local/bin:${PATH}"
        log_info "${ICON_INFO} Added ~/.local/bin to PATH for this session."
    fi

    if command_exists uv; then
        log_success "${ICON_SUCCESS} uv installed successfully."
    else
        log_warning "${ICON_WARN} uv installation did not complete. You can install manually: curl -fsSL https://astral.sh/uv/install.sh | sh"
    fi
}

install_fzf() {
    log_info "${ICON_DOWNLOAD} Installing fzf..."
    
    if [[ -d "${HOME}/.fzf" ]]; then
        log_info "${ICON_CHECK} fzf already exists. Skipping clone."
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
        log_success "${ICON_GIT} fzf cloned."
    fi
    
    # Install fzf
    if [[ "$AUTO_YES" == true ]]; then
        yes | "${HOME}/.fzf/install" --all --no-bash --no-fish
    else
        "${HOME}/.fzf/install" --all --no-bash --no-fish
    fi
    log_success "${ICON_DOWNLOAD} fzf installed."
}

install_oh_my_zsh() {
    log_info "${ICON_DOWNLOAD} Installing oh-my-zsh..."
    
    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
        log_info "${ICON_CHECK} oh-my-zsh already exists. Skipping."
        return 0
    fi
    
    # Use official oh-my-zsh installation script
    # Set RUNZSH=no to prevent automatic shell switch at the end
    # Set KEEP_ZSHRC=yes to preserve existing .zshrc (we manage it ourselves)
    if [[ "$AUTO_YES" == true ]]; then
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    
    log_success "${ICON_GIT} oh-my-zsh installed."
}

install_zsh_plugins() {
    log_info "${ICON_PLUGIN} Installing zsh plugins..."
    
    local custom_plugins_dir="${HOME}/.oh-my-zsh/custom/plugins"
    mkdir -p "$custom_plugins_dir"
    
    # Install zsh-autosuggestions
    if [[ -d "$custom_plugins_dir/zsh-autosuggestions" ]]; then
        log_info "${ICON_CHECK} zsh-autosuggestions already exists. Updating..."
        (cd "$custom_plugins_dir/zsh-autosuggestions" && git pull -q)
    else
        log_info "${ICON_DOWNLOAD} Cloning zsh-autosuggestions..."
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins_dir/zsh-autosuggestions"
        log_success "${ICON_PLUGIN} zsh-autosuggestions installed."
    fi
    
    # Install zsh-syntax-highlighting
    if [[ -d "$custom_plugins_dir/zsh-syntax-highlighting" ]]; then
        log_info "${ICON_CHECK} zsh-syntax-highlighting already exists. Updating..."
        (cd "$custom_plugins_dir/zsh-syntax-highlighting" && git pull -q)
    else
        log_info "${ICON_DOWNLOAD} Cloning zsh-syntax-highlighting..."
        git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$custom_plugins_dir/zsh-syntax-highlighting"
        log_success "${ICON_PLUGIN} zsh-syntax-highlighting installed."
    fi
    
    log_success "${ICON_PLUGIN} Zsh plugins installed."
}

install_vim_plug() {
    log_info "${ICON_PLUGIN} Installing vim-plug..."
    
    local plug_path="${HOME}/.local/share/nvim/site/autoload/plug.vim"
    mkdir -p "$(dirname "$plug_path")"
    
    if [[ -f "$plug_path" ]]; then
        log_info "${ICON_CHECK} vim-plug already exists."
    else
        curl -fsSLo "$plug_path" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        log_success "${ICON_PLUGIN} vim-plug installed."
    fi
}

install_vim_plugins() {
    log_info "${ICON_PLUGIN} Installing Neovim plugins..."
    
    if nvim +PlugInstall +qall; then
        log_success "${ICON_PLUGIN} Neovim plugins installed successfully."
    else
        log_warning "${ICON_PLUGIN} Failed to install Neovim plugins. You may need to run 'nvim +PlugInstall +qall' manually."
    fi
}

install_github_copilot() {
    log_info "${ICON_PLUGIN} Installing GitHub Copilot for Neovim..."
    
    # Check Node.js
    if ! command_exists node; then
        log_warning "${ICON_WARN} Node.js not found. Installing..."
        local os=$(detect_os)
        if [[ "$os" == "macos" ]]; then
            brew_install node
        else
            # Node.js 18+ is already installed with core packages
            log_success "${ICON_CHECK} Node.js should be installed."
        fi
    fi
    
    local node_version=$(node --version | sed 's/v//' | cut -d. -f1)
    if [[ "$node_version" -lt 18 ]]; then
        log_warning "${ICON_WARN} Node.js version is too old (need 18+). Current: $node_version"
    fi
    
    # Install for Neovim
    local nvim_copilot_dir="${HOME}/.config/nvim/pack/github/start"
    mkdir -p "$nvim_copilot_dir"
    
    if [[ -d "$nvim_copilot_dir/copilot.vim" ]]; then
        log_info "${ICON_CHECK} Copilot for Neovim already exists. Updating..."
        (cd "$nvim_copilot_dir/copilot.vim" && git pull)
    else
        git clone https://github.com/github/copilot.vim "$nvim_copilot_dir/copilot.vim"
        log_success "${ICON_PLUGIN} GitHub Copilot for Neovim installed."
    fi
    
    log_info "${ICON_INFO} To activate Copilot, run ':Copilot setup' in Neovim"
}

install_pytools() {
    log_info "${ICON_PYTHON} Installing pytools..."
    
    local pytools_dir="${DOTFILES_DIR}/custom-tools/pytools"
    
    if [[ ! -d "$pytools_dir" ]]; then
        log_warning "${ICON_WARN} pytools directory not found at $pytools_dir"
        return 1
    fi
    
    # Check for uv or pip
    if command_exists uv; then
        log_info "${ICON_PYTHON} Using uv to install pytools..."
        (cd "$pytools_dir" && uv pip install -e .)
    elif command_exists pip3; then
        log_info "${ICON_PYTHON} Using pip to install pytools..."
        (cd "$pytools_dir" && pip3 install -e .)
    elif command_exists pip; then
        log_info "${ICON_PYTHON} Using pip to install pytools..."
        (cd "$pytools_dir" && pip install -e .)
    else
        log_warning "${ICON_WARN} Neither uv nor pip found. Skipping pytools installation."
        log_info "${ICON_INFO} Install pip/uv and run: cd $pytools_dir && pip install -e ."
        return 1
    fi
    
    log_success "${ICON_PYTHON} pytools installed."
}

setup_dotfiles() {
    log_info "${ICON_CONFIG} Setting up dotfiles..."
    
    # Zsh
    link_config "source '$DOTFILES_DIR/zsh/zshrc_manager.sh'" "${HOME}/.zshrc"
    
    # Neovim
    link_config "so $DOTFILES_DIR/vim/nvimrc.vim" "${HOME}/.config/nvim/init.vim"
    
    # Tmux
    link_config "source-file $DOTFILES_DIR/tmux/tmux.conf" "${HOME}/.tmux.conf"
    
    # IPython
    copy_file "${DOTFILES_DIR}/tools/ipython_config.py" \
              "${HOME}/.ipython/profile_default/ipython_config.py"
    
    log_success "${ICON_CONFIG} Dotfiles configured."
}

configure_git() {
    log_info "${ICON_GIT} Configuring Git..."
    
    local git_email=$(git config --global user.email || echo "")
    local git_name=$(git config --global user.name || echo "")
    
    if [[ -z "$git_email" ]]; then
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "Enter your Git email: " git_email
            git config --global user.email "$git_email"
        else
            log_warning "${ICON_WARN} Skipping Git email (use 'git config --global user.email <email>')"
        fi
    else
        log_info "${ICON_CHECK} Git email already set: $git_email"
    fi
    
    if [[ -z "$git_name" ]]; then
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "Enter your Git name: " git_name
            git config --global user.name "$git_name"
        else
            log_warning "${ICON_WARN} Skipping Git name (use 'git config --global user.name <name>')"
        fi
    else
        log_info "${ICON_CHECK} Git name already set: $git_name"
    fi
    
    git config --global core.editor "nvim"
    log_success "${ICON_GIT} Git configured with editor: nvim"
}

change_default_shell() {
    log_info "${ICON_SHELL} Checking default shell..."
    
    if ! command_exists zsh; then
        log_warning "${ICON_WARN} zsh not found. Cannot set as default shell."
        return 1
    fi
    
    local zsh_path=$(command -v zsh)
    local current_user=$(whoami)
    local current_shell=$(getent passwd "$current_user" 2>/dev/null | cut -d: -f7)
    
    if [[ -z "$current_shell" ]]; then
        current_shell="$SHELL"
    fi
    
    if [[ "$current_shell" == "$zsh_path" ]]; then
        log_success "${ICON_SHELL} Default shell is already zsh."
        return 0
    fi
    
    if ! confirm "Change default shell to zsh?" "y"; then
        log_info "${ICON_INFO} Keeping current shell: $current_shell"
        return 0
    fi
    
    log_info "${ICON_SHELL} Changing default shell to zsh..."
    if [[ -n "${BOOTSTRAP_SUDO}" ]]; then
        ${BOOTSTRAP_SUDO} chsh -s "$zsh_path" "$current_user" || \
            log_warning "${ICON_WARN} Failed to change shell. You may need to run manually: sudo chsh -s \$(which zsh) $current_user"
    else
        chsh -s "$zsh_path" || \
            log_warning "${ICON_WARN} Failed to change shell. Run manually: chsh -s \$(which zsh)"
    fi
    
    log_success "${ICON_SHELL} Default shell changed to zsh."
}

#============================================================================
# Main Setup Function
#============================================================================

main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  🚀 Dotfiles Setup - macOS & Ubuntu                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Detect OS
    local os=$(detect_os)
    log_info "${ICON_OS} Operating System: $os"
    
    if [[ "$os" == "unknown" ]]; then
        log_error "${ICON_ERROR} Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    # Detect sudo capability
    detect_sudo
    
    # Confirm dotfiles directory
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "${ICON_ERROR} Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    log_success "${ICON_CHECK} Dotfiles directory: $DOTFILES_DIR"
    
    echo ""
    log_info "${ICON_INFO} Setup mode: $([ "$AUTO_YES" == true ] && echo "Non-interactive (-y)" || echo "Interactive")"
    echo ""
    
    if [[ "$AUTO_YES" == false ]]; then
        if ! confirm "Start setup?" "y"; then
            log_info "${ICON_INFO} Setup cancelled."
            exit 0
        fi
    fi
    
    echo ""
    echo "─────────────────────────────────────────────────────────────"
    
    # Step 1: Install core packages
    install_core_packages

    echo "─────────────────────────────────────────────────────────────"

    # Step 1.1: Install uv
    install_uv

    echo "─────────────────────────────────────────────────────────────"

    # Step 2: Install fzf
    install_fzf
    
    echo "─────────────────────────────────────────────────────────────"
    
    # Step 3: Install oh-my-zsh
    install_oh_my_zsh
    
    echo "─────────────────────────────────────────────────────────────"
    
    # Step 4: Install zsh plugins
    install_zsh_plugins
    
    echo "─────────────────────────────────────────────────────────────"
    
    # Step 5: Setup dotfiles
    setup_dotfiles
    
    echo "─────────────────────────────────────────────────────────────"
    
    # Step 6: Install vim-plug
    install_vim_plug
    
    echo "─────────────────────────────────────────────────────────────"
    
    # Step 7: Install vim plugins
    install_vim_plugins
    
    echo "─────────────────────────────────────────────────────────────"
    
    # Step 8: Install GitHub Copilot
    if confirm "Install GitHub Copilot for Neovim?" "y"; then
        install_github_copilot
    else
        log_info "${ICON_INFO} Skipping GitHub Copilot installation."
    fi
    
    echo "─────────────────────────────────────────────────────────────"
    
    # Step 9: Install pytools
    if confirm "Install pytools?" "y"; then
        install_pytools
    else
        log_info "${ICON_INFO} Skipping pytools installation."
    fi
    
    echo "─────────────────────────────────────────────────────────────"
    
    # Step 10: Configure Git
    configure_git
    
    echo "─────────────────────────────────────────────────────────────"
    
    # Step 11: Change default shell
    change_default_shell
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  ✅ Setup Complete!                                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "📋 Next Steps:"
    echo ""
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. For GitHub Copilot, run in Neovim: :Copilot setup"
    echo "  3. For pytools, run: pytools doctor"
    echo ""
    log_info "🎉 Happy coding!"
    echo ""
}

# Run main
main "$@"
