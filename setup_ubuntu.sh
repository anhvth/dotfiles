#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Assume dotfiles are already cloned/mounted at this location
DOTFILES_DIR="${HOME}/dotfiles"
# Optional: Change if your ipython config is elsewhere within dotfiles
IPYTHON_CONFIG_SRC="${DOTFILES_DIR}/tools/ipython_config.py"

# --- Icons ---
ICON_SUCCESS="✅"
ICON_INFO="ℹ️"
ICON_WARN="⚠️"
ICON_ERROR="❌"
ICON_SETUP="⚙️"
ICON_PACKAGE="📦"
ICON_DOWNLOAD="📥"
ICON_CONFIG="🔧"
ICON_GIT="🌱"
ICON_SHELL="🐚"
ICON_OS="🐧"
ICON_UPDATE="🔄"
ICON_CHECK="🔎"
ICON_PLUGIN="🔌"
ICON_PYTHON="🐍"

# --- Helper Functions ---

# Function to print messages with icons
log_info() { echo -e "${ICON_INFO} $1"; }
log_success() { echo -e "${ICON_SUCCESS} $1"; }
log_warning() { echo -e "${ICON_WARN} $1"; }
log_error() { echo -e "${ICON_ERROR} $1"; exit 1; } # Exit on error

# Determine if sudo is needed and available
SUDO_CMD=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO_CMD="sudo"
        log_info "Running as non-root. Using 'sudo' for privileged commands."
    else
        log_error "Running as non-root, but 'sudo' command not found. Cannot proceed."
    fi
else
    log_info "Running as root. 'sudo' not required."
fi

# Install a package using apt-get
install_package() {
    local package_name="$1"
    log_info "${ICON_PACKAGE} Attempting to install $package_name..."
    if $SUDO_CMD apt-get install -y "$package_name"; then
        log_success "${ICON_PACKAGE} Successfully installed $package_name."
    else
        log_error "${ICON_PACKAGE} Failed to install $package_name."
    fi
}

# Check if a command exists, if not, install the corresponding package
check_and_install() {
    local cmd="$1"
    local package_name="${2:-$1}" # Use second argument as package name if provided, otherwise assume command name is package name
    log_info "${ICON_CHECK} Checking for command '$cmd'..."
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_warning "'$cmd' not found."
        install_package "$package_name"
    else
        log_success "${ICON_CHECK} '$cmd' (package '$package_name') is already installed."
    fi
}

# --- Main Setup Logic ---

log_info "${ICON_SETUP} Starting setup process..."

# Check OS (although focused on Ubuntu)
log_info "${ICON_OS} Checking operating system compatibility..."
if ! command -v apt-get >/dev/null 2>&1; then
    log_error "${ICON_OS} This script requires 'apt-get' (Debian/Ubuntu). Unsupported operating system."
fi
log_success "${ICON_OS} Detected Ubuntu/Debian based system."

# 0. Initial Update and Essential Tools
log_info "${ICON_UPDATE} 0. Updating package list and installing essential tools..."
log_info "${ICON_UPDATE} Updating package list (apt-get update)..."
if ! $SUDO_CMD apt-get update; then
    log_error "${ICON_UPDATE} Failed to update package lists."
fi
log_success "${ICON_UPDATE} Package lists updated."

log_info "${ICON_PACKAGE} Installing essential tools (curl, git, software-properties-common, build-essential)..."
# Install multiple packages at once
if ! $SUDO_CMD apt-get install -y curl git software-properties-common build-essential; then
    log_error "${ICON_PACKAGE} Failed to install essential tools."
fi
log_success "${ICON_PACKAGE} Essential tools installed."

# Check if dotfiles directory exists
log_info "${ICON_CHECK} Checking for dotfiles directory..."
if [ ! -d "$DOTFILES_DIR" ]; then
    log_error "${ICON_CHECK} Dotfiles directory '$DOTFILES_DIR' not found. Please clone or mount your dotfiles first."
fi
log_success "${ICON_CHECK} Dotfiles directory found at '$DOTFILES_DIR'."


# 1. Check and install zsh, neovim, and tmux
log_info "${ICON_SETUP} 1. Installing core applications: zsh, neovim, tmux"

check_and_install zsh

# Neovim: Use PPA for potentially newer versions as recommended for Ubuntu
log_info "${ICON_PACKAGE} Setting up Neovim installation..."
log_info "${ICON_DOWNLOAD} Adding Neovim stable PPA (ppa:neovim-ppa/stable)..."
if $SUDO_CMD add-apt-repository -y ppa:neovim-ppa/stable; then
    log_success "${ICON_DOWNLOAD} Neovim PPA added successfully."
    log_info "${ICON_UPDATE} Updating package list after adding PPA..."
    if ! $SUDO_CMD apt-get update; then
      log_warning "${ICON_UPDATE} Failed to update package list after adding Neovim PPA, installation might use older version from cache."
    else
      log_success "${ICON_UPDATE} Package list updated."
    fi
else
    log_warning "${ICON_DOWNLOAD} Failed to add Neovim PPA. Will attempt installing 'neovim' from default repositories, which might be outdated."
fi
# Check Neovim command 'nvim' and install package 'neovim'
check_and_install nvim neovim
# Install Python support for Neovim (required for many plugins)
install_package python3-neovim
log_success "${ICON_PYTHON} Neovim Python provider installed."

check_and_install tmux

# 2. Set up dotfiles
log_info "${ICON_SETUP} 2. Configuring dotfiles..."

# Ensure target directories exist
log_info "${ICON_CONFIG} Ensuring configuration directories exist..."
mkdir -p "$HOME/.config/nvim/"
mkdir -p "$HOME/.local/share/nvim/site/autoload/"
log_success "${ICON_CONFIG} Configuration directories ready."

# Zsh
log_info "${ICON_CONFIG} Setting up Zsh configuration (~/.zshrc)..."
echo "source '$DOTFILES_DIR/zsh/zshrc_manager.sh'" > ~/.zshrc
log_success "${ICON_CONFIG} Zsh configuration linked."

# Neovim
log_info "${ICON_CONFIG} Setting up Neovim configuration (~/.config/nvim/init.vim)..."
echo "source $DOTFILES_DIR/vim/nvimrc.vim" > ~/.config/nvim/init.vim
log_success "${ICON_CONFIG} Neovim configuration linked."

# Tmux
log_info "${ICON_CONFIG} Setting up Tmux configuration (~/.tmux.conf)..."
echo "source-file $DOTFILES_DIR/tmux/tmux.conf" > ~/.tmux.conf
log_success "${ICON_CONFIG} Tmux configuration linked."

# 3. Install vim-plug
log_info "${ICON_PLUGIN} 3. Installing vim-plug (Neovim plugin manager)..."
VIMPLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
VIMPLUG_DEST="$HOME/.local/share/nvim/site/autoload/plug.vim"
log_info "${ICON_DOWNLOAD} Downloading vim-plug from $VIMPLUG_URL..."
if curl -fLo "$VIMPLUG_DEST" --create-dirs "$VIMPLUG_URL"; then
    log_success "${ICON_DOWNLOAD} vim-plug downloaded successfully to $VIMPLUG_DEST."
else
    log_error "${ICON_DOWNLOAD} Failed to download vim-plug."
fi

# 4. Install Developer Tools (ripgrep, fzf, silversearcher-ag)
log_info "${ICON_SETUP} 4. Installing developer tools..."
# Install ripgrep (rg) from apt
check_and_install rg ripgrep

# Install fzf (fuzzy finder)
log_info "${ICON_DOWNLOAD} Installing fzf (fuzzy finder)..."
if [ -d "$HOME/.fzf" ]; then
    log_info "${ICON_CHECK} fzf directory (~/.fzf) already exists. Skipping clone."
else
    log_info "${ICON_GIT} Cloning fzf repository..."
    if git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; then
        log_success "${ICON_GIT} fzf repository cloned successfully."
    else
        log_error "${ICON_GIT} Failed to clone fzf repository."
    fi
fi
# Run fzf install script non-interactively
log_info "${ICON_CONFIG} Running fzf installation script..."
if ~/.fzf/install --all --no-update-rc; then # --no-update-rc prevents modifying shell files directly
    log_success "${ICON_CONFIG} fzf installed successfully."
else
    log_error "${ICON_CONFIG} fzf installation script failed."
fi


# Install silver searcher (ag)
check_and_install ag silversearcher-ag

# 5. Install vim plugins
log_info "${ICON_SETUP} 5. Installing vim/nvim plugins via script..."
VIM_INSTALL_SCRIPT="$DOTFILES_DIR/vim/install.sh"
log_info "${ICON_CHECK} Looking for vim plugin install script at '$VIM_INSTALL_SCRIPT'..."
if [ -f "$VIM_INSTALL_SCRIPT" ]; then
    log_info "${ICON_PLUGIN} Found script. Executing '$VIM_INSTALL_SCRIPT'..."
    if sh "$VIM_INSTALL_SCRIPT"; then
        log_success "${ICON_PLUGIN} Vim/Neovim plugins installed successfully (via $VIM_INSTALL_SCRIPT)."
    else
        log_error "${ICON_PLUGIN} Vim/Neovim plugin installation script failed."
    fi
else
    log_warning "${ICON_PLUGIN} Vim plugin installation script not found at '$VIM_INSTALL_SCRIPT'. Skipping this step."
fi

# 6. Configure git
log_info "${ICON_SETUP} ${ICON_GIT} 6. Configuring Git..."
# Check if email and name are already set
log_info "${ICON_CHECK} Checking global git configuration..."
USER_EMAIL=$(git config --global --get user.email)
USER_NAME=$(git config --global --get user.name)

if [ -z "$USER_EMAIL" ]; then
    log_info "${ICON_CONFIG} Setting git global user.email..."
    git config --global user.email "anhvth.226@gmail.com"
    log_success "${ICON_CONFIG} Git global user.email set."
else
    log_info "${ICON_CHECK} Git global user.email already set to '$USER_EMAIL'."
fi

if [ -z "$USER_NAME" ]; then
    log_info "${ICON_CONFIG} Setting git global user.name..."
    git config --global user.name "anh vo"
    log_success "${ICON_CONFIG} Git global user.name set."
else
    log_info "${ICON_CHECK} Git global user.name already set to '$USER_NAME'."
fi

log_info "${ICON_CONFIG} Setting git global core.editor to nvim..."
git config --global core.editor "nvim"
log_success "${ICON_GIT} Git configured (user details and core.editor='nvim')."

# 7. Copy ipython config
log_info "${ICON_SETUP} ${ICON_PYTHON} 7. Configuring IPython..."
IPYTHON_DEST_DIR="$HOME/.ipython/profile_default/"
IPYTHON_DEST_FILE="$IPYTHON_DEST_DIR/ipython_config.py"
log_info "${ICON_CHECK} Checking for IPython config source '$IPYTHON_CONFIG_SRC'..."
if [ -f "$IPYTHON_CONFIG_SRC" ]; then
    log_info "${ICON_CONFIG} Found source config. Ensuring destination directory '$IPYTHON_DEST_DIR' exists..."
    mkdir -p "$IPYTHON_DEST_DIR"
    log_info "${ICON_CONFIG} Copying IPython configuration to $IPYTHON_DEST_FILE..."
    if cp "$IPYTHON_CONFIG_SRC" "$IPYTHON_DEST_FILE"; then
        log_success "${ICON_CONFIG} IPython configuration copied successfully."
    else
        log_error "${ICON_CONFIG} Failed to copy IPython configuration."
    fi
else
    log_warning "${ICON_CHECK} IPython config source '$IPYTHON_CONFIG_SRC' not found. Skipping IPython configuration."
fi

# 8. Change default shell to zsh (Optional, with warnings)
log_info "${ICON_SETUP} ${ICON_SHELL} 8. Setting default shell to zsh (Optional)..."
log_info "${ICON_CHECK} Checking if zsh command is available..."
if command -v zsh >/dev/null 2>&1; then
    ZSH_PATH=$(command -v zsh)
    log_success "${ICON_CHECK} zsh found at $ZSH_PATH."

    CURRENT_USER=$(whoami)
    log_info "${ICON_CHECK} Checking current default shell for user '$CURRENT_USER'..."

    # Get current shell differently depending on whether running as root or not
    if [ "$(id -u)" -eq 0 ]; then
        CURRENT_SHELL=$(getent passwd "$CURRENT_USER" | cut -d: -f7)
    else
        CURRENT_SHELL=$(getent passwd "$CURRENT_USER" | cut -d: -f7) # Can usually get own entry without root
        # Alternative if getent fails for non-root: CURRENT_SHELL=$SHELL (less reliable for *default* shell)
    fi
    log_info "${ICON_CHECK} Current default shell is '$CURRENT_SHELL'."


    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
        log_info "${ICON_CONFIG} Attempting to change default shell to Zsh ($ZSH_PATH)..."
        if [ "$SUDO_CMD" = "sudo" ]; then
            log_warning "Changing shell for non-root user ('$CURRENT_USER') requires 'sudo chsh'."
            log_warning "This might require interactive password entry unless passwordless sudo is configured for 'chsh'."
            log_warning "Attempting non-interactively, but may fail. Consider changing manually or via container setup."
            if $SUDO_CMD chsh -s "$ZSH_PATH" "$CURRENT_USER"; then
               log_success "${ICON_SHELL} Successfully changed default shell to Zsh for user '$CURRENT_USER'."
            else
               log_warning "${ICON_SHELL} Failed to change default shell using 'sudo chsh'. Please change it manually if needed (e.g., 'sudo chsh -s $(which zsh) $USER')."
            fi
        elif [ "$(id -u)" -eq 0 ]; then
             # Running as root, change shell for root user
            if chsh -s "$ZSH_PATH" root; then
                log_success "${ICON_SHELL} Default shell for user 'root' changed to Zsh ($ZSH_PATH)."
            else
                 log_warning "${ICON_SHELL} Failed to change default shell for 'root' using 'chsh'."
            fi
        else
             # Should not happen due to initial SUDO_CMD check, but as a fallback:
             log_warning "${ICON_SHELL} Cannot automatically change shell as non-root without sudo privileges."
        fi
    else
         log_info "${ICON_SHELL} Default shell for user '$CURRENT_USER' is already Zsh ($ZSH_PATH)."
    fi
else
    log_warning "${ICON_CHECK} 'zsh' command not found. Cannot set it as the default shell."
fi


log_success "${ICON_SETUP} Setup script finished!"
log_info "-----------------------------------------------------"
log_info "To apply changes:"
log_info "  - Start a new shell session, or"
log_info "  - Run 'source ~/.zshrc' if you are already in zsh, or"
log_info "  - Run 'zsh' to start a new zsh shell."
if [ -n "$SUDO_CMD" ] && command -v zsh > /dev/null 2>&1 && [ "$(getent passwd "$(whoami)" | cut -d: -f7)" != "$(command -v zsh)" ]; then
    log_warning "Remember: The default shell for your user might *not* have been changed automatically due to needing 'sudo'. You may need to change it manually."
fi
log_info "-----------------------------------------------------"