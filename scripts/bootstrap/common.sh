#!/usr/bin/env bash
# Shared helpers for dotfile bootstrap scripts.
# shellcheck shell=bash

set -euo pipefail

if [[ -n "${BOOTSTRAP_COMMON_SOURCED:-}" ]]; then
  return
fi
BOOTSTRAP_COMMON_SOURCED=1

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_REPO_ROOT="$(cd "${BOOTSTRAP_DIR}/../.." && pwd)"
: "${DOTFILES_DIR:=${BOOTSTRAP_REPO_ROOT}}"

# Icons used across setup scripts for friendly logging.
ICON_SUCCESS="✅"
ICON_INFO="ℹ️"
ICON_WARN="⚠️"
ICON_ERROR="❌"
ICON_SETUP="⚙️"
ICON_PACKAGE="📦"
ICON_DOWNLOAD="📥"
ICON_CONFIG="🔧"
ICON_GIT="🌱"
ICON_SHELL="🐚"
ICON_OS="🐧"
ICON_UPDATE="🔄"
ICON_CHECK="🔎"
ICON_PLUGIN="🔌"
ICON_PYTHON="🐍"

# --- Logging helpers -------------------------------------------------------
log_info() { printf '%s %s\n' "${ICON_INFO}" "$*"; }
log_success() { printf '%s %s\n' "${ICON_SUCCESS}" "$*"; }
log_warning() { printf '%s %s\n' "${ICON_WARN}" "$*"; }
log_error() { printf '%s %s\n' "${ICON_ERROR}" "$*" >&2; exit 1; }

bootstrap::ensure_dotfiles_dir() {
  if [[ ! -d "${DOTFILES_DIR}" ]]; then
    log_error "Dotfiles directory '${DOTFILES_DIR}' not found."
  fi
}

bootstrap::ensure_dir() {
  local dir="$1"
  mkdir -p "$dir"
}

bootstrap::write_stub() {
  local target="$1"
  local line="$2"
  printf '%s\n' "$line" >"$target"
}

bootstrap::copy_file() {
  local source_path="$1"
  local destination="$2"
  if [[ ! -f "$source_path" ]]; then
    log_warning "Source file '${source_path}' not found. Skipping copy."
    return
  fi
  bootstrap::ensure_dir "$(dirname "$destination")"
  cp "$source_path" "$destination"
}

bootstrap::detect_sudo() {
  if [[ -n "${BOOTSTRAP_SUDO:-}" ]]; then
    return
  fi
  if [[ "$(id -u)" -eq 0 ]]; then
    BOOTSTRAP_SUDO=""
    log_info "Running as root. 'sudo' not required."
  elif command -v sudo >/dev/null 2>&1; then
    BOOTSTRAP_SUDO="sudo"
    log_info "Using sudo for privileged commands."
  else
    log_error "Non-root execution without sudo is unsupported."
  fi
}

bootstrap::sudo() {
  if [[ -n "${BOOTSTRAP_SUDO:-}" ]]; then
    "${BOOTSTRAP_SUDO}" "$@"
  else
    "$@"
  fi
}

bootstrap::apt_update() {
  bootstrap::detect_sudo
  if ! bootstrap::sudo apt-get update -y; then
    log_error "Failed to update package lists."
  fi
}

bootstrap::apt_install() {
  bootstrap::detect_sudo
  if ! bootstrap::sudo apt-get install -y "$@"; then
    log_error "Failed to install package(s): $*"
  fi
}

bootstrap::add_apt_repository() {
  local repo="$1"
  bootstrap::detect_sudo
  if ! command -v add-apt-repository >/dev/null 2>&1; then
    bootstrap::apt_install software-properties-common
  fi
  if ! bootstrap::sudo add-apt-repository -y "$repo"; then
    log_warning "Unable to add repository ${repo}. Continuing with defaults."
  fi
}

bootstrap::ensure_command() {
  local cmd="$1"
  local package="${2:-$1}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_info "${ICON_PACKAGE} Installing missing package '${package}' for command '${cmd}'."
    bootstrap::apt_install "$package"
  else
    log_success "${ICON_CHECK} '${cmd}' already available."
  fi
}

bootstrap::link_config() {
  local source_line="$1"
  local destination="$2"
  bootstrap::ensure_dir "$(dirname "$destination")"
  bootstrap::write_stub "$destination" "$source_line"
  log_success "${ICON_CONFIG} Linked ${destination}"
}
