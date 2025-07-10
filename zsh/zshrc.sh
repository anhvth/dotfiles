#------------------------------------------
# Theme and Oh-My-Zsh Setup
#------------------------------------------
# Fast startup mode (set ZSH_FAST_MODE=1 to enable minimal loading)
if [[ "$ZSH_FAST_MODE" == "1" ]]; then
    # Minimal setup for fastest startup
    HISTFILE=$HOME/.zsh_history
    SAVEHIST=1000
    setopt inc_append_history share_history
    
    # Basic path setup only
    typeset -U path PATH
    path=($HOME/dotfiles/custom-tools $HOME/.local/bin $path)
    
    # Load only essential aliases and functions
    source ~/dotfiles/zsh/alias.sh
    
    # Simple prompt
    PS1="fast|%~ %# "
    return
fi

# Performance optimizations
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
COMPLETION_WAITING_DOTS="false"

# Use simple theme for faster startup
ZSH_THEME="robbyrussell"
export ZSH="$HOME/dotfiles/zsh/plugins/oh-my-zsh"


#------------------------------------------
# Basic Configuration
#------------------------------------------
# History settings
HISTFILE=$HOME/.zsh_history
SAVEHIST=10000
setopt inc_append_history # To save every command before it is executed 
setopt share_history # Share history between terminals
stty -ixon # Disable terminal flow control (Ctrl+S, Ctrl+Q)

# Editor configuration
export VISUAL=vim
# VSCODE=code-insiders

# Set FUNCNEST to prevent "maximum nested function level reached" errors
export FUNCNEST=100000

#------------------------------------------
# Path Configuration
#------------------------------------------
# Use typeset for efficient path management and avoid duplicates
typeset -U path PATH

# Add paths efficiently
path=(
    $HOME/dotfiles/utils/ripgrep_all-v0.9.5-x86_64-unknown-linux-musl
    $HOME/dotfiles/utils
    $HOME/dotfiles/squashfs-root/usr/bin
    $HOME/dotfiles/tools/bin
    $HOME/dotfiles/bin/dist
    $HOME/dotfiles/custom-tools
    $HOME/.local/bin
    $HOME/.fzf/bin
    $path
)

# Homebrew paths (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ -d /opt/homebrew/bin ]]; then
        path=(/opt/homebrew/bin /opt/homebrew/sbin $path)
    else
        path=(/usr/local/bin /usr/local/sbin $path)
    fi
fi

#------------------------------------------
# Environment and Config Sources
#------------------------------------------
# Source environment variables (only if file exists and is readable)
[[ -r ~/.env ]] && source ~/.env

# Source configuration files
# Load oh-my-zsh with minimal features for speed
source $ZSH/oh-my-zsh.sh

# Load plugins conditionally
source $HOME/dotfiles/zsh/plugins/vi-mode.plugin.zsh

# Load syntax highlighting last for better performance
source $HOME/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Load custom configurations
source $HOME/dotfiles/zsh/keybindings.sh
source $HOME/dotfiles/zsh/plugins/fixls.zsh

# Load aliases and functions (these are fast)
source ~/dotfiles/zsh/alias.sh
source ~/dotfiles/zsh/functions.sh
# Load virtual environment functions (lazy load for speed)
source $HOME/dotfiles/zsh/venv.sh

#------------------------------------------
# Performance Optimizations
#------------------------------------------
# Skip global compinit on Ubuntu for faster startup
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    skip_global_compinit=1
fi

# Lazy load heavier plugins/functions when first used
if [[ -f ~/.zsh_suggestions_enabled ]]; then
    source $HOME/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

#------------------------------------------
# Plugin Setup
#------------------------------------------
# Optimized compinit - only run once per day or when needed
autoload -Uz compinit
_comp_files=(${ZDOTDIR:-$HOME}/.zcompdump(Nm-20))
if (( $#_comp_files )); then
    compinit -C
else
    compinit
    # Update timestamp
    touch ${ZDOTDIR:-$HOME}/.zcompdump
fi
unset _comp_files
# Plugin configuration
# autoload -U compinit
# plugins=(
# 	docker 
# )

# for plugin ($plugins); do
#     fpath=($HOME/dotfiles/zsh/plugins/oh-my-zsh/plugins/$plugin $fpath)
# done

# compinit


#------------------------------------------
# Key Bindings (Optimized)
#------------------------------------------
# Lazy load arrow key history search only when needed
_setup_history_search() {
    autoload -U up-line-or-beginning-search down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    
    [[ -n "${terminfo[kcuu1]}" ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
    [[ -n "${terminfo[kcud1]}" ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
}

# Setup history search on first use
_setup_history_search


if [[ -n "$VIRTUAL_ENV" ]]; then
    # echo "Activating virtual environment: $VIRTUAL_ENV"
    # echo "To switch environments, cd to your project and run: atv"
    source "$VIRTUAL_ENV/bin/activate"
fi
