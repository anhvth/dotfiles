# ZSH Plugins

This directory contains custom zsh plugins that are part of the dotfiles repository.

## Plugin Management

**Note:** The main zsh plugins (`zsh-autosuggestions` and `zsh-syntax-highlighting`) are NOT stored in this repository. They are installed automatically via the `setup.sh` script to `~/.oh-my-zsh/custom/plugins/`.

This keeps the repository lightweight and allows for easy updates of plugins.

## Custom Plugins

The following custom plugins are kept in this repository:

- `fixls.zsh` - Custom ls color fixes
- `vi-mode.plugin.zsh` - Vi mode customizations

## Installation

Run the setup script to install all plugins:

```bash
./setup.sh
```

The script will:
1. Install oh-my-zsh
2. Clone `zsh-autosuggestions` to `~/.oh-my-zsh/custom/plugins/`
3. Clone `zsh-syntax-highlighting` to `~/.oh-my-zsh/custom/plugins/`

## Manual Installation

If you need to install the plugins manually:

```bash
# zsh-autosuggestions
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# zsh-syntax-highlighting
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```
