````markdown
# Dotfiles Setup

Modern dotfiles configuration for macOS and Ubuntu with automated setup.

## Quick Installation

### One-Line Install (Interactive)

```bash
git clone https://github.com/anhvth/dotfiles ~/dotfiles --single-branch && cd ~/dotfiles && ./setup.sh
```

### One-Line Install (Non-Interactive)

```bash
git clone https://github.com/anhvth/dotfiles ~/dotfiles --single-branch && cd ~/dotfiles && ./setup.sh -y
```

## What Gets Installed

The setup script (`setup.sh`) automatically installs and configures:

### Core Tools

- **zsh** - Modern shell with oh-my-zsh
- **neovim** - Text editor with vim-plug and plugins
- **tmux** - Terminal multiplexer
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep alternative
- **silversearcher-ag** - Code searching tool

### Development Tools

- **GitHub Copilot** - AI pair programming for Neovim
- **pytools** - Custom Python CLI utilities
- **Git** - Configured with your identity

### Configurations

- Zsh with custom functions and plugins
- Neovim with custom config
- Tmux with custom keybindings
- IPython with enhanced settings

## Setup Modes

### Interactive Mode (Default)

Prompts for confirmation at each step:

```bash
./setup.sh
```

### Non-Interactive Mode

Auto-confirms all prompts (useful for automated deployments):

```bash
./setup.sh -y
```

## Platform Support

- ✅ **macOS** - Uses Homebrew
- ✅ **Ubuntu/Debian** - Uses apt-get
- Works in Docker containers and WSL2

## Post-Installation

After setup completes:

1. **Restart your terminal** or run:

   ```bash
   source ~/.zshrc
   ```

2. **Activate GitHub Copilot** (if installed):

   ```bash
   nvim
   :Copilot setup
   ```

3. **Verify pytools** (if installed):
   ```bash
   pytools doctor
   ```

## Manual Setup Options

If you prefer specific setup scripts:

- `setup_ubuntu.sh` - Ubuntu-specific setup
- `setup_mac.sh` - macOS-specific setup
- `setup_noninteractive.sh` - Minimal non-interactive setup

````
## Python venv auto-activation

- cd-based auto-activation is enabled by default. Toggle it via helpers (writes to `~/.env`):

```bash
# Disable auto-activate on cd
ve_auto_chdir off

# Re-enable
ve_auto_chdir on
````

- Login-time auto-activation (activate mapped or last venv at shell start) is off by default. Enable/disable:

```bash
# Enable login-time auto-activation
ve_auto_login on

# Disable (unset)
ve_auto_login off
```

Notes:

- `ve_auto_chdir` controls activation on directory change using mappings from `atv <name>`.
- `ve_auto_login` controls one-time activation at shell startup.
- Reload with `source ~/.zshrc` to apply immediately in the current shell.

# Alias only

```bash
wget https://raw.githubusercontent.com/anhvth/dotfiles/master/bash/bashrc.sh -O ~/.alias.h

echo "source ~/.alias.h" >> ~/.bashrc


rm -rf ~/.fzf

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

~/.fzf/install

```

tmux

```bash
wget https://raw.githubusercontent.com/anhvth/dotfiles/main/tmux/tmux.conf -O ~/.tmux.conf
```

### Codegen

```
wget "https://raw.githubusercontent.com/anhvth/dotfiles/refs/heads/main/copilot/code-gen.md" -O .codegen
```

Ctrol+, -> add this line below

```json
    "github.copilot.chat.codeGeneration.instructions": [
        {
            "file": ".codegen"
        }
    ],
```
````
