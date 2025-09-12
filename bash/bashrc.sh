#!/bin/bash

#============================================================================
# Bash Performance Mode System
# Modes: fastest, balanced, full
# Use: bash_toggle_mode to switch between modes
#============================================================================

# Start timing for performance measurement
if command -v date >/dev/null 2>&1; then
    if date +%s%N >/dev/null 2>&1; then
        # GNU date with nanoseconds
        BASH_START_TIME=$(($(date +%s%N)/1000000))
    else
        # Fallback to seconds for systems without nanosecond support
        BASH_START_TIME=$(($(date +%s)*1000))
    fi
else
    BASH_START_TIME=0
fi

# Determine current mode
BASH_MODE="${BASH_MODE:-balanced}"  # Default to balanced mode
BASH_MODE_FILE="$HOME/.bash_mode"

# Load saved mode if exists
if [ -f "$BASH_MODE_FILE" ]; then
    BASH_MODE="$(cat "$BASH_MODE_FILE")"
fi

#============================================================================
# Mode Toggle Functions
#============================================================================
bash_toggle_mode() {
    local current_mode="$BASH_MODE"
    local new_mode
    
    case "$current_mode" in
        fastest)  new_mode="balanced" ;;
        balanced) new_mode="full" ;;
        full)     new_mode="fastest" ;;
        *)        new_mode="balanced" ;;
    esac
    
    echo "$new_mode" > "$BASH_MODE_FILE"
    echo "🔄 Switching from $current_mode to $new_mode mode"
    echo "💡 Restart your terminal or run: exec bash"
    
    export BASH_MODE="$new_mode"
}

# Also provide direct mode setting
bash_set_mode() {
    local mode="$1"
    case "$mode" in
        fastest|balanced|full)
            echo "$mode" > "$BASH_MODE_FILE"
            echo "✅ Set mode to: $mode"
            echo "💡 Restart your terminal or run: exec bash"
            export BASH_MODE="$mode"
            ;;
        *)
            echo "❌ Invalid mode. Use: fastest, balanced, or full"
            echo "Current mode: $BASH_MODE"
            ;;
    esac
}

#============================================================================
# FASTEST MODE - Minimal setup for maximum speed
#============================================================================
if [ "$BASH_MODE" = "fastest" ]; then
    # Basic essentials only
    HISTFILE="$HOME/.bash_history"
    HISTSIZE=5000
    HISTFILESIZE=5000
    HISTCONTROL=ignoredups:ignorespace
    
    # Essential environment
    export VISUAL=vim
    export EDITOR=vim
    
    # Minimal path setup
    export PATH="$HOME/dotfiles/custom-tools:$HOME/.local/bin:$PATH"
    
    # Homebrew (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d /opt/homebrew/bin ]; then
            export PATH="/opt/homebrew/bin:$PATH"
        elif [ -d /usr/local/bin ]; then
            export PATH="/usr/local/bin:$PATH"
        fi
    fi
    
    # Load only critical files
    [ -r ~/.env ] && source ~/.env
    [ -f ~/dotfiles/bash/aliases.sh ] && source ~/dotfiles/bash/aliases.sh
    
    # Ultra-minimal colorized prompt
    PS1="\[\033[1;35m\]⚡\[\033[0m\]|\[\033[1;36m\]\W\[\033[0m\] \[\033[1;32m\]\$\[\033[0m\] "
    
    # Show startup time
    if [ "$BASH_START_TIME" -ne 0 ]; then
        if date +%s%N >/dev/null 2>&1; then
            BASH_END_TIME=$(($(date +%s%N)/1000000))
        else
            BASH_END_TIME=$(($(date +%s)*1000))
        fi
        BASH_LOAD_TIME=$((BASH_END_TIME - BASH_START_TIME))
        echo "⚡ Bash Fastest Mode Active (${BASH_LOAD_TIME}ms)"
    else
        echo "⚡ Bash Fastest Mode Active"
    fi
    return
fi

#============================================================================
# BALANCED MODE - Optimized setup with key features
#============================================================================
if [ "$BASH_MODE" = "balanced" ]; then
    # Basic configuration
    HISTFILE="$HOME/.bash_history"
    HISTSIZE=10000
    HISTFILESIZE=10000
    HISTCONTROL=ignoredups:ignorespace
    
    # Append to history file, don't overwrite it
    shopt -s histappend
    
    # Check window size after each command
    shopt -s checkwinsize
    
    # Enable advanced pattern matching
    shopt -s extglob
    
    # Enable case-insensitive globbing
    shopt -s nocaseglob
    
    export VISUAL=vim
    export EDITOR=vim
    
    # Optimized path setup
    export PATH="$HOME/dotfiles/custom-tools:$HOME/.local/bin:$HOME/dotfiles/utils:$HOME/dotfiles/bin:$PATH"
    
    # Homebrew paths (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d /opt/homebrew/bin ]; then
            export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
        elif [ -d /usr/local/bin ]; then
            export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
        fi
    fi
    
    # FZF integration (compatible with older versions)
    if [ -f ~/.fzf.bash ]; then
        # Check if FZF supports --bash option (v0.48+)
        if fzf --bash &>/dev/null; then
            source ~/.fzf.bash
        else
            # Fallback for older FZF versions
            if [ -f ~/.fzf/shell/completion.bash ]; then
                source ~/.fzf/shell/completion.bash
            fi
            if [ -f ~/.fzf/shell/key-bindings.bash ]; then
                source ~/.fzf/shell/key-bindings.bash
            fi
        fi
    fi
    
    # Git integration with enhanced colors
    if command -v git >/dev/null 2>&1; then
        # Enhanced git branch in prompt with status colors
        parse_git_branch() {
            local branch
            branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
            if [ -z "$branch" ]; then
                return  # Not a git repo
            fi

            local git_status
            git_status=$(git status --porcelain 2>/dev/null)
            local color="\033[0;32m" # Green for clean
            local state=""

            if [ -n "$git_status" ]; then
                color="\033[0;31m" # Red for dirty
                if echo "$git_status" | grep -q '^??'; then
                    state+="U" # Untracked
                fi
                if echo "$git_status" | grep -q '^.[MD]'; then
                    state+="M" # Modified
                fi
                if echo "$git_status" | grep -q '^[MARC]'; then
                    state+="A" # Added/Staged
                fi
            fi
            
            if [ -n "$state" ]; then
                echo -e " [${color}${branch} (${state})\033[0m]"
            else
                echo -e " [\033[0;32m${branch}\033[0m]"
            fi
        }

        # Set the prompt
        PS1="\[\033[1;32m\]\u\[\033[0m\]@\[\033[1;33m\]\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\$(parse_git_branch)\[\033[1;36m\]\$\[\033[0m\] "
    else
        # Default prompt without git
        PS1="\[\033[1;32m\]\u\[\033[0m\]@\[\033[1;33m\]\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\[\033[1;36m\]\$\[\033[0m\] "
    fi

    # Load essential configurations
    [ -r ~/.env ] && source ~/.env
    [ -f ~/dotfiles/bash/aliases.sh ] && source ~/dotfiles/bash/aliases.sh
    [ -f ~/dotfiles/bash/functions.sh ] && source ~/dotfiles/bash/functions.sh
    [ -f ~/dotfiles/bash/keybindings.sh ] && source ~/dotfiles/bash/keybindings.sh
    
    # Load bash completion
    if ! shopt -oq posix; then
        if [ -f /usr/share/bash-completion/bash_completion ]; then
            source /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
            source /etc/bash_completion
        fi
    fi
    
    # Show startup time
    if [ "$BASH_START_TIME" -ne 0 ]; then
        if date +%s%N >/dev/null 2>&1; then
            BASH_END_TIME=$(($(date +%s%N)/1000000))
        else
            BASH_END_TIME=$(($(date +%s)*1000))
        fi
        BASH_LOAD_TIME=$((BASH_END_TIME - BASH_START_TIME))
        echo "⚖️  Bash Balanced Mode Active (${BASH_LOAD_TIME}ms)"
    else
        echo "⚖️  Bash Balanced Mode Active"
    fi
    return
fi

#============================================================================
# FULL MODE - All features with performance optimizations
#============================================================================

# History Configuration
HISTFILE="$HOME/.bash_history"
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:ignorespace

# Append to history file, don't overwrite it
shopt -s histappend

# Save multi-line commands as one command
shopt -s cmdhist

# Check window size after each command and update LINES and COLUMNS
shopt -s checkwinsize

# Enable advanced pattern matching features
shopt -s extglob

# Enable case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Enable recursive globbing with **
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    shopt -s globstar
fi

# Basic Environment
export VISUAL=vim
export EDITOR=vim
export PAGER=less

# Full path configuration
export PATH="$HOME/dotfiles/utils/ripgrep_all-v0.9.5-x86_64-unknown-linux-musl:$HOME/dotfiles/utils:$HOME/dotfiles/squashfs-root/usr/bin:$HOME/dotfiles/tools/bin:$HOME/dotfiles/bin/dist:$HOME/dotfiles/custom-tools:$HOME/.local/bin:$HOME/.fzf/bin:$PATH"

# Homebrew paths (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [ -d /opt/homebrew/bin ]; then
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    elif [ -d /usr/local/bin ]; then
        export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
    fi
fi

# # Enhanced Git prompt function with detailed status
# parse_git_branch() {
#     local branch
#     branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
#     if [ -n "$branch" ]; then
#         local status=""
#         local color="1;32m"  # Bright green for clean
#         local git_status=$(git status --porcelain 2>/dev/null)
        
#         if [ -n "$git_status" ]; then
#             # Check different types of changes
#             if echo "$git_status" | grep -q '^??'; then
#                 status="${status}?"
#             fi
#             if echo "$git_status" | grep -q '^.[MD]'; then
#                 status="${status}!"
#             fi
#             if echo "$git_status" | grep -q '^[MARC]'; then
#                 status="${status}+"
#             fi
#             color="1;31m"  # Bright red for dirty
#         fi
        
#         echo " \[\033[${color}\](${branch}${status})\[\033[0m\]"
#     fi
# }

# # Enhanced prompt with git support and vibrant colors
# if command -v git >/dev/null 2>&1; then
#     PS1="\[\033[1;32m\]\u\[\033[0m\]@\[\033[1;33m\]\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\$(parse_git_branch)\[\033[1;35m\] ❯\[\033[0m\] "
# else
#     PS1="\[\033[1;32m\]\u\[\033[0m\]@\[\033[1;33m\]\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\[\033[1;35m\] ❯\[\033[0m\] "
# fi

# Load all configurations
[ -r ~/.env ] && source ~/.env
[ -f ~/dotfiles/bash/aliases.sh ] && source ~/dotfiles/bash/aliases.sh
[ -f ~/dotfiles/bash/functions.sh ] && source ~/dotfiles/bash/functions.sh
[ -f ~/dotfiles/bash/keybindings.sh ] && source ~/dotfiles/bash/keybindings.sh

# Enhanced bash completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        source /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        source /etc/bash_completion
    fi
fi

# FZF integration with enhanced features (compatible with older versions)
if [ -f ~/.fzf.bash ]; then
    # Check if FZF supports --bash option (v0.48+)
    if fzf --bash &>/dev/null; then
        source ~/.fzf.bash
    else
        # Fallback for older FZF versions
        if [ -f ~/.fzf/shell/completion.bash ]; then
            source ~/.fzf/shell/completion.bash
        fi
        if [ -f ~/.fzf/shell/key-bindings.bash ]; then
            source ~/.fzf/shell/key-bindings.bash
        fi
    fi
    
    # Enhanced FZF settings
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    
    # Use ripgrep if available
    if command -v rg >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# Directory navigation enhancements
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    # Auto-correct minor spelling errors in directory names
    shopt -s dirspell
    
    # Auto-expand directory stack when using cd
    shopt -s autocd 2>/dev/null
fi

# Programmable completion enhancements
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    source /etc/bash_completion
fi

# Virtual environment auto-activation
_activate_venv() {
    if [ "${VENV_AUTO_CHDIR:-on}" = "on" ]; then
        # Look for virtual environment in current directory and parents
        local dir="$PWD"
        while [ "$dir" != "/" ]; do
            if [ -f "$dir/bin/activate" ]; then
                if [ "$VIRTUAL_ENV" != "$dir" ]; then
                    echo "🐍 Activating virtual environment: $dir"
                    source "$dir/bin/activate"
                fi
                return
            elif [ -f "$dir/venv/bin/activate" ]; then
                if [ "$VIRTUAL_ENV" != "$dir/venv" ]; then
                    echo "🐍 Activating virtual environment: $dir/venv"
                    source "$dir/venv/bin/activate"
                fi
                return
            elif [ -f "$dir/.venv/bin/activate" ]; then
                if [ "$VIRTUAL_ENV" != "$dir/.venv" ]; then
                    echo "🐍 Activating virtual environment: $dir/.venv"
                    source "$dir/.venv/bin/activate"
                fi
                return
            fi
            dir="$(dirname "$dir")"
        done
    fi
}

# Override cd to auto-activate virtual environments
cd() {
    builtin cd "$@" && _activate_venv
}

# Auto-activate on login if enabled
if [ "${VENV_AUTO_ACTIVATE:-off}" = "on" ]; then
    _activate_venv
fi

# Enhanced history search with readline
if [ -t 1 ]; then
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
    bind '"\e[C": forward-char'
    bind '"\e[D": backward-char'
fi

# Show startup time
if [ "$BASH_START_TIME" -ne 0 ]; then
    if date +%s%N >/dev/null 2>&1; then
        BASH_END_TIME=$(($(date +%s%N)/1000000))
    else
        BASH_END_TIME=$(($(date +%s)*1000))
    fi
    BASH_LOAD_TIME=$((BASH_END_TIME - BASH_START_TIME))
    echo "🚀 Bash Full Mode Active (${BASH_LOAD_TIME}ms)"
else
    echo "🚀 Bash Full Mode Active"
fi

#============================================================================
# COLOR CONFIGURATION - Terminal colors and colored output
#============================================================================

# Enable color support for terminal
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Colored ls output
if [ "$TERM" != "dumb" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        export CLICOLOR=1
        export LSCOLORS=ExFxBxDxCxegedabagacad
        alias ls='ls -G'
    else
        # Linux
        alias ls='ls --color=auto'
    fi
fi

# Colored grep output
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Colored man pages
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

# Force color output for some tools
export FORCE_COLOR=1
export CLICOLOR_FORCE=1

# GCC colored output
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Enable 256 colors if supported
if [ "$TERM" = "xterm" ] || [ "$TERM" = "screen" ]; then
    export TERM="${TERM}-256color"
fi

# Color definitions for use in scripts/functions
export COLOR_BLACK='\033[0;30m'
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[0;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_PURPLE='\033[0;35m'
export COLOR_CYAN='\033[0;36m'
export COLOR_WHITE='\033[0;37m'
export COLOR_BOLD_BLACK='\033[1;30m'
export COLOR_BOLD_RED='\033[1;31m'
export COLOR_BOLD_GREEN='\033[1;32m'
export COLOR_BOLD_YELLOW='\033[1;33m'
export COLOR_BOLD_BLUE='\033[1;34m'
export COLOR_BOLD_PURPLE='\033[1;35m'
export COLOR_BOLD_CYAN='\033[1;36m'
export COLOR_BOLD_WHITE='\033[1;37m'
export COLOR_RESET='\033[0m'

# Color helper functions
color_echo() {
    local color="$1"
    shift
    echo -e "${color}$*${COLOR_RESET}"
}

# Usage examples:
# color_echo $COLOR_RED "This is red text"
# color_echo $COLOR_BOLD_GREEN "This is bold green text"