# PyTools CLI Reference

This document provides a complete reference for all PyTools commands.

Generated from the tool registry.


**Total Tools:** 12


## Tools by Category

- **config**: set-env, setup-typing
- **dev**: cat-projects, pyinit, report-error, setup-typing
- **download**: hf-down
- **env**: set-env
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
cat-projects <paths...> [-e .py,.js] [--summarise]
```


**Safety:** `safe`


**Tags:** dev, snapshot


**Examples:**
```bash
# Snapshot Python project
pytools run cat-projects src/ -e .py

# With AI summarization
pytools run cat-projects . --summarise
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

**Summary:** Execute commands in parallel with tmux and CPU/GPU assignment


**Usage:**
```bash
lsh <commands.txt> <num_workers> [--name NAME] [--gpus 0,1] [--dry-run]
```


**Safety:** `interactive`


**Tags:** parallel, system, tmux


**Examples:**
```bash
# Create commands file
echo 'python train.py --seed 1' > cmds.txt
echo 'python train.py --seed 2' >> cmds.txt

# Run in parallel
pytools run lsh cmds.txt 2 --gpus 0,1
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


### `set-env`

**Summary:** Manage KEY=VALUE entries in ~/.env


**Usage:**
```bash
set-env {set KEY VALUE | unset KEY | list}
```


**Safety:** `write`


**Tags:** config, env


**Examples:**
```bash
# Set variable
pytools run set-env set API_KEY mykey

# List all
pytools run set-env list

# Remove
pytools run set-env unset API_KEY
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
