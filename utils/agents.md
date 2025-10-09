# Utils Folder Agents Guide

## Architecture Overview

Collection of utility scripts for common development tasks and cross-platform operations.

Main files: `copy` (clipboard utility), `keep_connection.sh` (SSH tunnel maintainer), `gdrive` (Google Drive tool), binaries like `ripgrep_all`.

Data flow: Scripts executed directly or called from other configs (tmux uses copy for clipboard).

## Developer Workflows

- **Clipboard operations**: Use `copy` script for cross-platform clipboard access
- **SSH tunnels**: Run `keep_connection.sh` to maintain persistent SSH connections with port forwarding
- **File operations**: Use various utilities for downloads, organization, connections

## Conventions & Patterns

- **Platform detection**: Scripts check $OSTYPE for Darwin/Windows/Linux compatibility
- **Tool availability**: Fallback chains (xclip/xsel for Linux clipboard)
- **Loop scripts**: Infinite loops with sleep for connection maintenance

## Integration Points

- **Tmux**: copy script used in tmux-keybindings.conf for vi-mode copy-paste
- **SSH**: keep_connection.sh maintains tunnels for remote development
- **External tools**: ripgrep_all for extended search capabilities
