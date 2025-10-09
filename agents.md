# Dotfiles Project Agents Guide

## Architecture Overview

Dotfiles repository containing personal configuration files for developer environment: zsh shell, Neovim editor, tmux multiplexer, and utility scripts. Organized into directories by component (zsh/, vim/, tmux/, etc.) with setup scripts for installation.

Main components: zsh/ (shell config), vim/ (editor config), tmux/ (terminal multiplexer), custom-tools/ (Python utilities), bin/ (scripts and binaries).

Data flow: Setup scripts (setup.sh, setup_noninteractive.sh) install packages, clone plugins, and symlink configs to home directory.

## Developer Workflows

- **Installation**: `./setup.sh` for interactive setup, `./setup_noninteractive.sh` for unattended (Ubuntu-focused)
- **Configuration**: Edit files in respective directories, then run setup to apply
- **Venv management**: Use zsh functions like `ve_auto_chdir on/off` to toggle auto-activation on directory change
- **Plugin updates**: For Neovim, run `nvim +PlugInstall +qall` after setup
- **Testing configs**: Source `~/.zshrc` or reload with `zsh_reload` function

## Conventions & Patterns

- **Config linking**: Setup scripts symlink dotfiles to home (e.g., `zsh/zshrc_manager.sh` → `~/.zshrc`)
- **Zsh functions**: Helpers in `zsh/functions.sh` for toggles, using `set_env` to write to `~/.env`
- **Package installation**: Scripts use apt for Ubuntu, assume common tools (zsh, neovim, tmux, git, fzf, ripgrep)
- **Path assumptions**: Scripts expect repo at `~/dotfiles`, use `$HOME/dotfiles` in configs

## Integration Points

- **External tools**: fzf for fuzzy finding, ripgrep/silversearcher-ag for search, tmux for multiplexing
- **Git**: Configured with user email/name during setup
- **IPython**: Config copied from `default_configs/ipython_config.py`
- **VS Code**: Codegen instructions from `copilot/code-gen.md` for Copilot settings</content>
  <parameter name="filePath">/home/anhvth5/dotfiles/agents.md
