# PyTools Project Agents Guide

## Architecture Overview

PyTools is a unified CLI toolset built around a plugin registry architecture. The core consists of:

- **Registry system** (`src/pytools/core/registry.py`): Declarative tool metadata with safety levels, tags, and execution runners
- **CLI dispatcher** (`src/pytools/cli.py`): Single entry point handling interactive mode, direct execution, and tool discovery
- **Session logging** (`src/pytools/core/session.py`): JSONL-based audit trail stored in `~/.config/pytools/sessions/`
- **Tool modules**: Individual utilities in `src/pytools/` following a `main()` function pattern

Data flow: CLI → Registry lookup → Tool runner → Session log. Tools are categorized by safety (safe/write/destructive/interactive) and tagged for discovery.

## Developer Workflows

- **Installation**: `uv pip install -e .` (preferred) or `pip install -e .`
- **Interactive development**: `pytools` launches prompt_toolkit-based shell with fuzzy matching and tab completion
- **Direct execution**: `pytools run <tool> [args]` for scripting
- **Testing**: `pytest tests/ -v` with coverage via `pytest tests/ --cov=src/pytools --cov-report=term-missing`
- **Tool addition**: Register new tools in `cli.py::build_registry()` with Tool dataclass metadata

## Conventions & Patterns

- **Tool naming**: Kebab-case for CLI (e.g., `cat-projects`), snake_case for modules (e.g., `cat_projects.py`)
- **Entry points**: All tools expose a `main()` function taking no args, using `sys.argv` directly
- **Safety tagging**: Tools marked "destructive" (e.g., `organize-downloads`) require caution; "interactive" tools (e.g., `kill-process-grep`) use passthrough mode
- **Import style**: Relative imports within pytools package; external deps like `rich` for UI, `loguru` for logging
- **Error handling**: Tools return exit codes; CLI captures stdout/stderr for non-interactive tools

## Integration Points

- **External tools**: `fzf` for fuzzy selection, `tmux` for parallel execution, `wget` for downloads
- **VS Code**: `pyinit` generates `.vscode/settings.json` with Python interpreter paths
- **Hugging Face**: `hf-down` transforms URLs and uses `wget` for downloads
- **SSH**: `keep-ssh` maintains connections with configurable intervals
