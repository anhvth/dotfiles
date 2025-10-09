# Zsh Folder Agents Guide

## Architecture Overview

Zsh shell configuration with custom functions, aliases, keybindings, and environment management.

Main files: `zshrc_manager.sh` (main loader), `functions.sh` (helpers), `alias.sh` (shortcuts), `venv.sh` (Python venv tools).

Data flow: zshrc_manager.sh sources all config files, sets up environment and completions.

## Developer Workflows

- **Setup**: Source zshrc_manager.sh in ~/.zshrc
- **Venv management**: `ve_auto_chdir on/off` toggles auto-activation, `atv <name>` to assign venvs
- **Shell functions**: Use helpers like `zsh_reload` to reload config, `tree_project` for structure
- **Aliases**: Shortcuts for git (g=git), navigation (..=cd ..)

## Conventions & Patterns

- **Function naming**: Descriptive names like ve_auto_chdir, zsh_reload
- **Environment files**: ~/.env for persistent toggles using set_env function
- **Venv mapping**: atv command associates directories with venv paths
- **Modular config**: Separate files for aliases, functions, keybindings

## Integration Points

- **Python venvs**: Auto-activation on directory change or login
- **Git**: Aliases and prompt integration
- **Fzf**: Fuzzy completion and selection
- **External tools**: ripgrep, silversearcher for search operations