#!/bin/zsh

# Editor
alias vi='nvim'

# FZF
alias fzc='fzf | xargs -r code'

# Docker aliases
alias dki='docker images'
alias dk='docker kill'

# Git aliases
alias gg='git status'

# TensorBoard alias
alias tb='tensorboard --logdir '

# Tmux aliases
alias ta='tmux a -t '
alias tk='tmux kill-session -t'

# Python and Jupyter aliases
alias i='ipython'
alias iav='ipython --profile av'
alias ju='jupyter lab --allow-root --ip 0.0.0.0 --port '
alias nb-clean='jupyter nbconvert --ClearOutputPreprocessor.enabled=True --inplace'

# Utility aliases
alias checksize='sudo du -h ./ | sort -rh | head -n30'
alias gpus='watch -n0.1 nvidia-smi'
alias what-is-my-ip='wget -qO- https://ipecho.net/plain ; echo'
alias kill_processes='awk "{print \$2}" | xargs kill'

# Rsync aliases
alias rs='rsync -av --progress'


# Custom tools aliases
alias autoreload='$HOME/dotfiles/custom-tools/autoreload-toggle'
alias ov='fetch_and_open_video'
alias code-debug='$HOME/dotfiles/bin/code-debug'

# LS aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Image conversion alias
alias convert_png2jpg='find ./ -name "*.png" | parallel "convert -quality 92 -sampling-factor 2x2,1x1,1x1 {.}.png {.}.jpg && rm {}"'

# SSH alias
alias run-autossh='autossh -M 20000 -o ServerAliveInterval=5 -f -N'

# Dotfiles alias
alias update-dotfiles='cwd=$(pwd) && cd ~/dotfiles && git pull && cd $cwd'


alias deit="docker exec -it"

# UV virtual environment creation moved to zsh/venv.sh (venv-create function)
alias install-pytools='cd ~/dotfiles/custom-tools/pytools && uv tool install --force --editable . && cd -'

# Smart pytools wrapper - auto-installs if not found
pytools() {
    if command -v pytools >/dev/null 2>&1; then
        command pytools "$@"
    else
        echo "⚠️  pytools not found, installing..."
        install-pytools && command pytools "$@"
    fi
}