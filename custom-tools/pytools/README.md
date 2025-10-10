# PyTools

A modern, unified CLI for development utilities and dotfiles management. One command to rule them all! 🚀

## Quick Start

```bash
# Install
cd /path/to/dotfiles/custom-tools/pytools
uv pip install -e .

# Try it out
pytools              # Interactive mode
pytools list         # Show all tools
pytools doctor       # Check dependencies
pytools run <tool>   # Run a specific tool
pytools-mcp          # Launch MCP server over stdio
```

📚 **[Read the Quickstart Guide](docs/quickstart.md)** for a complete walkthrough!

## What's New in v0.3.0

✨ **Enhanced Safety**: Dry-run and confirmation prompts for destructive operations  
🔧 **Dependency Doctor**: Check system dependencies with remediation guidance  
⚙️ **Configuration System**: Centralized config in `~/.config/pytools/`  
🎯 **More Tools**: Added `report-error`, `setup-typing`, and the `env-*` suite  
📊 **Better organize-downloads**: Preview, filters, and flexible sorting options  
🧪 **Test Suite**: 18 passing tests covering core functionality  
🧩 **MCP Server**: `pytools-mcp` exposes safe tools via the Model Context Protocol  
📖 **Complete Docs**: Quickstart guide and auto-generated CLI reference

## Installation

### Using uv (Recommended)

```bash
cd /path/to/dotfiles/custom-tools/pytools

# Install globally (requires sudo)
sudo $(which uv) pip install --system .

# Or install for current user
uv pip install -e .
```

### Using pip

```bash
cd /path/to/dotfiles/custom-tools/pytools
pip install -e .
```

## Usage

### Interactive Mode (Recommended)

The easiest way to use PyTools is through the interactive mode:

```bash
pytools
```

This opens a friendly prompt where you can:

- Type `list` to see all available tools
- Type `doctor` to check system dependencies
- Type `help <tool>` to get help for a specific tool
- Run any tool directly by name
- Get fuzzy match suggestions for typos
- Use tab completion

### Direct Mode

Run tools directly without the interactive prompt:

```bash
pytools --version               # Show version
pytools --json list             # JSON output
pytools --no-color list         # Plain text output
pytools doctor                  # Check dependencies
pytools run print-ipv4          # Get your public IP
pytools run cat-projects ./src  # Create code snapshot
```

### MCP Server

PyTools ships with an experimental [Model Context Protocol](https://modelcontextprotocol.io) server that makes a subset of safe tools available to MCP-compatible assistants (such as Claude Desktop).

```bash
pytools-mcp                 # Start the server (stdio transport)
pytools-mcp --session-id mcp-demo  # Custom session log identifier
```

The server:

- Lists only non-destructive, non-interactive tools
- Captures command stdout/stderr and returns them to the client
- Logs invocations to the standard PyTools session log directory

Configure your MCP client to launch `pytools-mcp` and it will negotiate the protocol automatically.

## Available Tools

PyTools includes 14 utilities organized by category:

### Development Tools

- **cat-projects** - Create code snapshots for LLMs
- **pyinit** - Initialize Python projects with VSCode settings
- **setup-typing** - Configure typing and linting for Python projects
- **report-error** - Report Pylance/Pyright errors to JSON

### System Utilities

- **lsh** - List Shell runs command files in parallel inside tmux with CPU/GPU pinning
- **kill-process-grep** - Interactive process killer using fzf
- **organize-downloads** - Organize downloads folder by date (with dry-run, filters, preview)

### Network Tools

- **print-ipv4** - Display public IPv4 address
- **hf-down** - Download files from Hugging Face Hub
- **keep-ssh** - Keep SSH connections alive

### Configuration Tools

- **env-set** - Write KEY=VALUE entries to ~/.env
- **env-unset** - Remove a KEY from ~/.env
- **env-list** - Show current ~/.env entries
- **atv-select** - Select and activate virtualenv from history

## Examples

```bash
# Interactive exploration
$ pytools
pytools> list                    # See all tools
pytools> doctor                  # Check dependencies
pytools> help organize-downloads # Get detailed help
pytools> organize-downloads --dry-run  # Preview what would happen
pytools> exit

# Direct execution with safety
$ pytools run organize-downloads --dry-run    # Preview organization
$ pytools run organize-downloads --yes        # Organize with confirmation skipped
$ pytools run organize-downloads --pattern "*.pdf"  # Only PDFs

# Development workflow
$ pytools run setup-typing --python-version 3.11
$ pytools run report-error src/main.py --output-file errors.json
$ pytools run cat-projects ./src --extensions .py > snapshot.txt

# Configuration management
$ pytools run env-set API_KEY mykey123
$ pytools run env-list
$ pytools run env-unset API_KEY
```

## Global Flags

- `--version` - Show PyTools version
- `--no-color` - Disable colored output (for scripting)
- `--json` - Output in JSON format where applicable (for `list` command)

## Documentation

- **[Quickstart Guide](docs/quickstart.md)** - Complete walkthrough for new users
- **[CLI Reference](docs/CLI.md)** - Detailed documentation for all tools
- **[MCP Server Guide](docs/mcp_server.md)** - Launch and test the MCP integration
- **[Modernization Plan](plans/00_mordernize.md)** - Architecture and roadmap

## Development

### Running Tests

```bash
# Install dev dependencies
uv pip install -e ".[dev]"

# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=src/pytools --cov-report=term-missing
```

### Test Coverage

- **18 tests** covering registry, CLI, MCP integration, and session logging
- Tests validate: tool registration, CLI flags, JSON output, session logging

## Dependencies

Core dependencies:

- `loguru` - Enhanced logging
- `rich` - Beautiful terminal output
- `prompt_toolkit` - Interactive prompts and completion
- `typer` - CLI framework for some tools

External tools (optional, checked by `pytools doctor`):

- `fzf` - For `kill-process-grep` and `atv-select`
- `tmux` - For `lsh`
- `wget` - For `hf-down`
- `pyright` - For `report-error`

## Configuration

PyTools stores configuration in `~/.config/pytools/`:

- `config.toml` - User configuration (optional)
- `sessions/` - Session logs for audit trail
- `venv_history` - Virtual environment activation history

Set `PYTOOLS_CONFIG_DIR` to override the config directory.

## Safety Levels

Tools are classified by safety:

- **safe** - Read-only operations (e.g., `print-ipv4`, `cat-projects`)
- **write** - Create/modify files (e.g., `pyinit`, `setup-typing`)
- **destructive** - Move/delete operations (e.g., `organize-downloads`)
- **interactive** - Require user interaction (e.g., `kill-process-grep`, `lsh`)

Destructive tools support:

- `--dry-run` - Preview changes without making them
- `--yes` / `-y` - Skip confirmation prompts
- Preview tables showing what will change

## License

MIT

## Contributing

Contributions welcome! Please:

1. Follow the modernization plan in `plans/00_mordernize.md`
2. Add tests for new features
3. Update documentation
4. Keep the single entry point philosophy
5. Use `--dry-run` for destructive operations
