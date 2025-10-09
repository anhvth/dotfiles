# Bash Folder Agents Guide

## Architecture Overview

Bash shell configuration providing aliases, prompt customization, and fzf integration for improved command-line experience.

Main file: `bashrc.sh` - comprehensive bashrc with colors, aliases, history, completion.

Data flow: Sourced in ~/.bashrc for standalone alias setup (wget from GitHub).

## Developer Workflows

- **Standalone setup**: `wget https://raw.githubusercontent.com/anhvth/dotfiles/master/bash/bashrc.sh -O ~/.bashrc` and source it
- **Integration**: Source `bashrc.sh` in existing ~/.bashrc for additional aliases
- **fzf usage**: Use `fo` to fuzzy-open files, `fcd` to cd to directories, Ctrl-R for history search

## Conventions & Patterns

- **Alias naming**: Short aliases for common commands (ll=ls -l, g=git, gs=git status)
- **Prompt format**: User@host:dir (git-branch)$ with colors (green user, blue dir, yellow branch)
- **History settings**: Large history size, append mode, ignore duplicates
- **fzf integration**: Default opts for height/layout, custom functions for file/dir selection

## Integration Points

- **fzf**: Fuzzy finder for file selection, directory navigation, history search
- **Git**: Branch parsing in prompt, git aliases
- **Completion**: Bash completion for commands, programmable completion enabled
- **External configs**: Sources ~/.alias.h if exists, includes zsh/alias.sh
