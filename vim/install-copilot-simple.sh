#!/bin/bash
# Simple GitHub Copilot installer function
# Can be sourced or copied into other setup scripts

setup_github_copilot() {
    echo "🤖 Setting up GitHub Copilot for Vim/Neovim..."
    
    # Check Node.js
    if ! command -v node >/dev/null 2>&1; then
        echo "❌ Node.js not found. Installing via brew..."
        if command -v brew >/dev/null 2>&1; then
            brew install node
        else
            echo "❌ Please install Node.js 18+ manually"
            return 1
        fi
    fi
    
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

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_github_copilot
fi
