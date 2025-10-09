# PyTools Quickstart Guide

PyTools is a unified CLI toolset for managing Python development workflows, system utilities, and automation tasks.

## Installation

### From Source (Development)

```bash
cd /path/to/pytools
uv pip install -e .
# or
pip install -e .
```

### Verify Installation

```bash
pytools --version
pytools doctor  # Check dependencies
```

## Basic Usage

### Interactive Mode

Run `pytools` without arguments to enter interactive mode:

```bash
pytools
```

In interactive mode:

- `list` - Show all available tools
- `doctor` - Check system dependencies
- `help <tool>` - Get help for a specific tool
- `<tool> [args]` - Run a tool directly
- `exit` or `quit` - Exit interactive mode

### Direct Execution

Run tools directly without entering interactive mode:

```bash
pytools run <tool-name> [args...]
```

### List All Tools

```bash
pytools list              # Pretty table output
pytools --json list       # JSON output for scripting
```

## Common Tools

### Development Tools

**cat-projects** - Create code snapshots for LLMs

```bash
pytools run cat-projects src/ -e .py,.js --summarise
```

**pyinit** - Initialize a Python project with VSCode settings

```bash
pytools run pyinit my-project --venv
```

**setup-typing** - Configure typing and linting

```bash
pytools run setup-typing --python-version 3.11
```

**report-error** - Report Pylance/Pyright errors

```bash
pytools run report-error src/main.py --output-file errors.json
```

### System Utilities

**organize-downloads** - Organize Downloads folder by date

```bash
# Preview what would be organized
pytools run organize-downloads --dry-run

# Organize with confirmation
pytools run organize-downloads

# Organize without confirmation, by modified date
pytools run organize-downloads --yes --by modified

# Organize only PDFs
pytools run organize-downloads --pattern "*.pdf"
```

**kill-process-grep** - Interactive process killer with fzf

```bash
pytools run kill-process-grep
```

**lsh** - Execute commands in parallel with tmux

```bash
# Create a commands file
echo "python train.py --config config1.yaml" > commands.txt
echo "python train.py --config config2.yaml" >> commands.txt

# Run in parallel
pytools run lsh commands.txt 2 --gpus 0,1
```

### Network Tools

**print-ipv4** - Display public IPv4 address

```bash
pytools run print-ipv4
```

**hf-down** - Download files from Hugging Face

```bash
pytools run hf-down https://huggingface.co/model/file
```

**keep-ssh** - Keep SSH connections alive

```bash
pytools run keep-ssh user@server --interval 30
```

### Configuration Tools

**set-env** - Manage environment variables in ~/.env

```bash
pytools run set-env set API_KEY mykey123
pytools run set-env list
pytools run set-env unset API_KEY
```

**atv-select** - Select and activate virtual environments

```bash
pytools run atv-select
```

## Global Flags

- `--version` - Show version
- `--no-color` - Disable colored output
- `--json` - Output in JSON format (where applicable)

## Configuration

PyTools stores configuration in `~/.config/pytools/`:

- `config.toml` - User configuration (optional)
- `sessions/` - Session logs for audit trail
- `venv_history` - Virtual environment activation history

### Environment Variables

- `PYTOOLS_CONFIG_DIR` - Override config directory (default: `~/.config/pytools`)

## Dependency Check

Check which external tools are available:

```bash
pytools doctor
```

Required dependencies for specific tools:

- **fzf** - kill-process-grep, atv-select
- **tmux** - lsh
- **wget** - hf-down
- **pyright** - report-error

## Safety Levels

Tools are classified by safety:

- **safe** - Read-only operations (e.g., print-ipv4, cat-projects)
- **write** - Create/modify files (e.g., pyinit, setup-typing)
- **destructive** - Move/delete operations (e.g., organize-downloads)
- **interactive** - Require user interaction (e.g., kill-process-grep, lsh)

Destructive tools support `--dry-run` to preview changes.

## Tips

1. **Tab completion** - In interactive mode, use tab completion for tool names
2. **Fuzzy matching** - Tool names are fuzzy-matched in interactive mode
3. **Session logs** - All tool executions are logged to `~/.config/pytools/sessions/`
4. **Help anywhere** - Use `--help` with any tool to see detailed options

## Troubleshooting

### Tool not found

```bash
pytools list  # Check available tools
pytools doctor  # Check dependencies
```

### Permission errors

Ensure files/directories are writable, especially for destructive operations.

### Import errors

Reinstall in editable mode:

```bash
pip install -e .
```

## Next Steps

- Check [CLI.md](CLI.md) for complete tool reference
- Run `pytools doctor` to verify your setup
- Try interactive mode: `pytools`
- Explore tools with `pytools list`
