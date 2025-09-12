# PyTools

A collection of Python utility scripts for dotfiles management and development workflows.

## Installation

Install using uv (recommended):

```bash
cd /path/to/dotfiles/custom-tools/pytools
uv pip install -e .
```

Or using pip:

```bash
cd /path/to/dotfiles/custom-tools/pytools
pip install -e .
```

## Available Tools

After installation, the following commands will be available as system binaries:

### System Utilities

- **lsh** - Execute commands in parallel using tmux with CPU/GPU assignment

  ```bash
  lsh commands.txt 4 --name my-session --gpus 0,1,2,3
  ```

- **kill-process-grep** - Interactive process killer using fzf

  ```bash
  kill-process-grep
  ```

- **print-ipv4** - Display public IPv4 address

  ```bash
  print-ipv4
  ```

- **organize-downloads** - Organize downloads folder by creation date
  ```bash
  organize-downloads [~/Downloads]
  ```

### Development Tools

- **cat-projects** - Create code snapshots for LLMs

  ```bash
  cat-projects ./src -e .py,.js --summarise > snapshot.txt
  ```

- **hf-down** - Download files from Hugging Face Hub

  ```bash
  hf-down https://huggingface.co/model/file.bin [output-name]
  ```

- **pyinit** - Initialize Python projects

  ```bash
  pyinit my-project --venv
  ```

- **keep-ssh** - Keep SSH connections alive
  ```bash
  keep-ssh user@host --interval 60
  ```

## Dependencies

- `loguru` - For enhanced logging
- `fzf` - Required for `kill-process-grep`
- `wget` - Required for `hf-down`
- `tmux` - Required for `lsh`

## Migration from Old Scripts

This package replaces the individual Python scripts that were previously accessed via fish aliases:

- `pytools-lsh.py` → `lsh`
- `pytools-hf-down.py` → `hf-down`
- `pytools-kill_process_grep.py` → `kill-process-grep`
- `pytools-print-ipv4.py` → `print-ipv4`
- `pytools-cat_projects.py` → `cat-projects`
- `organize_download.py` → `organize-downloads`
- `pyinit.py` → `pyinit`
- `keep_ssh.py` → `keep-ssh`
