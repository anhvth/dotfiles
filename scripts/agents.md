# Scripts Folder Agents Guide

## Architecture Overview

Scripts directory containing bootstrap utilities and validation tests for dotfiles setup.

Main subdirs: `bootstrap/` (setup helpers), `smoke/` (config validation tests).

Data flow: Bootstrap scripts use common.sh for logging/installation, smoke tests validate config loading.

## Developer Workflows

- **Setup scripting**: Source common.sh in setup scripts for apt install, file operations, logging
- **Validation**: Run `smoke/run.sh` to test zsh startup, Neovim loading, tmux config parsing
- **Template usage**: Use script-command.template.sh as starting point for new scripts

## Conventions & Patterns

- **Error handling**: set -euo pipefail for strict bash execution
- **Logging**: Use ICON_* variables and log_* functions for consistent output
- **Function naming**: bootstrap::* for reusable helpers (apt_install, link_config, etc.)
- **Path handling**: SCRIPT_DIR and REPO_ROOT variables for relative paths

## Integration Points

- **Package managers**: apt functions for Ubuntu package installation
- **Configs**: Smoke tests validate zsh/, vim/, tmux/ configurations
- **Tmux**: Uses named sessions for isolated testing