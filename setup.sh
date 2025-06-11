#!/bin/bash

set -e

# Determine OS and package manager
if command -v brew >/dev/null 2>&1; then
    INSTALL_CMD="brew install"
    OS="mac"
elif command -v apt-get >/dev/null 2>&1; then
    INSTALL_CMD="sudo apt-get install -y"
    OS="ubuntu"
    sudo apt-get update
    sudo add-apt-repository ppa:neovim-ppa/stable -y
else
    echo "Unsupported operating system"
    exit 1
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
if [ "$OS" == "mac" ]; then
    brew install ripgrep
else
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.2/ripgrep_11.0.2_amd64.deb
    sudo dpkg -i ripgrep_11.0.2_amd64.deb
    rm ripgrep_11.0.2_amd64.deb
fi

# Install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

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
cp tools/ipython_config.py ~/.ipython/profile_default/ipython_config.py

echo "Setup complete!"
