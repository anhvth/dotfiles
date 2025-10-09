#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/bootstrap/common.sh"

bootstrap::ensure_dotfiles_dir
bootstrap::detect_sudo

log_info "${ICON_SETUP} Starting unattended setup..."
bootstrap::apt_update
bootstrap::add_apt_repository ppa:neovim-ppa/stable
bootstrap::apt_update

log_info "${ICON_PACKAGE} Installing required packages..."
bootstrap::apt_install zsh neovim tmux ripgrep fzf silversearcher-ag curl git

log_info "${ICON_CONFIG} Wiring shell/editor configs..."
bootstrap::link_config "source '$DOTFILES_DIR/zsh/zshrc_manager.sh'" "${HOME}/.zshrc"
bootstrap::link_config "so $DOTFILES_DIR/vim/nvimrc.vim" "${HOME}/.config/nvim/init.vim"
bootstrap::link_config "source-file $DOTFILES_DIR/tmux/tmux.conf" "${HOME}/.tmux.conf"

log_info "${ICON_PLUGIN} Installing vim-plug for Neovim..."
bootstrap::ensure_dir "${HOME}/.local/share/nvim/site/autoload"
curl -fsLo "${HOME}/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
log_success "${ICON_PLUGIN} vim-plug installed."

if [[ ! -d "${HOME}/.fzf" ]]; then
    log_info "${ICON_DOWNLOAD} Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
    yes | "${HOME}/.fzf/install" --all --no-bash --no-fish
    log_success "${ICON_DOWNLOAD} fzf installed."
else
    log_info "${ICON_CHECK} fzf already present. Skipping clone."
fi

if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    log_info "${ICON_DOWNLOAD} Installing oh-my-zsh..."
    git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh"
    log_success "${ICON_DOWNLOAD} oh-my-zsh installed."
else
    log_info "${ICON_CHECK} oh-my-zsh already present. Skipping clone."
fi

log_info "${ICON_CONFIG} Copying IPython configuration..."
bootstrap::copy_file "${DOTFILES_DIR}/tools/ipython_config.py" "${HOME}/.ipython/profile_default/ipython_config.py"

log_info "${ICON_GIT} Configuring Git identity..."
read -r -p "Enter your Git email: " git_email
git config --global user.email "$git_email"
read -r -p "Enter your Git username: " git_username
git config --global user.name "$git_username"
git config --global core.editor "nvim"

log_success "${ICON_SUCCESS} Setup complete!"
log_info "${ICON_INFO} Run 'nvim +PlugInstall +qall' after first launch to sync plugins."
