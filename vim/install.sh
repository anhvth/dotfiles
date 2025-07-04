#!/bin/bash
# Vim/Neovim setup script

# sudo apt-get update && install curl
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#nvim + PlugInstall
nvim +'PlugInstall --sync' +qa

# Setup GitHub Copilot
echo "🤖 Setting up GitHub Copilot..."
setup_github_copilot() {
    # Install for Vim if present
    if command -v vim >/dev/null 2>&1; then
        echo "📝 Installing Copilot for Vim..."
        mkdir -p ~/.vim/pack/github/start
        if [ ! -d ~/.vim/pack/github/start/copilot.vim ]; then
            git clone https://github.com/github/copilot.vim ~/.vim/pack/github/start/copilot.vim
        fi
    fi
    
    # Install for Neovim if present  
    if command -v nvim >/dev/null 2>&1; then
        echo "🆕 Installing Copilot for Neovim..."
        mkdir -p ~/.config/nvim/pack/github/start
        if [ ! -d ~/.config/nvim/pack/github/start/copilot.vim ]; then
            git clone https://github.com/github/copilot.vim ~/.config/nvim/pack/github/start/copilot.vim
        fi
    fi
    
    echo "✅ GitHub Copilot installed!"
    echo "📋 Next: Open vim/nvim and run ':Copilot setup'"
}

setup_github_copilot

