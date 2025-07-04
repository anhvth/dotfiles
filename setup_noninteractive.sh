#!/bin/bash
# /home/anhvth5/dotfiles/setup_noninteractive.sh

set -e

# Update the package list and add the Neovim repository
sudo apt-get update -y
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt-get update -y

# Install required packages in a single line
echo "Installing required packages: zsh, neovim, tmux, ripgrep, fzf, silversearcher-ag, curl, git"
sudo apt-get install -y zsh neovim tmux ripgrep fzf silversearcher-ag curl git

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


# Change the default shell to zsh without prompting for password
echo "Changing the default shell to zsh for the current user..."

# Copy IPython configuration
echo "Copying IPython configuration..."
mkdir -p ~/.ipython/profile_default
cp custom-tools/ipython_config.py ~/.ipython/profile_default/ipython_config.py
# Configure git
read -p "Enter your Git email: " git_email
git config --global user.email "$git_email"
read -p "Enter your Git username: " git_username
git config --global user.name "$git_username"
git config --global core.editor "vim"

echo "Setup complete!"
echo "Run: nvim +PlugInstall +qall"
