# improve-code

A small CLI to format, auto-fix, and generate a code-quality report for Python projects.

## Usage

From any project directory:

- `improve-code` (default: format + fix + report)
- `improve-code format`
- `improve-code report`
- `improve-code view`

Config:

- Place `improve-code.yaml` in your project root (or pass `--config path/to/file.yaml`).
- If no config exists, the tool will create one from the built-in template.

## Install

This is installed by `~/dotfiles/setup.sh` (editable install).
