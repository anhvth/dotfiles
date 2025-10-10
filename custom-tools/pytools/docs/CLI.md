# PyTools CLI Reference

This document provides a complete reference for all PyTools commands.

Generated from the tool registry.


**Total Tools:** 14


## Tools by Category

- **config**: env-set, env-unset, env-list, setup-typing
- **dev**: cat-projects, pyinit, report-error, setup-typing
- **download**: hf-down
- **env**: env-set, env-unset, env-list
- **fs**: organize-downloads
- **fzf**: atv-select, kill-process-grep
- **network**: hf-down, keep-ssh, print-ipv4
- **parallel**: lsh
- **scaffold**: pyinit
- **snapshot**: cat-projects
- **ssh**: keep-ssh
- **system**: kill-process-grep, lsh, organize-downloads
- **tmux**: lsh
- **typing**: report-error, setup-typing
- **venv**: atv-select

## All Tools


### `atv-select`

**Summary:** Select and activate a venv from history (fzf)


**Usage:**
```bash
atv-select [--help-venv]
```


**Safety:** `interactive`


**Tags:** fzf, venv


**Examples:**
```bash
pytools run atv-select
```


---


### `cat-projects`

**Summary:** Create code snapshots for LLMs


**Usage:**
```bash
cat-projects <paths...> [--extensions .py,.js] [--summarize]
```


**Safety:** `safe`


**Tags:** dev, snapshot


**Examples:**
```bash
# Snapshot Python project
pytools run cat-projects src/ --extensions .py

# With AI summarization
pytools run cat-projects . --summarize
```


---


### `hf-down`

**Summary:** Download files from Hugging Face (url transform included)


**Usage:**
```bash
hf-down <URL> [SAVE_NAME]
```


**Safety:** `write`


**Tags:** download, network


**Examples:**
```bash
pytools run hf-down https://huggingface.co/username/model/resolve/main/file.bin
```


---


### `keep-ssh`

**Summary:** Keep SSH connections alive


**Usage:**
```bash
keep-ssh user@host [--interval 60] [--verbose]
```


**Safety:** `interactive`


**Tags:** network, ssh


**Examples:**
```bash
# Keep connection alive
pytools run keep-ssh user@server

# Custom interval
pytools run keep-ssh user@server --interval 30 --verbose
```


---


### `kill-process-grep`

**Summary:** Interactive process killer with fzf


**Usage:**
```bash
kill-process-grep
```


**Safety:** `interactive`


**Tags:** fzf, system


**Examples:**
```bash
pytools run kill-process-grep
```


---


### `lsh`

**Summary:** List Shell (lsh) runs command lists in parallel inside tmux with CPU/GPU pinning


**Usage:**
```bash
lsh COMMANDS_FILE WORKERS [--session-name NAME] [--gpus 0,1] [--cpu-per-worker N] [--dry-run]
```


**Safety:** `interactive`


**Tags:** parallel, system, tmux


**Examples:**
```bash
# Create commands file
echo 'python train.py --seed 1' > cmds.txt
echo 'python train.py --seed 2' >> cmds.txt

# Run in parallel with explicit session name
pytools run lsh cmds.txt 2 --session-name training --gpus 0,1

# Preview tmux command layout without launching
pytools run lsh cmds.txt 2 --dry-run
```


---


### `organize-downloads`

**Summary:** Organize Downloads by creation date (moves files)


**Usage:**
```bash
organize-downloads [~/Downloads]
```


**Safety:** `destructive`


**Tags:** fs, system


**Examples:**
```bash
# Preview organization
pytools run organize-downloads --dry-run

# Organize by modified date
pytools run organize-downloads --by modified --yes

# Organize only PDFs
pytools run organize-downloads --pattern '*.pdf'
```


---


### `print-ipv4`

**Summary:** Display public IPv4 address


**Usage:**
```bash
print-ipv4
```


**Safety:** `safe`


**Tags:** network


**Examples:**
```bash
pytools run print-ipv4
```


---


### `pyinit`

**Summary:** Initialize a Python project with VSCode settings


**Usage:**
```bash
pyinit <name> [--venv]
```


**Safety:** `write`


**Tags:** dev, scaffold


**Examples:**
```bash
# Create a new project
pytools run pyinit my-project

# With virtual environment
pytools run pyinit my-project --venv
```


---


### `report-error`

**Summary:** Report Pylance/Pyright errors to JSON file


**Usage:**
```bash
report-error <file_path> [--output-file FILE] [--json-format] [--verbose]
```


**Safety:** `write`


**Tags:** dev, typing


**Examples:**
```bash
pytools run report-error src/main.py --output-file errors.json
```


---


### `env-set`

**Summary:** Set a KEY=VALUE entry in ~/.env


**Usage:**
```bash
env-set KEY VALUE
```


**Safety:** `write`


**Tags:** config, env


**Examples:**
```bash
pytools run env-set API_TOKEN secret
```


---


### `env-unset`

**Summary:** Remove a KEY from ~/.env


**Usage:**
```bash
env-unset KEY
```


**Safety:** `write`


**Tags:** config, env


**Examples:**
```bash
pytools run env-unset API_TOKEN
```


---


### `env-list`

**Summary:** List all variables stored in ~/.env


**Usage:**
```bash
env-list
```


**Safety:** `safe`


**Tags:** config, env


**Examples:**
```bash
pytools run env-list
```


---


### `setup-typing`

**Summary:** Configure typing and linting for a Python project


**Usage:**
```bash
setup-typing [--python-version 3.11] [--type-checking-mode basic]
```


**Safety:** `write`


**Tags:** config, dev, typing


**Examples:**
```bash
# Setup with defaults
pytools run setup-typing

# Custom Python version
pytools run setup-typing --python-version 3.11 --type-checking-mode strict
```


---
