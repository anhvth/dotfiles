# PyTools Src Agents Guide

## Architecture Overview

Source code organized as a Python package with core infrastructure in `core/` and tool implementations as modules. CLI acts as dispatcher using registry pattern to map tool names to module main functions. Tools follow adapter pattern wrapping existing scripts with metadata.

Main modules: `cli.py` (dispatcher), `core/registry.py` (tool metadata), `core/session.py` (logging), individual tool modules (e.g., `cat_projects.py`).

Data flow: CLI parses args → registry lookup → tool runner executes module.main() → session logs result.

## Developer Workflows

- **Adding tools**: Create module in `src/pytools/` with `main()` function, register in `cli.py::build_registry()` with Tool metadata
- **Testing tools**: Run via `pytools run <tool>` during development, verify in interactive mode
- **Registry updates**: Modify `build_registry()` to add/remove tools, update metadata (usage, tags, safety)
- **Session debugging**: Check `~/.config/pytools/sessions/` JSONL files for execution logs

## Conventions & Patterns

- **Module structure**: Each tool is a separate module with `main()` entry point using `sys.argv`
- **Registry registration**: Tools defined with name (kebab-case), summary, runner lambda, usage string, tags list, safety level
- **Safety levels**: "safe" (read-only), "write" (creates files), "destructive" (moves/deletes), "interactive" (user input)
- **Passthrough mode**: Interactive tools set `passthrough=True` to avoid output capture
- **Import pattern**: Tools imported lazily in `build_registry()` to avoid loading all modules at startup

## Integration Points

- **Rich library**: Used in `cli.py` for table rendering and panel output
- **Prompt toolkit**: Powers interactive mode with completion and history
- **Loguru**: Implicit logging in session module (not directly used in CLI)
- **External executables**: Tools like `lsh` depend on `tmux`, `kill-process-grep` on `fzf`
