#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${REPO_ROOT}/scripts/bootstrap/common.sh"

trap 'tmux -L dotfiles-smoke kill-server >/dev/null 2>&1 || true' EXIT

run_check() {
  local description="$1"
  shift
  log_info "${ICON_CHECK} ${description}"
  local output
  if output=$("$@" 2>&1); then
    log_success "${description} passed."
  else
    printf '%s\n' "$output" >&2
    log_error "${description} failed."
  fi
}

run_check "Interactive zsh starts" zsh -i -c exit
run_check "Neovim loads headless" nvim --headless +qall
run_check "Tmux config parses" tmux -f "${DOTFILES_DIR}/tmux/tmux.conf" -L dotfiles-smoke list-keys

log_success "Smoke tests completed."
