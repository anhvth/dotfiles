# Bash Configuration

A comprehensive bash configuration system with performance modes, inspired by the zsh and fish configurations in this dotfiles repository.

## Quick Start

1. **Run the setup script:**

   ```bash
   ./setup_bash.sh
   ```

2. **Start a new bash session or reload:**
   ```bash
   exec bash
   # or
   source ~/.bashrc
   ```

## Performance Modes

The bash configuration supports three performance modes:

### 🚀 **Fastest Mode**

- Minimal setup for maximum speed
- Basic aliases and essential PATH
- Ultra-minimal prompt
- Best for: servers, CI/CD, performance-critical environments

```bash
bash_set_mode fastest
```

### ⚖️ **Balanced Mode** (Default)

- Optimized setup with key features
- Git integration in prompt
- FZF integration
- Bash completion
- Best for: daily development work

```bash
bash_set_mode balanced
```

### 🔧 **Full Mode**

- All features enabled
- Enhanced git prompt with status
- Virtual environment auto-activation
- Advanced history search
- Extended completions
- Best for: feature-rich local development

```bash
bash_set_mode full
```

## Mode Management

```bash
# Toggle between modes
bash_toggle_mode

# Set specific mode
bash_set_mode fastest|balanced|full

# Check current mode
echo $BASH_MODE

# Quick mode switches
bash_fast    # Switch to fastest mode
bash_full    # Switch to full mode
bash_reload  # Reload current configuration
```

## File Structure

```
bash/
├── bashrc_manager.sh  # Main entry point (sourced by ~/.bashrc)
├── bashrc.sh         # Core configuration with performance modes
├── aliases.sh        # All bash aliases
├── functions.sh      # Bash functions (ported from zsh)
├── keybindings.sh    # Keyboard shortcuts and bindings
└── README.md         # This file
```

## Key Features

### 🎯 **Smart Aliases**

- Editor shortcuts (`vi` → `nvim`)
- Git shortcuts (`gg` → `git status`)
- Docker shortcuts (`dki`, `dk`)
- Python/Jupyter shortcuts
- Development tools

### 🔧 **Powerful Functions**

- `c()` - Smart cd with ls
- `tm()` - Tmux session manager with fzf
- `fh()` - FZF history search
- `fif()` - Find in files with grep + fzf
- `fd()` - Directory finder
- `fkill()` - Process killer with fzf
- Virtual environment management
- Git utilities
- Docker helpers

### ⌨️ **Enhanced Keybindings**

- **Ctrl+R**: FZF history search
- **Ctrl+T**: File/directory finder
- **Alt+C**: Change directory with fzf
- **Ctrl+G**: Find in files
- **Alt+U**: Go up one directory
- **Alt+H**: Go to home directory
- **Alt+G**: Git status
- **Alt+T**: Tmux session selector

### 🐍 **Python Integration**

- Virtual environment auto-activation
- IPython configuration
- Jupyter shortcuts
- Python tools integration

### 🌟 **Git Integration**

- Branch display in prompt
- Git status indicators
- Enhanced git shortcuts
- Git completion

## Performance Features

- **Lazy Loading**: Heavy features load only when needed
- **Optimized Completion**: Intelligent completion caching
- **Fast History**: Optimized history search and management
- **Minimal Startup**: Sub-100ms startup time in fastest mode
- **Smart PATH**: Efficient PATH management

## Environment Variables

- `BASH_MODE`: Current performance mode (fastest/balanced/full)
- `VENV_AUTO_CHDIR`: Auto-activate virtualenvs on cd (on/off)
- `VENV_AUTO_ACTIVATE`: Auto-activate on login (on/off)

## Customization

### Adding Custom Aliases

```bash
# Add to ~/.env or directly to aliases.sh
set_alias myalias "my command"
```

### Environment Variables

```bash
# Manage environment variables
set_env MYVAR "value"
unset_env MYVAR
```

### Virtual Environment Settings

```bash
# Configure auto-activation
ve_auto_chdir on|off    # Auto-activate on directory change
ve_auto_login on|off    # Auto-activate on login
```

## Compatibility

- **Bash 4.0+**: Full feature support
- **Bash 3.x**: Core features supported
- **macOS**: Full support with Homebrew integration
- **Linux**: Full support with package manager integration
- **WSL**: Tested and supported

## Dependencies

### Required

- `bash` (obviously)
- `git`
- `curl`

### Optional (enhances functionality)

- `fzf` - Fuzzy finder integration
- `rg` (ripgrep) - Fast file searching
- `tmux` - Terminal multiplexer integration
- `nvim`/`vim` - Editor integration
- `docker` - Docker shortcuts
- `python3` - Python tools

## Migration from Zsh/Fish

This bash configuration provides similar functionality to the zsh and fish configurations in this dotfiles repository:

- **Functions**: Most zsh functions ported to bash
- **Aliases**: Direct port with bash-compatible syntax
- **Performance**: Similar multi-mode system
- **Integrations**: Same tool integrations (fzf, git, tmux, etc.)

## Troubleshooting

### Slow Startup

```bash
# Switch to faster mode
bash_set_mode fastest

# Check what's loading slowly
bash_bench
```

### Completion Issues

```bash
# Reload bash completion
bash_reload

# Check completion setup
type _completion_loader
```

### FZF Not Working

```bash
# Install FZF
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

## Contributing

When adding new features:

1. **Respect performance modes**: Add expensive features only in full mode
2. **Test compatibility**: Ensure bash 3.x and 4.x support
3. **Update documentation**: Keep this README current
4. **Follow patterns**: Use existing code style and structure

## Performance Benchmarks

Typical startup times:

- **Fastest Mode**: 20-50ms
- **Balanced Mode**: 50-150ms
- **Full Mode**: 100-300ms

_Times may vary based on system and installed tools._
