#!/bin/bash

set -e

# Check if the script is run as root
if [ "$EUID" -eq 0 ]; then
    INSTALL_CMD="apt-get install -y"
    OS="ubuntu"
    apt-get update
    apt-get install -y software-properties-common
    add-apt-repository ppa:neovim-ppa/stable -y
    apt-get update
else
    if command -v sudo >/dev/null 2>&1; then
        INSTALL_CMD="sudo apt-get install -y"
        OS="ubuntu"
        sudo apt-get update
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository ppa:neovim-ppa/stable -y
        sudo apt-get update
    else
        echo "sudo is required to install packages."
        exit 1
    fi
fi

echo "Using install command: $INSTALL_CMD"

install_package() {
    echo "Installing $1..."
    $INSTALL_CMD "$1"
}

check_and_install() {
    if ! command -v "$1" >/dev/null 2>&1; then
        install_package "$1"
    else
        echo "$1 is already installed."
    fi
}

echo "Setup process:"
echo "1. Check and install zsh, neovim, and tmux"
echo "2. Configure default shell to zsh"
echo "3. Set up dotfiles"

# Check and install required software
check_and_install zsh
check_and_install neovim
check_and_install tmux

# Set up dotfiles
echo "source '$HOME/dotfiles/zsh/zshrc_manager.sh'" > ~/.zshrc

mkdir -p ~/.config/nvim/
echo "so $HOME/dotfiles/vim/nvimrc.vim" > ~/.config/nvim/init.vim

echo "source-file $HOME/dotfiles/tmux/tmux.conf" > ~/.tmux.conf

# Install vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install ripgrep
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.2/ripgrep_11.0.2_amd64.deb
$([ "$EUID" -eq 0 ] && echo "dpkg -i" || echo "sudo dpkg -i") ripgrep_11.0.2_amd64.deb
rm ripgrep_11.0.2_amd64.deb

# Install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# Install silver searcher
check_and_install silversearcher-ag

# Install vim plugins
sh "$HOME/dotfiles/vim/install.sh"

# Change default shell to zsh
chsh -s "$(which zsh)"

# Configure git
git config --global user.email "anhvth.226@gmail.com"
git config --global user.name "anh vo"
git config --global core.editor "vim"

# Copy ipython config
mkdir -p ~/.ipython/profile_default
#-------ipython config
config_file="$HOME/.ipython/profile_default/ipython_config.py"

if [ -f "$config_file" ] || [ -L "$config_file" ]; then
    rm "$config_file"
    echo "Removed existing ipython_config.py"
fi

ln -s "$(pwd)/tools/ipython_config.py" "$config_file"
echo "Created symbolic link for $config_file"
#---


echo "Setup complete!"