export COLOR_RESET="\[\033[0m\]"
export COLOR_RED="\[\033[0;31m\]"
export COLOR_GREEN="\[\033[0;32m\]"
export COLOR_YELLOW="\[\033[0;33m\]"
export COLOR_BLUE="\[\033[0;34m\]"
export COLOR_MAGENTA="\[\033[0;35m\]"
export COLOR_CYAN="\[\033[0;36m\]"
export COLOR_WHITE="\[\033[0;37m\]"

# Customize the prompt
export PS1="${COLOR_CYAN}\u@\h${COLOR_RESET}:${COLOR_GREEN}\w${COLOR_RESET}\$ "

# Aliases
alias ll='ls -alF'
alias grep='grep --color=auto'
alias ..='cd ..'

# Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar e "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
