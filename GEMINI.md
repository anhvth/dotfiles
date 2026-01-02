# Gemini Context: Dotfiles Project

## Project Overview

This repository contains personal configuration files (dotfiles) and custom developer tools, primarily targeting **macOS** and **Ubuntu** environments. It automates the setup of a modern development environment featuring Zsh, Neovim, Tmux, and a suite of custom Python utilities.

### Key Components

*   **Zsh**: Shell configuration using `oh-my-zsh`, custom aliases, and functions.
*   **Neovim**: Editor configuration (`init.vim`) managed with `vim-plug`, including plugins for fuzzy finding (`fzf`), code completion (`coc.nvim` or similar implied), and GitHub Copilot.
*   **Tmux**: Terminal multiplexer configuration with custom keybindings and status bar styling.
*   **PyTools**: A unified CLI (`pytools`) for development workflows, including project snapshots for LLMs (`cat-projects`), environment management, and system utilities.
*   **Improve Code**: A CLI tool (`improve-code`) for code formatting, auto-fixing, and quality reporting.

## Installation & Usage

### Core Setup

The primary entry point is `setup.sh`, which handles OS detection and package installation.

*   **Interactive Setup:**
    ```bash
    ./setup.sh
    ```
*   **Non-Interactive (Unattended) Setup:**
    ```bash
    ./setup.sh -y
    # OR via Make
    make install
    ```
*   **Ubuntu Specific:** `make install-ubuntu` (calls `setup_ubuntu.sh`)
*   **macOS Specific:** `make install-mac` (calls `setup_mac.sh`)

### PyTools Installation

The custom Python tools are located in `custom-tools/`.

```bash
# Install PyTools (requires uv or pip)
cd custom-tools/pytools
uv pip install -e .  # Recommended
# OR
pip install -e .
```

### Verification

*   **Smoke Tests:** Run `make smoke` to verify the installation of core tools (zsh, nvim, tmux).
*   **PyTools Check:** Run `pytools doctor` to check dependencies.

## Directory Structure

*   `bin/`: Global executable scripts.
*   `custom-tools/`: Custom Python applications (`pytools`, `improve-code`).
*   `default_configs/`: Fallback/template configurations (e.g., IPython).
*   `scripts/`: Helper scripts for bootstrapping and testing.
*   `tmux/`: Tmux configuration files.
*   `vim/`: Neovim configuration files.
*   `zsh/`: Zsh configuration files and scripts.
*   `setup.sh`: Main setup orchestrator.
*   `Makefile`: Task runner for installation and testing.

## Development Conventions

*   **Configuration Management:** Configuration files in the repository (e.g., `vim/nvimrc.vim`) are symlinked to their target locations (e.g., `~/.config/nvim/init.vim`) by the setup scripts. **Do not edit files in `~` directly; edit them in the repo and re-run setup or re-source.**
*   **Python Tools:**
    *   Built with modern Python standards (pyproject.toml).
    *   Preferred package manager: `uv`.
    *   Testing: `pytest` (e.g., `pytest custom-tools/pytools/tests`).
*   **Shell Scripts:** Should be POSIX-compliant or Bash-specific where noted. Verified with `shellcheck` (via `make lint-shell`).
*   **Code Style:**
    *   Python: Adhere to standard PEP 8, enforced/formatted by the `improve-code` tool.
    *   Shell: Follow Google Shell Style Guide where applicable.

## Architecture Notes

*   **Agent Awareness:** This repo contains `agents.md` files in various subdirectories. these likely provide context-specific instructions for AI agents.
*   **Venv Management:** The `zsh` config includes helpers for auto-activating Python virtual environments (`ve_auto_chdir`, `ve_auto_login`).
*   **MCP Support:** `pytools` includes an experimental Model Context Protocol (MCP) server (`pytools-mcp`), allowing AI assistants to interface safely with local tools.
