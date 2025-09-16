#============================================================================
# ZSH Configuration - Full Mode
#============================================================================

# Start timing for performance measurement
ZSH_START_TIME=$(($(date +%s%N)/1000000))

#============================================================================
# Auto-activate uv environment
#============================================================================

# Function to activate uv environment if available
auto_activate_uv() {
    # Check if we have a pyproject.toml or uv.lock in current directory
    if [[ -f "pyproject.toml" || -f "uv.lock" ]]; then
        local python_exec=$(uv run python -c "import sys; print(sys.executable)" 2>/dev/null)
        if [[ "$python_exec" == *".venv"* ]]; then
            local activate_path="${python_exec%python*}activate"
            if [[ -f "$activate_path" ]]; then
                source "$activate_path"
            fi
        fi
    fi
}

# Hook into directory changes
# chpwd() {
#     auto_activate_uv
# }

# Activate on shell startup if in a uv project

#============================================================================
# Python command fallback
#============================================================================

# python() {
#     if command python "$@" 2>/dev/null; then
#         :
#     else
#         uv run python "$@"
#     fi
# }
# pip() {
#     if command pip "$@" 2>/dev/null; then
#         :
#     else
#         uv run pip "$@"
#     fi
# }

#============================================================================
# Full Mode Configuration - All features with performance optimizations
#============================================================================
# Performance optimizations
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
COMPLETION_WAITING_DOTS="false"

# Basic Configuration
HISTFILE=$HOME/.zsh_history
SAVEHIST=10000
setopt inc_append_history share_history hist_ignore_dups
stty -ixon

export VISUAL=vim
export FUNCNEST=100000
export ZSH="$HOME/dotfiles/zsh/plugins/oh-my-zsh"

# Full path configuration
typeset -U path PATH
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

# Optimized completion initialization
autoload -Uz compinit
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version
    if [[ $(date +'%j') != $(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null) ]]; then
        compinit
    else
        compinit -C
    fi
else
    # Linux version  
    if [[ $(date +'%j') != $(stat -c '%Y' ~/.zcompdump 2>/dev/null | xargs -I{} date -d @{} +'%j' 2>/dev/null) ]]; then
        compinit
    else
        compinit -C
    fi
fi

# Theme
ZSH_THEME="robbyrussell"

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Load all configurations
[[ -r ~/.env ]] && source ~/.env
[[ -f $HOME/dotfiles/zsh/plugins/vi-mode.plugin.zsh ]] && source $HOME/dotfiles/zsh/plugins/vi-mode.plugin.zsh
[[ -f $HOME/dotfiles/zsh/keybindings.sh ]] && source $HOME/dotfiles/zsh/keybindings.sh
[[ -f $HOME/dotfiles/zsh/plugins/fixls.zsh ]] && source $HOME/dotfiles/zsh/plugins/fixls.zsh
[[ -f ~/dotfiles/zsh/alias.sh ]] && source ~/dotfiles/zsh/alias.sh
[[ -f ~/dotfiles/zsh/functions.sh ]] && source ~/dotfiles/zsh/functions.sh
if typeset -f auto_atv_startup >/dev/null; then
    auto_atv_startup
fi

# Autosuggestions with performance settings
if [[ -f $HOME/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source $HOME/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
    ZSH_AUTOSUGGEST_USE_ASYNC=1
fi

# Syntax highlighting (always last for performance)
[[ -f $HOME/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source $HOME/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Optimized history search
_setup_history_search() {
    autoload -U up-line-or-beginning-search down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    
    [[ -n "${terminfo[kcuu1]}" ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
    [[ -n "${terminfo[kcud1]}" ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
}
_setup_history_search

# Show startup time
ZSH_END_TIME=$(($(date +%s%N)/1000000))
ZSH_LOAD_TIME=$((ZSH_END_TIME - ZSH_START_TIME))
echo "🚀 ZSH Full Mode Active (${ZSH_LOAD_TIME}ms)"
