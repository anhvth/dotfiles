alias vi=nvim
alias fzc="fzf | xargs -r code"
alias cd="cd"
alias dki="docker images"
alias gg="git status"
alias tb='tensorboard --logdir '
alias ta="tmux a -t "
alias tk="tmux kill-session -t"
alias i="ipython"
# alias iav="ipython --profile av"
alias iav="ipython --profile av"
alias checksize="du -h ./ | sort -rh "
alias ju="jupyter lab --allow-root --ip 0.0.0.0 --port "
alias dk="docker kill"
alias rs="rsync -avzhe ssh --progress "
alias rs-git="rs --filter=':- .gitignore' "
alias nb-clean="jupyter nbconvert --ClearOutputPreprocessor.enabled=True --inplace"
alias gpus="watch -n0.1 nvidia-smi"
alias run-autossh="autossh -M 20000 -o ServerAliveInterval=5 -f -N"
alias nvidia-smi-watch='watch -n0.1 nvidia-smi'
alias update-dotfiles="cwd=$(pwd) && cd ~/dotfiles && git pull && cd $cwd"
# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias convert_png2jpg="find ./ -name '*.png' | parallel 'convert -quality 92 -sampling-factor 2x2,1x1,1x1 {.}.png {.}.jpg && rm {}'"
alias what-is-my-ip="wget -qO- https://ipecho.net/plain ; echo"
alias run-list-cmd="python $HOME/dotfiles/tools/run_list_commands.py"
alias code-debug=$HOME"/dotfiles/bin/code-debug"
alias autoreload=$HOME"/dotfiles/custom-tools/autoreload-toggle"