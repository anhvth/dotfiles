# Custom-Tools Folder Agents Guide

## Architecture Overview

Directory containing custom Python-based tools and utilities for development workflow enhancement.

Main subdirectories: `pytools/` - unified CLI toolset with plugin registry architecture.

Data flow: Tools registered in central registry, executed via CLI dispatcher with session logging.

## Developer Workflows

- **PyTools usage**: Install with `pip install -e pytools/`, run `pytools` for interactive mode or `pytools run <tool>`
- **Tool development**: Add new tools in pytools/src/pytools/, register in cli.py
- **Testing**: `pytest pytools/tests/` with coverage reporting

## Conventions & Patterns

- **Tool naming**: Kebab-case for CLI, snake_case for modules
- **Safety levels**: Tools tagged safe/write/destructive/interactive
- **Entry points**: All tools have main() function using sys.argv

## Integration Points

- **External tools**: fzf for selection, tmux for parallel execution, wget for downloads
- **VS Code**: pyinit generates .vscode/settings.json
- **Hugging Face/SSH**: Specialized tools for downloads and connections