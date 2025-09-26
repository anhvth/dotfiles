# Modern Bash Configuration (~/.bashrc or ~/dotfiles/bash/bashrc.sh)

# Function to set up code/code-insiders with fallback

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set up colors for the prompt
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_BLUE="\033[0;34m"
COLOR_CYAN="\033[0;36m"
COLOR_RESET="\033[0m"

# Function to parse Git branch for the prompt
parse_git_branch() {
    git branch 2> /dev/null | grep '^*' | colrm 1 2 | awk '{print " ("$1")"}'
}

# Customize the PS1 prompt
PS1="${COLOR_GREEN}\u@\h${COLOR_RESET}:${COLOR_BLUE}\w${COLOR_YELLOW}\$(parse_git_branch)${COLOR_RESET}\$ "

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Common aliases
alias ll='ls -l'
alias la='ls -la'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias h='history'
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# Enable history settings
HISTCONTROL=ignoreboth  # Ignore duplicate commands and commands starting with a space
HISTSIZE=100000
HISTFILESIZE=200000
shopt -s histappend  # Append to history file, don't overwrite

# Enable programmable completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# fzf configuration
if [ -f /usr/share/fzf/key-bindings.bash ]; then
    . /usr/share/fzf/key-bindings.bash
    . /usr/share/fzf/completion.bash
fi

# Basic fzf settings
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_DEFAULT_COMMAND='find . -type f'
fzf_open() {
    local file
    file=$(fzf --query="$1" --select-1 --exit-0)
    [ -n "$file" ] && ${EDITOR:-nano} "$file"
}
alias fo='fzf_open'

# Fuzzy cd to a directory
fzf_cd() {
    local dir
    dir=$(find . -type d 2>/dev/null | fzf +m) && cd "$dir"
}
alias fcd='fzf_cd'

# Environment variables

export PATH="$HOME/.local/bin:$PATH"  # Add ~/.local/bin to PATH

# Source additional configuration files if they exist
[ -f ~/.alias.h ] && source ~/.alias.h

# Print a welcome message
# echo -e "${COLOR_CYAN}Welcome to your modern Bash shell!${COLOR_RESET}"



fzf_search_history() {
    local selected_command
    selected_command=$(history | fzf +s --tac | sed 's/ *[0-9]* *//')
    if [ -n "$selected_command" ]; then
        echo "$selected_command"
        eval "$selected_command"
    fi
}
# key binding for fzf_search_history
bind -x '"\C-r": fzf_search_history'

source ~/dotfiles/zsh/alias.sh