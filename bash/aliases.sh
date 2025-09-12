#!/bin/bash

# Bash Aliases Configuration
# Port of zsh/alias.sh to bash-compatible format

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
alias rs-git='rs --filter=":- .gitignore"'

# Custom tools aliases
alias autoreload='$HOME/dotfiles/custom-tools/autoreload-toggle'
alias ov='fetch_and_open_video'
alias code-debug='$HOME/dotfiles/bin/code-debug'

# LS aliases with colors
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias lll='ls -alh --color=auto'  # Human readable sizes
alias lt='ls -altr --color=auto'  # Sort by time
alias lsize='ls -lSr --color=auto'  # Sort by size

# Directory listing with tree-like structure
if command -v tree >/dev/null 2>&1; then
    alias tree='tree -C'  # Colorized tree
    alias tree1='tree -C -L 1'
    alias tree2='tree -C -L 2'
    alias tree3='tree -C -L 3'
fi

# SSH alias
alias run-autossh='autossh -M 20000 -o ServerAliveInterval=5 -f -N'

# Dotfiles alias
alias update-dotfiles='cwd=$(pwd) && cd ~/dotfiles && git pull && cd $cwd'

# Python tools aliases
alias lsh="pytools-lsh.py"
alias ipython_config="pytools-ipython_config.py"
alias cat_projects="python ~/dotfiles/custom-tools/pytools-cat_projects.py"
alias hf-down="pytools-hf-down.py"
alias kill_process_grep="pytools-kill_process_grep.py"
alias print-ipv4="pytools-print-ipv4.py"
alias deit="docker exec -it"

# Code editor preference (check for code-insiders first)
if command -v code-insiders >/dev/null 2>&1; then
    alias code="code-insiders"
else
    alias code="code"
fi

# Bash-specific aliases
alias bashrc='source ~/.bashrc && echo "✅ Bash configuration reloaded"'
alias editbash='nvim ~/dotfiles/bash/bashrc.sh'
alias editalias='nvim ~/dotfiles/bash/aliases.sh'
alias editfunc='nvim ~/dotfiles/bash/functions.sh'

# Performance mode aliases
alias bash_fast='export BASH_FAST_MODE=1 && exec bash'
alias bash_full='unset BASH_FAST_MODE && exec bash'
alias bash_reload='source ~/.bashrc'

# History aliases
alias h='history'
alias hgrep='history | grep --color=auto'
alias hclear='history -c && history -w'

# Color utility aliases
alias colors='for i in {0..255}; do printf "\033[38;5;${i}mColor $i\033[0m\n"; done | column -c 80'
alias color256='curl -s https://gist.githubusercontent.com/HaleTom/89ffe32783f89f403bba96bd7bcd1263/raw/ | bash'
alias rainbow='echo -e "\033[31mR\033[32mA\033[33mI\033[34mN\033[35mB\033[36mO\033[37mW\033[0m"'

# Enhanced grep with colors
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias rg='rg --color=always'

# Pretty print JSON with colors (if jq is available)
if command -v jq >/dev/null 2>&1; then
    alias json='jq --color-output .'
    alias jsonc='jq --color-output -C .'
fi

# Diff with colors
alias diff='diff --color=auto'

# IP command with colors
alias ip='ip --color=auto'