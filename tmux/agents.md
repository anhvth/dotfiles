# Tmux Folder Agents Guide

## Architecture Overview

Tmux terminal multiplexer configuration with custom keybindings and visual styling.

Main files: `tmux.conf` (main config), `tmux-keybindings.conf` (key mappings).

Data flow: Main conf sources keybindings, sets colors, mouse mode, status bar.

## Developer Workflows

- **Setup**: `wget https://raw.githubusercontent.com/anhvth/dotfiles/main/tmux/tmux.conf -O ~/.tmux.conf`
- **Reload config**: `tmux source ~/.tmux.conf` or prefix-r
- **Navigation**: Use h/j/k/l for pane navigation (vim-style)
- **Splitting**: Prefix-" for horizontal split, prefix-v for vertical

## Conventions & Patterns

- **Prefix key**: Backtick (`) instead of Ctrl-b
- **Keybindings**: Vim-inspired (h/j/k/l for directions, v for visual selection)
- **Window/pane creation**: New windows/panes start in current directory
- **Copy mode**: Vi mode with custom copy command using ~/dotfiles/utils/copy

## Integration Points

- **Custom copy script**: Uses utils/copy for clipboard integration
- **Colors**: 256-color terminal support with custom status bar styling
- **Mouse**: Enabled for pane/window selection