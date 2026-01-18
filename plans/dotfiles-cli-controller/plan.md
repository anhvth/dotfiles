# Dotfiles CLI Controller

**Branch:** `feature/dotfiles-cli-controller`
**Description:** Add a unified `dotfiles` command to manage dotfiles configuration settings via CLI

## Goal
Create a `dotfiles` CLI tool that provides a consistent interface for managing dotfiles configuration settings, starting with venv auto-reload control. This tool will integrate with the existing pytools infrastructure and follow established patterns in the repository for configuration management.

## Implementation Steps

### Step 1: Create Python CLI Module
**Files:** 
- `custom-tools/pytools/src/pytools/dotfiles_commands.py` (new)
- `custom-tools/pytools/tests/test_dotfiles_commands.py` (new)

**What:** 
Create a new Python module implementing the `dotfiles` command with venv management subcommands. The module will:
- Support `dotfiles --help` to show usage information
- Implement `dotfiles venv {enable_reload|disable_reload|status}` to manage VENV_AUTO_ACTIVATE setting
- Use existing `set_env`/`unset_env` patterns from env_commands.py
- Provide emoji-based visual feedback (✅, 🔧, ❌)
- Follow the Tool pattern with proper safety tagging

**Testing:** 
- Run `pytools run dotfiles --help` to verify help output
- Test `pytools run dotfiles venv status` to check current status
- Test `pytools run dotfiles venv enable_reload` and verify `~/.env` contains `VENV_AUTO_ACTIVATE=on`
- Test `pytools run dotfiles venv disable_reload` and verify `~/.env` contains `VENV_AUTO_ACTIVATE=off`
- Run unit tests: `cd custom-tools/pytools && python -m pytest tests/test_dotfiles_commands.py -v`

### Step 2: Register in CLI
**Files:**
- `custom-tools/pytools/src/pytools/cli.py`

**What:**
Register the new `dotfiles` command in the pytools CLI registry. Add it to the `build_registry()` function following the pattern used for other commands like `env-set`, `env-unset`, etc. Tag it with appropriate categories ("config", "dotfiles") and safety level ("write").

**Testing:**
- Run `pytools --help` and verify `dotfiles` appears in the command list
- Run `pytools list` and verify `dotfiles` is registered
- Test the command via pytools: `pytools run dotfiles venv status`

### Step 3: Add Zsh Alias for Convenience
**Files:**
- `zsh/alias.sh`

**What:**
Add a simple zsh alias to make `dotfiles` directly accessible from the shell without needing `pytools run` prefix. This provides convenience while keeping the main implementation in Python.

```bash
alias dotfiles='pytools run dotfiles'
```

**Testing:**
- Source the updated alias file: `source ~/.zshrc` or `zsh_reload`
- Run `dotfiles --help` (without pytools prefix)
- Run `dotfiles venv status` and verify it works
- Run `dotfiles venv enable_reload` and check it modifies `~/.env`

### Step 4: Update Documentation
**Files:**
- `custom-tools/pytools/README.md`
- `custom-tools/pytools/docs/CLI.md` (if exists)

**What:**
Document the new `dotfiles` command in the pytools README. Add usage examples and explain the available subcommands. Include it in the list of configuration management tools alongside `env-set`, `env-unset`, etc.

**Testing:**
- Read the documentation and verify it's clear and complete
- Follow the examples in the docs to ensure they work as described

## Future Extensibility

The `dotfiles` command is designed to be extensible. Future enhancements could include:
- `dotfiles tmux <setting>` - Manage tmux configuration
- `dotfiles vim <setting>` - Manage vim/neovim settings  
- `dotfiles git <setting>` - Manage git configuration
- `dotfiles list` - List all managed settings
- `dotfiles export` - Export current configuration
- `dotfiles import <file>` - Import configuration from file

## Notes

- Follow existing patterns in `env_commands.py` for file manipulation
- Use emoji feedback consistently: ✅ success, 🔧 status, ❌ error
- Tag the tool as `safety="write"` since it modifies `~/.env`
- Keep the implementation simple and focused on configuration management
- The hybrid approach (Python + zsh alias) provides best usability
