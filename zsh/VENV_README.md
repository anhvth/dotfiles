# Virtual Environment Management - Unified System

## Overview

All Python virtual environment functions have been unified into a single file: `zsh/venv.sh`

This eliminates the previous duplication and conflicts between:
- `atv()` system in functions.sh  
- `auto_activate_uv()` in zshrc.sh
- `uv_venv()` in alias.sh

## Key Features

✅ **Single Responsibility** - Each function does one job  
✅ **Help System** - Every function supports `--help`  
✅ **Short Aliases** - Convenient shortcuts  
✅ **History Tracking** - Remembers used environments  
✅ **Auto-Detection** - Smart environment detection  
✅ **UV Integration** - First-class UV support  

## Quick Reference

### Core Commands
```bash
va [path]              # Activate virtualenv (venv-activate)
vd                     # Deactivate current env (venv-deactivate)  
vc [path] [packages]   # Create UV env with packages (venv-create)
vs                     # Select from history (venv-select)
```

### Management
```bash
venv-auto [on|off]     # Control auto-activation
vl                     # List environment history (venv-list)
venv-detect            # Auto-detect environment in current dir
vh                     # Show help (venv-help)
```

### Help System
```bash
vh                     # Show all commands
va --help              # Help for specific command
vc --help              # Help for create command
```

## Examples

```bash
# Create new environment with packages
vc myproject numpy pandas matplotlib

# Activate existing environment  
va .venv
va /path/to/myenv

# Select from history using fzf
vs

# Enable auto-activation on shell startup
venv-auto on

# List all environments from history
vl

# Get help for any command
vc --help
```

## Migration from Old System

### Old Functions → New Functions
- `atv()` → `va` / `venv-activate`
- `atv_select()` → `vs` / `venv-select`  
- `auto_atv_disable()` → `vd && venv-auto off`
- `ve_auto_login()` → `venv-auto`
- `uv_venv()` → `vc` / `venv-create`
- `auto_activate_uv()` → `venv-detect`

### Legacy Compatibility
The old function names are aliased for backward compatibility but will be removed in a future update.

## Implementation Details

### File Structure
- **Main file**: `zsh/venv.sh` - Contains all venv functions
- **Sourced from**: `zsh/zshrc.sh` - Automatically loaded
- **History file**: `~/.cache/dotfiles/venv_history` - Tracks used environments

### Auto-Activation
- **Environment variables**: 
  - `VENV_AUTO_ACTIVATE` - on/off flag
  - `VENV_AUTO_ACTIVATE_PATH` - path to activate script
- **Startup function**: `_venv_auto_startup()` - Called from zshrc
- **Control**: `venv-auto on|off|status`

### Detection Priority
1. UV projects (pyproject.toml, uv.lock)
2. Standard .venv directory  
3. Other common names (venv, env, .env)

## Benefits

1. **No More Conflicts** - Single source of truth
2. **Better UX** - Consistent help system and error messages
3. **Maintainable** - All related code in one place
4. **Extensible** - Easy to add new features
5. **Performance** - No duplicate function loading