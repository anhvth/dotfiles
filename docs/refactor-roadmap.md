# Refactor roadmap

The refactor progresses in deliberate phases to keep daily workflows stable. Complete and validate each phase before starting the next one.

## Phase 0 – Safety net

- Capture baseline metrics and versions (see `baseline.md`).
- Create restore points: `git tag`, `tar` backups for shell/editor configs.
- Draft smoke tests for zsh, Neovim, and tmux startup.

## Phase 1 – Structure & hygiene

- Introduce a shared bootstrap helper for setup scripts.
- Standardize repository layout (group setup logic under `scripts/bootstrap/`, docs in `docs/`).
- Start modularizing shell helpers: split `zsh/functions.sh` into themed modules and load through `zshrc_manager.sh`.
- Capture Neovim configuration in `vim/nvim/` and plan migration towards Lua configs while keeping vimscript compatibility.
- Break `tmux/tmux.conf` into logical includes.

## Phase 2 – Automation & quality gates

- Wire up linting: shellcheck (`scripts/`, `zsh/`), stylua for Neovim Lua modules, `pytest` for `custom-tools/pytools`.
- Add pre-commit hooks to run lint/smoke checks locally.
- Publish GitHub Actions workflow for CI parity.

## Phase 3 – Feature hardening & docs

- Offer feature flags (e.g., FZF, direnv) controlled via `~/.config/dotfiles/profile.yml`.
- Document Neovim plugins with their purpose and health-check commands.
- Add tmux session restoration helpers and keybinding cheatsheet.
- Maintain a changelog noting user-facing differences and migration steps.

## Rollout checklist (per phase)

1. Work in feature branches with detailed commit messages.
2. Run smoke tests (interactive shell, `nvim --headless`, `tmux -f tmux/tmux.conf ls`).
3. Update documentation in this folder.
4. Announce changes and provide rollback instructions.
