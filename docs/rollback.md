# Rollback guide

If a refactor change regresses your workflow, follow this playbook to revert cleanly.

## Quick disable switches

- Shell: `mv ~/.zshrc ~/.zshrc.broken && cp ~/dotfiles/backups/zshrc.pre-refactor ~/.zshrc`
- Neovim: `cp ~/dotfiles/backups/init.vim.pre-refactor ~/.config/nvim/init.vim`
- Tmux: `cp ~/dotfiles/backups/tmux.conf.pre-refactor ~/.tmux.conf`
- IPython: `cp ~/dotfiles/backups/ipython_config.py.pre-refactor ~/.ipython/profile_default/ipython_config.py`

## Git-based rollback

1. `cd ~/dotfiles`
2. `git checkout pre-refactor-YYYYMMDD`
3. Restore symlinks (if needed) by re-running the pre-refactor setup script.

## Smoke tests after rollback

- `zsh -i -c exit`
- `nvim --headless +qall`
- `tmux -f ~/.tmux.conf start-server \; display-message "tmux config OK"`

## Reporting

Log issues in `report.md` or your tracker. Include:

- What broke and reproduction steps.
- Phase/commit that introduced the issue.
- Any logs (shell output, plugin trace).
