# Vim Folder Agents Guide

## Architecture Overview

Neovim/Vim editor configuration with plugin management and custom key mappings.

Main files: `nvimrc.vim` (config), `install.sh` (setup script), `vimrc.vim` (legacy vim config).

Data flow: Install script sets up vim-plug and Copilot, config sourced in ~/.config/nvim/init.vim.

## Developer Workflows

- **Installation**: Run `install.sh` to install vim-plug and GitHub Copilot
- **Plugin management**: `nvim +PlugInstall +qall` to sync plugins
- **Navigation**: Use H/L for line start/end, J/K for file top/bottom, space to toggle folds
- **Search**: Ctrl-l to clear highlights, leader-f for FZF file search

## Conventions & Patterns

- **Leader key**: Single quote (') for custom mappings
- **Indentation**: 4 spaces by default, 2 for HTML, expandtab enabled
- **Key mappings**: Vim-style navigation, custom shortcuts for common operations
- **Filetype settings**: Auto commands for language-specific indentation

## Integration Points

- **vim-plug**: Plugin manager for Neovim/Vim
- **FZF**: Fuzzy file finder integration
- **GitHub Copilot**: AI code completion (requires :Copilot setup)
- **Language support**: Syntax highlighting, filetype detection