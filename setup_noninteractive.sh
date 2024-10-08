#!/bin/bash

set -e

# Update the package list and add the Neovim repository
sudo apt-get update -y
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt-get update -y

# Define the package installation command
INSTALL_CMD="sudo apt-get install -y"

# Function to install packages if not already installed
install_package() {
    echo "Installing $1..."
    $INSTALL_CMD "$1"
}

# Install required packages
echo "Installing required packages: zsh, neovim, tmux, ripgrep, fzf, silversearcher-ag, curl, git"
install_package zsh
install_package neovim
install_package tmux
install_package ripgrep
install_package fzf
install_package silversearcher-ag
install_package curl
install_package git

# Set up dotfiles
echo "Setting up dotfiles..."
echo "source '$HOME/dotfiles/zsh/zshrc_manager.sh'" > ~/.zshrc

mkdir -p ~/.config/nvim/
echo "so $HOME/dotfiles/vim/nvimrc.vim" > ~/.config/nvim/init.vim

echo "source-file $HOME/dotfiles/tmux/tmux.conf" > ~/.tmux.conf

# Install vim-plug for Neovim
echo "Installing vim-plug for Neovim..."
curl -fsLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install fzf non-interactively
if [ ! -d "$HOME/.fzf" ]; then
    echo "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    yes | ~/.fzf/install --all --no-bash --no-fish
fi

# Install Neovim plugins non-interactively
echo "Installing Neovim plugins..."
nvim +PlugInstall +qall

# Change the default shell to zsh without prompting for password
echo "Changing the default shell to zsh for the current user..."

# Configure Git
echo "Configuring Git..."
git config --global user.email "anhvth.226@gmail.com"
git config --global user.name "anh vo"
git config --global core.editor "vim"

# Copy IPython configuration
echo "Copying IPython configuration..."
mkdir -p ~/.ipython/profile_default
cp tools/ipython_config.py ~/.ipython/profile_default/ipython_config.py

echo "Setup complete!"
