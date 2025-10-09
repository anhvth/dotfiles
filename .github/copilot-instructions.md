This repository contains personal dotfiles and helper scripts for configuring
a developer shell environment (zsh, neovim, tmux) and small utilities.

Primary goals for an AI coding agent working in this repo:
- Be conservative: these are user configuration files used at login/startup.
- Prefer minimal, reversible changes and document them in the PR/commit.

Quick orientation
- Install / setup: `setup.sh`, `setup_noninteractive.sh`, `setup_ubuntu.sh` show
  the expected environment and common package commands. Use these scripts to
  understand how configuration files are applied (they write `~/.zshrc`,
  `~/.config/nvim/init.vim`, `~/.tmux.conf`).
- Major directories:
  - `zsh/` — primary shell configs and helper functions (`zsh/functions.sh`,
    `zsh/zshrc.sh`, `zsh/zshrc_manager.sh`).
  - `vim/` — neovim config and installers (`nvimrc.vim`, `install.sh`).
  - `custom-tools/` — small Python utilities and scripts (`pytools/`).
  - `default_configs/` — default configuration files (`ipython_config.py`).
  - `bin/` — user scripts and app images; inspect before modifying.

Conventions and patterns to follow (discoverable from files)
- Change scope: prefer edits under a single subdirectory (e.g. `zsh/` or
  `vim/`) for isolated changes. Avoid touching multiple top-level config files
  in one patch unless coordinating a single user-visible feature.
- Shell functions: `zsh/functions.sh` contains many helpers used interactively.
  Keep function names, argument patterns, and printed messages consistent.
  Example: `ve_auto_chdir on|off` toggles an entry in `~/.env` using `set_env`.
- Installer scripts: `setup.sh` and `setup_noninteractive.sh` are idempotent
  and intended to be runnable on Ubuntu/mac. Preserve the simple, imperative
  style (no heavy dependency injection).

Workflows and debug commands
- To replicate the user's environment locally, run the setup script in a
  disposable VM/container: `./setup_noninteractive.sh` (reads prompts; prefer
  `setup.sh` for interactive installs). After setup, source `~/.zshrc` or run
  `zsh_reload` (function in `zsh/functions.sh`).
- Neovim plugins: `vim/install.sh` and `~/.config/nvim/init.vim` are used to
  configure plugins. To update plugins run `nvim +PlugInstall +qall`.
- When changing shell startup files, test by running `zsh -i -c exit` or use
  `timezsh` (helper) to benchmark startup.

Integration points & external dependencies
- Scripts expect common tools: `zsh`, `neovim`, `tmux`, `git`, `fzf`,
  `ripgrep`, `silversearcher-ag`. Confirm package names in `setup*.sh` before
  adding new external tools.
- Several components assume `HOME/dotfiles` path (e.g. `zsh/functions.sh` uses
  `$HOME/dotfiles` explicitly). When editing, prefer relative references to
  `$HOME/dotfiles` only when the user's repo is installed there.
- `custom-tools/pytools` is a Python package — changes to it may require tests
  or `pyproject.toml` updates.

What to change and what to avoid
- Safe: Fix typos, small helper improvements, add missing docs, small shell
  function refactors that keep CLI compatibility.
- Avoid: Large rewrites of the login flow, changing `chsh` usage, or moving
  files without discussing with the repo owner — these affect the user's
  shell immediately.

Examples to reference in commits/PRs
- Toggle venv auto-activation: see `zsh/functions.sh::ve_auto_chdir`.
- Copy copilot instructions into a working `.github` dir (helper: `init_copilot_instruction`).
- Project-structure helper: `zsh/functions.sh::tree_project` generates a
  `project-structure.instructions.md` file — use that pattern when adding
  repo scanning helpers.

If unsure
- Run tests locally (few exist) and ask the repo owner before making any
  changes that modify shell startup behavior. Open a small, targeted PR and
  explain the reasoning.

End of instructions — ask the owner for clarification on any interactive
install steps you plan to change.
