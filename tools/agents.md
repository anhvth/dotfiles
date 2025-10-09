# Tools Folder Agents Guide

## Architecture Overview

Configuration files for development tools and utilities.

Main files: `ipython_config.py` - IPython/Jupyter interactive shell configuration.

Data flow: Config files copied to appropriate locations during setup (e.g., ~/.ipython/profile_default/).

## Developer Workflows

- **IPython setup**: Config copied during dotfiles installation, enables autoreload and true color
- **Interactive development**: %autoreload 2 automatically reloads modules on change
- **Customization**: Edit ipython_config.py and re-run setup to apply changes

## Conventions & Patterns

- **Config format**: IPython c.get_config() style with extension loading
- **Extensions**: autoreload for automatic module reloading
- **Display**: True color support, no exit confirmation for faster workflow

## Integration Points

- **IPython/Jupyter**: Interactive Python environments
- **Setup scripts**: Config copied during unattended setup
- **Development workflow**: Enhances REPL experience with auto-reload