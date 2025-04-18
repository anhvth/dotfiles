#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
DOTFILES_DIR="$HOME/dotfiles" # Assumes your dotfiles are in ~/dotfiles
GIT_USER_NAME="anh vo"        # Replace with your Git user name
GIT_USER_EMAIL="anhvth.226@gmail.com" # Replace with your Git email

# --- Icons ---
ICON_SUCCESS="✅"
ICON_INFO="ℹ️"
ICON_WARN="⚠️"
ICON_ERROR="❌"

# --- macOS Check ---
echo "$ICON_INFO Checking for macOS and Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  echo "$ICON_ERROR Homebrew (brew) is not installed or not in PATH."
  echo "$ICON_INFO Please install Homebrew first: https://brew.sh/"
  exit 1
else
  echo "$ICON_SUCCESS Homebrew found."
  INSTALL_CMD="brew install"
  UPDATE_CMD="brew update"
fi

# --- Helper Functions ---
install_package() {
  local package_name="$1"
  echo "$ICON_INFO Installing $package_name..."
  if $INSTALL_CMD "$package_name"; then
    echo "$ICON_SUCCESS Successfully installed $package_name."
  else
    echo "$ICON_ERROR Failed to install $package_name."
    exit 1 # Exit because set -e might not catch failures in conditionals
  fi
}

check_and_install() {
  local command_name="$1"
  local package_name="$2" # Use a potentially different package name if needed
  if [ -z "$package_name" ]; then
    package_name="$command_name" # Default to command name if package name not provided
  fi

  echo "$ICON_INFO Checking for $command_name..."
  if ! command -v "$command_name" >/dev/null 2>&1; then
    install_package "$package_name"
  else
    echo "$ICON_SUCCESS $command_name is already installed."
  fi
}

# --- Main Setup ---
echo "$ICON_INFO Starting macOS setup process..."
echo "----------------------------------------"

# 1. Update Homebrew
echo "$ICON_INFO Updating Homebrew..."
if $UPDATE_CMD; then
  echo "$ICON_SUCCESS Homebrew updated."
else
  echo "$ICON_WARN Failed to update Homebrew, proceeding anyway..."
fi
echo "----------------------------------------"

# 2. Install Core Software
echo "$ICON_INFO Installing core software (zsh, neovim, tmux)..."
check_and_install zsh
check_and_install nvim neovim # Check for 'nvim' command, install 'neovim' package
check_and_install tmux
echo "----------------------------------------"

# 3. Install Essential Tools
echo "$ICON_INFO Installing essential tools (ripgrep, fzf, the_silver_searcher)..."
check_and_install rg ripgrep # Check for 'rg' command, install 'ripgrep' package
check_and_install ag the_silver_searcher # Check for 'ag' command, install 'the_silver_searcher' package

# Install fzf (requires git)
if ! command -v fzf >/dev/null 2>&1; then
    echo "$ICON_INFO Installing fzf..."
    if [ -d "$HOME/.fzf" ]; then
        echo "$ICON_WARN ~/.fzf directory already exists. Skipping clone, attempting install script."
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    fi
    if ~/.fzf/install --all; then # '--all' installs keybindings and completion
         echo "$ICON_SUCCESS Successfully installed fzf."
    else
         echo "$ICON_ERROR Failed to install fzf."
         exit 1
    fi
else
    echo "$ICON_SUCCESS fzf is already installed."
fi
echo "----------------------------------------"

# 4. Set up Dotfiles
echo "$ICON_INFO Setting up dotfiles configuration..."
# Ensure dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "$ICON_ERROR Dotfiles directory not found at $DOTFILES_DIR."
    echo "$ICON_INFO Please clone your dotfiles to that location first."
    exit 1
fi

# Zsh config
echo "$ICON_INFO Configuring Zsh..."
echo "source '$DOTFILES_DIR/zsh/zshrc_manager.sh'" > ~/.zshrc
echo "$ICON_SUCCESS ~/.zshrc configured."

# Neovim config
echo "$ICON_INFO Configuring Neovim..."
mkdir -p ~/.config/nvim/
echo "so $DOTFILES_DIR/vim/nvimrc.vim" > ~/.config/nvim/init.vim
echo "$ICON_SUCCESS ~/.config/nvim/init.vim configured."

# Tmux config
echo "$ICON_INFO Configuring Tmux..."
echo "source-file $DOTFILES_DIR/tmux/tmux.conf" > ~/.tmux.conf
echo "$ICON_SUCCESS ~/.tmux.conf configured."
echo "----------------------------------------"

# 5. Install vim-plug (Neovim Plugin Manager)
echo "$ICON_INFO Installing vim-plug for Neovim..."
VIMPLUG_PATH="$HOME/.local/share/nvim/site/autoload/plug.vim"
if [ ! -f "$VIMPLUG_PATH" ]; then
    curl -fLo "$VIMPLUG_PATH" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "$ICON_SUCCESS vim-plug installed."
else
    echo "$ICON_SUCCESS vim-plug already exists."
fi
echo "----------------------------------------"

# 6. Install vim plugins (using your script)
echo "$ICON_INFO Installing Vim/Neovim plugins..."
if [ -f "$DOTFILES_DIR/vim/install.sh" ]; then
    sh "$DOTFILES_DIR/vim/install.sh"
    echo "$ICON_SUCCESS Vim/Neovim plugin installation script executed."
    echo "$ICON_WARN Please run ':PlugInstall' inside Neovim if the script didn't do it automatically."
else
    echo "$ICON_WARN Vim plugin install script not found at $DOTFILES_DIR/vim/install.sh. Skipping."
fi
echo "----------------------------------------"

# 7. Change default shell to zsh
echo "$ICON_INFO Setting default shell to Zsh..."
CURRENT_SHELL=$(dscl . -read ~/ UserShell | sed 's/UserShell: //')
ZSH_PATH=$(which zsh)
if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    if sudo chsh -s "$ZSH_PATH" "$(whoami)"; then
        echo "$ICON_SUCCESS Default shell changed to Zsh. Please log out and back in for the change to take full effect."
    else
        echo "$ICON_ERROR Failed to change default shell."
    fi
else
    echo "$ICON_SUCCESS Default shell is already Zsh."
fi
echo "----------------------------------------"

# 8. Configure Git
echo "$ICON_INFO Configuring Git..."
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global core.editor "nvim" # Use nvim as default git editor
echo "$ICON_SUCCESS Git configured with Name: '$GIT_USER_NAME', Email: '$GIT_USER_EMAIL', Editor: 'nvim'."
echo "----------------------------------------"

# 9. Copy IPython Config (Optional)
IPYTHON_SRC_CONFIG="$DOTFILES_DIR/tools/ipython_config.py" # Assuming it's in dotfiles/tools
IPYTHON_DEST_DIR="$HOME/.ipython/profile_default"
echo "$ICON_INFO Checking for IPython config..."
if [ -f "$IPYTHON_SRC_CONFIG" ]; then
    echo "$ICON_INFO Copying IPython configuration..."
    mkdir -p "$IPYTHON_DEST_DIR"
    cp "$IPYTHON_SRC_CONFIG" "$IPYTHON_DEST_DIR/ipython_config.py"
    echo "$ICON_SUCCESS IPython config copied."
else
    echo "$ICON_INFO IPython source config not found. Creating a default one..."
    mkdir -p "$IPYTHON_DEST_DIR"
    mkdir -p "$(dirname "$IPYTHON_SRC_CONFIG")"
    
    # Create a basic ipython config with some useful settings
    cat > "$IPYTHON_SRC_CONFIG" << 'EOF'
# Configuration file for ipython.
c = get_config()

# Set up auto reload for modules
c.InteractiveShellApp.extensions = ['autoreload']
c.InteractiveShellApp.exec_lines = ['%autoreload 2']

# Display settings
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.true_color = True

# History settings
c.HistoryManager.enabled = True
EOF
    
    # Copy to the ipython directory as well
    cp "$IPYTHON_SRC_CONFIG" "$IPYTHON_DEST_DIR/ipython_config.py"
    echo "$ICON_SUCCESS Default IPython config created and installed."
fi
echo "----------------------------------------"

echo "$ICON_SUCCESS macOS setup script completed!"
echo "$ICON_WARN Remember to restart your terminal or log out/in for all changes (like the default shell) to apply."