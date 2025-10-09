# Bin Folder Agents Guide

## Architecture Overview

User bin directory containing executable scripts, binaries, and utilities for development tasks.

Main files: Scripts like `generate-report.sh` (pylint error reports), `organize_download.py` (organize downloads by date), binaries like `nvim.appimage`, `rs-code`.

Data flow: Scripts executed directly or added to PATH for CLI usage.

## Developer Workflows

- **Running scripts**: Execute directly (e.g., `./generate-report.sh`) or add bin/ to PATH
- **Report generation**: `generate-report.sh` scans Python files for pylint errors, outputs to report.readme
- **Download organization**: `organize_download.py` moves files in ~/Downloads to date folders
- **Binary usage**: Run appimages like `./nvim.appimage` for portable Neovim

## Conventions & Patterns

- **Script structure**: Bash scripts with #!/bin/bash, Python scripts with if __name__ == "__main__"
- **Error handling**: Try-except in Python, basic checks in bash
- **Output**: Print progress/messages, write reports to files
- **Dependencies**: Assume common tools (pylint for reports, shutil/os for file ops)

## Integration Points

- **Pylint**: Used in generate-report.sh for Python code analysis
- **File system**: organize_download.py manipulates ~/Downloads directory
- **AppImages**: Portable binaries like nvim.appimage for self-contained execution