# Baseline snapshot

Use this checklist to capture the state of the machine before running the refactor. Having these reference points helps during regression triage and rollback.

## System metadata

- `uname -a`
- `lsb_release -a` (or `sw_vers` on macOS)
- `zsh --version`, `bash --version`
- `nvim --version`, `tmux -V`
- `python3 --version`, `pipx --version`

Record the output in `report.md` or attach it to the tracking issue before continuing.

## Shell startup timing

Run `timezsh` (defined in `zsh/functions.sh`) to collect the average interactive shell startup time.

## Dotfiles snapshot

- Tag the repo: `git tag pre-refactor-$(date +%Y%m%d)`
- Backup key config files:
  - `~/.zshrc`
  - `~/.config/nvim/init.vim`
  - `~/.tmux.conf`
  - `~/.ipython/profile_default/ipython_config.py`

Store archives under `~/dotfiles/backups/` or another safe path.
