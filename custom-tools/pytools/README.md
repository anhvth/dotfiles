# PyTools

A modern, unified CLI for development utilities and dotfiles management. One command to rule them all! ????

## Quick Start

```bash
# Install
cd /path/to/dotfiles/custom-tools/pytools
uv pip install -e .

# Try it out
pytools              # Interactive mode
pytools list         # Show all tools
pytools run <tool>   # Run a specific tool
```

???? **[Read the Quickstart Guide](docs/quickstart.md)** for a complete walkthrough!

## What's New in v0.2.0

??? **Single Entry Point**: All tools accessible via one `pytools` command  
???? **Interactive Mode**: Fuzzy search, tab completion, and contextual help  
???? **Modern UX**: Rich terminal output with colors and formatting  
???? **Test Coverage**: 43 tests with 79% coverage on core CLI  
???? **Better Docs**: Comprehensive quickstart guide and examples

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

- Type \`list\` to see all available tools
- Type \`help <tool>\` to get help for a specific tool
- Run any tool directly by name
- Get fuzzy match suggestions for typos
- Use tab completion

### Direct Mode

Run tools directly without the interactive prompt:

```bash
pytools list                    # Show all tools
pytools run print-ipv4          # Get your public IP
pytools run cat-projects ./src  # Create code snapshot
```

## Available Tools

PyTools includes 10+ utilities organized by category:

### System Utilities

- **lsh** - Execute commands in parallel using tmux with CPU/GPU assignment
- **kill-process-grep** - Interactive process killer using fzf
- **print-ipv4** - Display public IPv4 address
- **organize-downloads** - Organize downloads folder by creation date

### Development Tools

- **cat-projects** - Create code snapshots for LLMs
- **hf-down** - Download files from Hugging Face Hub
- **pyinit** - Initialize Python projects with VSCode settings
- **atv-select** - Select and activate virtualenv

### Network Tools

- **keep-ssh** - Keep SSH connections alive
- **print-ipv4** - Show public IP address

## Examples

```bash
# Interactive exploration
$ pytools
pytools> list              # See all tools
pytools> help cat-projects # Get help
pytools> cat-projects ./src -e .py,.md  # Run it
pytools> exit

# Direct execution
$ pytools run cat-projects ./src -e .py > snapshot.txt
$ pytools run print-ipv4
$ pytools run hf-down https://huggingface.co/model/file.bin
```

## Creating Aliases (Optional)

If you prefer the old-style individual commands, create aliases:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias lsh='pytools run lsh'
alias cat-projects='pytools run cat-projects'
alias hf-down='pytools run hf-down'
```

## Documentation

- **[Quickstart Guide](docs/quickstart.md)** - Complete walkthrough for new users
- **[Modern CLI Plan](docs/modern_cli_plan.md)** - Architecture and roadmap

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

- **43 tests** covering registry, runner, and interactive mode
- **79% coverage** on core CLI module
- **100% coverage** on registry module
- **97% coverage** on session logger

## Dependencies

- \`loguru\` - Enhanced logging
- \`rich\` - Beautiful terminal output
- \`prompt_toolkit\` - Interactive prompts and completion

Some tools require external utilities:

- \`fzf\` - For \`kill-process-grep\` and \`atv-select\`
- \`tmux\` - For \`lsh\`
- \`wget\` - For \`hf-down\`

## Migration from v0.1.x

Previously, each tool had its own command. Now they're all unified:

**Before:**

```bash
lsh commands.txt 4
cat-projects ./src
hf-down <url>
```

**After (both work):**

```bash
# Option 1: Interactive
pytools
pytools> lsh commands.txt 4

# Option 2: Direct
pytools run lsh commands.txt 4
pytools run cat-projects ./src
pytools run hf-down <url>
```

The old individual commands are **removed** to simplify installation and reduce CLI clutter.

## License

MIT

## Contributing

Contributions welcome! Please:

1. Follow TDD (test-driven development)
2. Add tests for new features
3. Update documentation
4. Keep the single entry point philosophy
