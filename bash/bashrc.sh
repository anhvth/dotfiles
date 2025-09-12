# Modern Bash Configuration (~/.bashrc or ~/dotfiles/bash/bashrc.sh)
# Optimized for performance and modern bash features

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ============================================================================
# SHELL OPTIONS AND BEHAVIOR
# ============================================================================

# Set advanced bash options for better behavior
set -o notify          # Report status of terminated background jobs immediately
shopt -s checkwinsize  # Check window size after each command and update LINES/COLUMNS
shopt -s expand_aliases # Expand aliases in non-interactive shells
shopt -s histappend    # Append to history file, don't overwrite
shopt -s histverify    # Allow editing of history substitutions
shopt -s cdspell       # Autocorrect minor spelling errors in cd commands
shopt -s dirspell      # Autocorrect minor spelling errors in directory names
shopt -s globstar      # Enable ** recursive globbing
shopt -s nocaseglob    # Case-insensitive globbing

# History configuration
HISTCONTROL=ignoreboth:erasedups  # Ignore duplicates and commands starting with space
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "  # Add timestamps to history

# Set up colors for the prompt and tools
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_BLUE="\033[0;34m"
COLOR_PURPLE="\033[0;35m"
COLOR_CYAN="\033[0;36m"
COLOR_WHITE="\033[0;37m"
COLOR_BOLD="\033[1m"
COLOR_RESET="\033[0m"

# ============================================================================
# PROMPT CONFIGURATION
# ============================================================================

# Function to get git status information
parse_git_status() {
    local git_status git_branch
    git_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    
    if [[ -n "$git_branch" ]]; then
        git_status=$(git status --porcelain 2>/dev/null)
        local status_symbol=""
        
        if [[ -n "$git_status" ]]; then
            status_symbol="${COLOR_RED}*${COLOR_RESET}"
        else
            status_symbol="${COLOR_GREEN}✓${COLOR_RESET}"
        fi
        
        echo " ${COLOR_YELLOW}(${git_branch}${status_symbol}${COLOR_YELLOW})${COLOR_RESET}"
    fi
}

# Function to show current Python virtual environment
show_venv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "${COLOR_PURPLE}($(basename "$VIRTUAL_ENV"))${COLOR_RESET} "
    fi
}

# Enhanced PS1 prompt with git status and virtual environment
PS1="\$(show_venv)${COLOR_GREEN}\u@\h${COLOR_RESET}:${COLOR_BLUE}\w${COLOR_RESET}\$(parse_git_status)${COLOR_RESET}\$ "

# ============================================================================
# COLOR SUPPORT AND BASIC ALIASES
# ============================================================================

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

# ============================================================================
# NAVIGATION AND FILE SYSTEM ALIASES
# ============================================================================

# Basic navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias c='clear'
alias h='history'

# Enhanced ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -altrh'  # Sort by time, newest last
alias lsize='ls -alSrh'  # Sort by size, largest last

# ============================================================================
# DEVELOPMENT ALIASES
# ============================================================================

# Editor aliases
alias vi='nvim'
alias vim='nvim'

# Git aliases
alias gg='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gb='git branch'
alias gco='git checkout'

# Python and development
alias i='ipython'
alias iav='ipython --profile av'
alias py='python3'
alias pip='pip3'

# Docker aliases
alias dki='docker images'
alias dk='docker kill'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias deit="docker exec -it"

# ============================================================================
# SPECIALIZED TOOLS AND UTILITIES
# ============================================================================

# TensorBoard alias
alias tb='tensorboard --logdir '

# Tmux aliases
alias ta='tmux a -t '
alias tk='tmux kill-session -t'
alias tl='tmux list-sessions'

# Jupyter aliases
alias ju='jupyter lab --allow-root --ip 0.0.0.0 --port '
alias nb-clean='jupyter nbconvert --ClearOutputPreprocessor.enabled=True --inplace'

# System utilities
alias checksize='sudo du -h ./ | sort -rh | head -n30'
alias gpus='watch -n0.1 nvidia-smi'
alias what-is-my-ip='wget -qO- https://ipecho.net/plain ; echo'
alias kill_processes='awk "{print \$2}" | xargs kill'

# Rsync aliases
alias rs='rsync -av --progress'
alias rs-git='rs --filter=\':- .gitignore\''

# SSH and connection
alias run-autossh='autossh -M 20000 -o ServerAliveInterval=5 -f -N'

# Dotfiles management
alias update-dotfiles='cwd=$(pwd) && cd ~/dotfiles && git pull && cd $cwd'

# Custom tools aliases
alias autoreload='$HOME/dotfiles/custom-tools/autoreload-toggle'
alias ov='fetch_and_open_video'
alias code-debug='$HOME/dotfiles/bin/code-debug'
alias lsh="pytools-lsh.py"
alias ipython_config="pytools-ipython_config.py"
alias cat_projects="python ~/dotfiles/custom-tools/pytools-cat_projects.py"
alias hf-down="pytools-hf-down.py"
alias kill_process_grep="pytools-kill_process_grep.py"
alias print-ipv4="pytools-print-ipv4.py"

# Image processing
alias convert_png2jpg='find ./ -name "*.png" | parallel "convert -quality 92 -sampling-factor 2x2,1x1,1x1 {.}.png {.}.jpg && rm {}"'

# VS Code setup - prioritize code-insiders if available
if command -v code-insiders >/dev/null 2>&1; then
  alias code="code-insiders"
else
  alias code="code"
fi


# ============================================================================
# ENVIRONMENT VARIABLES AND PATH
# ============================================================================

# Set default editor
export EDITOR=nvim
export VISUAL=nvim

# Add local bin directories to PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ============================================================================
# PROGRAMMABLE COMPLETION
# ============================================================================

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

# ============================================================================
# FZF CONFIGURATION AND FUNCTIONS
# ============================================================================

# Lazy load fzf to improve startup time
load_fzf() {
    if [ -f /usr/share/fzf/key-bindings.bash ]; then
        . /usr/share/fzf/key-bindings.bash
        . /usr/share/fzf/completion.bash
    fi
    
    # Enhanced fzf configuration
    export FZF_DEFAULT_OPTS='
        --height 40% 
        --layout=reverse 
        --border
        --preview "head -100 {}"
        --preview-window=right:50%:wrap
        --bind "ctrl-y:execute-silent(echo {} | xclip -selection clipboard)"
        --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796
        --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6
        --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796'
    
    # Use fd or find for file search
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    else
        export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*"'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='find . -type d -not -path "*/\.git/*"'
    fi
}

# Enhanced fzf functions
fzf_open() {
    local file
    [ ! -command -v fzf >/dev/null 2>&1 ] && { echo "fzf not installed"; return 1; }
    file=$(fzf --query="$1" --select-1 --exit-0 --preview 'head -100 {}')
    [ -n "$file" ] && ${EDITOR:-nano} "$file"
}
alias fo='fzf_open'

# Fuzzy find and open with VS Code
fzf_code() {
    local file
    [ ! -command -v fzf >/dev/null 2>&1 ] && { echo "fzf not installed"; return 1; }
    file=$(fzf --query="$1" --select-1 --exit-0 --preview 'head -100 {}')
    [ -n "$file" ] && code "$file"
}
alias fzc='fzf_code'

# Fuzzy cd to a directory
fzf_cd() {
    local dir
    [ ! -command -v fzf >/dev/null 2>&1 ] && { echo "fzf not installed"; return 1; }
    if command -v fd >/dev/null 2>&1; then
        dir=$(fd --type d --hidden --follow --exclude .git | fzf +m --preview 'ls -la {}')
    else
        dir=$(find . -type d -not -path "*/\.git/*" 2>/dev/null | fzf +m --preview 'ls -la {}')
    fi
    [ -n "$dir" ] && cd "$dir"
}
alias fcd='fzf_cd'

# Enhanced history search with fzf
fzf_search_history() {
    local selected_command
    [ ! -command -v fzf >/dev/null 2>&1 ] && { echo "fzf not installed"; return 1; }
    selected_command=$(history | fzf +s --tac --no-preview | sed 's/ *[0-9]* *//')
    if [ -n "$selected_command" ]; then
        echo "$selected_command"
        eval "$selected_command"
    fi
}

# Fuzzy kill process
fzf_kill() {
    local pid
    [ ! -command -v fzf >/dev/null 2>&1 ] && { echo "fzf not installed"; return 1; }
    pid=$(ps -ef | sed 1d | fzf -m --preview 'echo {}' | awk '{print $2}')
    if [ -n "$pid" ]; then
        echo "$pid" | xargs kill -${1:-9}
    fi
}
alias fkill='fzf_kill'

# Key binding for enhanced history search
bind -x '"\C-r": fzf_search_history'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Create directory and navigate to it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find and replace in files
findreplace() {
    if [ $# -ne 3 ]; then
        echo "Usage: findreplace <directory> <find_pattern> <replace_pattern>"
        return 1
    fi
    find "$1" -type f -exec sed -i "s/$2/$3/g" {} +
}

# Show directory sizes
dirsize() {
    du -sh "${1:-.}"/* 2>/dev/null | sort -hr
}

# Quick backup function
backup() {
    if [ $# -eq 0 ]; then
        echo "Usage: backup <file_or_directory>"
        return 1
    fi
    cp -r "$1" "${1}.backup.$(date +%Y%m%d_%H%M%S)"
}

# Weather function (requires curl)
weather() {
    curl -s "wttr.in/${1:-$(curl -s ipinfo.io/city)}"
}

# Get public IP
myip() {
    curl -s ifconfig.me
}

# Port check function
portcheck() {
    if [ $# -eq 0 ]; then
        echo "Usage: portcheck <port>"
        return 1
    fi
    lsof -i ":$1"
}

# Git log with graph
gitgraph() {
    git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit "${@:-HEAD}"
}

# Search for text in files
search() {
    if [ $# -eq 0 ]; then
        echo "Usage: search <pattern> [directory]"
        return 1
    fi
    grep -r --color=auto "$1" "${2:-.}"
}

# Quick server for current directory
serve() {
    local port="${1:-8000}"
    if command -v python3 >/dev/null 2>&1; then
        python3 -m http.server "$port"
    elif command -v python >/dev/null 2>&1; then
        python -m SimpleHTTPServer "$port"
    else
        echo "Python not found. Cannot start server."
        return 1
    fi
}

# Process monitoring
psmem() {
    ps aux | sort -nrk 4 | head -10
}

pscpu() {
    ps aux | sort -nrk 3 | head -10
}

# ============================================================================
# SOURCE ADDITIONAL CONFIGURATIONS
# ============================================================================

# Source additional configuration files if they exist
[ -f ~/.alias.h ] && source ~/.alias.h
[ -f ~/.bashrc.local ] && source ~/.bashrc.local

# ============================================================================
# STARTUP MESSAGE
# ============================================================================

# Print a welcome message with system info
startup_info() {
    echo -e "${COLOR_CYAN}╭─────────────────────────────────────────╮${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET} ${COLOR_BOLD}Welcome to your enhanced Bash shell!${COLOR_RESET}   ${COLOR_CYAN}│${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET} ${COLOR_GREEN}Host:${COLOR_RESET} $(hostname)                        ${COLOR_CYAN}│${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET} ${COLOR_GREEN}User:${COLOR_RESET} $(whoami)                          ${COLOR_CYAN}│${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET} ${COLOR_GREEN}Date:${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S')        ${COLOR_CYAN}│${COLOR_RESET}"
    if command -v git >/dev/null 2>&1 && [ -d .git ]; then
        echo -e "${COLOR_CYAN}│${COLOR_RESET} ${COLOR_GREEN}Git:${COLOR_RESET}  $(git branch --show-current 2>/dev/null || echo 'Not a git repository') ${COLOR_CYAN}│${COLOR_RESET}"
    fi
    echo -e "${COLOR_CYAN}╰─────────────────────────────────────────╯${COLOR_RESET}"
}

# Only show startup info in interactive shells
if [[ $- == *i* ]]; then
    startup_info
fi