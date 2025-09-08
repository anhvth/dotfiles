#============================================================================
# ZSH Performance Mode System
# Modes: fastest, balanced, full
# Use: zsh_toggle_mode to switch between modes
#============================================================================

# Start timing for performance measurement
ZSH_START_TIME=$(($(date +%s%N)/1000000))

# Determine current mode
ZSH_MODE="${ZSH_MODE:-balanced}"  # Default to balanced mode
ZSH_MODE_FILE="$HOME/.zsh_mode"

# Load saved mode if exists
[[ -f "$ZSH_MODE_FILE" ]] && ZSH_MODE="$(cat "$ZSH_MODE_FILE")"

#============================================================================
# Mode Toggle Function
#============================================================================
zsh_toggle_mode() {
    local current_mode="$ZSH_MODE"
    local new_mode
    
    case "$current_mode" in
        fastest)  new_mode="balanced" ;;
        balanced) new_mode="full" ;;
        full)     new_mode="fastest" ;;
        *)        new_mode="balanced" ;;
    esac
    
    echo "$new_mode" > "$ZSH_MODE_FILE"
    echo "🔄 Switching from $current_mode to $new_mode mode"
    echo "💡 Restart your terminal or run: exec zsh"
    
    export ZSH_MODE="$new_mode"
}

# Also provide direct mode setting
zsh_set_mode() {
    local mode="$1"
    if [[ "$mode" =~ ^(fastest|balanced|full)$ ]]; then
        echo "$mode" > "$ZSH_MODE_FILE"
        echo "✅ Set mode to: $mode"
        echo "💡 Restart your terminal or run: exec zsh"
        export ZSH_MODE="$mode"
    else
        echo "❌ Invalid mode. Use: fastest, balanced, or full"
        echo "Current mode: $ZSH_MODE"
    fi
}

#============================================================================
# FASTEST MODE - Minimal setup for maximum speed
#============================================================================
if [[ "$ZSH_MODE" == "fastest" ]]; then
    # Basic essentials only
    HISTFILE=$HOME/.zsh_history
    SAVEHIST=5000
    setopt inc_append_history share_history hist_ignore_dups
    stty -ixon
    
    # Essential environment
    export VISUAL=vim
    export FUNCNEST=100000
    
    # Minimal path setup
    typeset -U path PATH
    path=(
        $HOME/dotfiles/custom-tools
        $HOME/.local/bin
        $path
    )
    
    # Homebrew (macOS only)
    [[ "$OSTYPE" == "darwin"* && -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin $path)
    [[ "$OSTYPE" == "darwin"* && -d /usr/local/bin && ! -d /opt/homebrew/bin ]] && path=(/usr/local/bin $path)
    
    # Load only critical files
    [[ -r ~/.env ]] && source ~/.env
    [[ -f ~/dotfiles/zsh/alias.sh ]] && source ~/dotfiles/zsh/alias.sh
    
    # Ultra-minimal prompt
    PS1="⚡|%2~ %# "
    
    # Basic completion
    autoload -Uz compinit && compinit -C
    
    # Show startup time
    ZSH_END_TIME=$(($(date +%s%N)/1000000))
    ZSH_LOAD_TIME=$((ZSH_END_TIME - ZSH_START_TIME))
    echo "⚡ ZSH Fastest Mode Active (${ZSH_LOAD_TIME}ms)"
    return
fi

#============================================================================
# BALANCED MODE - Optimized oh-my-zsh with key features
#============================================================================
if [[ "$ZSH_MODE" == "balanced" ]]; then
    # Performance optimizations from the article
    DISABLE_AUTO_UPDATE="true"
    DISABLE_MAGIC_FUNCTIONS="true" 
    DISABLE_COMPFIX="true"
    DISABLE_UNTRACKED_FILES_DIRTY="true"
    
    # Basic configuration
    HISTFILE=$HOME/.zsh_history
    SAVEHIST=10000
    setopt inc_append_history share_history hist_ignore_dups
    stty -ixon
    
    export VISUAL=vim
    export FUNCNEST=100000
    export ZSH="$HOME/dotfiles/zsh/plugins/oh-my-zsh"
    
    # Optimized path setup
    typeset -U path PATH
    path=(
        $HOME/dotfiles/custom-tools
        $HOME/.local/bin
        $HOME/dotfiles/utils
        $HOME/dotfiles/bin
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
    
    # Smart completion initialization (once per day)
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
    
    # Theme setup
    ZSH_THEME="robbyrussell"
    
    # Essential plugins only
    plugins=(git)
    
    # Load oh-my-zsh
    source $ZSH/oh-my-zsh.sh
    
    # Load essential configurations
    [[ -r ~/.env ]] && source ~/.env
    [[ -f ~/dotfiles/zsh/alias.sh ]] && source ~/dotfiles/zsh/alias.sh
    [[ -f ~/dotfiles/zsh/functions.sh ]] && source ~/dotfiles/zsh/functions.sh
    [[ -f ~/dotfiles/zsh/keybindings.sh ]] && source ~/dotfiles/zsh/keybindings.sh
    
    # Load autosuggestions if enabled
    if [[ -f ~/.zsh_suggestions_enabled ]]; then
        source $HOME/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
        ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
        ZSH_AUTOSUGGEST_USE_ASYNC=1
    fi
    
    # Syntax highlighting last (for performance)
    [[ -f $HOME/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
        source $HOME/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    
    # Show startup time
    ZSH_END_TIME=$(($(date +%s%N)/1000000))
    ZSH_LOAD_TIME=$((ZSH_END_TIME - ZSH_START_TIME))
    echo "⚖️  ZSH Balanced Mode Active (${ZSH_LOAD_TIME}ms)"
    return
fi

#============================================================================
# FULL MODE - All features with performance optimizations
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



