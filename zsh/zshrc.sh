#------------------------------------------
# Theme and Oh-My-Zsh Setup
#------------------------------------------
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"


# reset

ZSH_THEME="muse"
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
# Dotfiles utilities
export PATH=$PATH:$HOME/dotfiles/utils/ripgrep_all-v0.9.5-x86_64-unknown-linux-musl/
export PATH=$PATH:$HOME/dotfiles/utils
export PATH=$PATH:$HOME/dotfiles/squashfs-root/usr/bin/
export PATH=$PATH:$HOME/dotfiles/tools/bin/
export PATH=$PATH:$HOME/dotfiles/bin/dist
export PATH=$PATH:$HOME/dotfiles/custom-tools/

# Local binaries
export PATH=$PATH=$HOME/.local/bin

# FZF
export PATH=$HOME/.fzf/bin/:$PATH

# Homebrew
if [[ "$OSTYPE" == "darwin"* ]]; then
	if [ -d /opt/homebrew/bin ]; then
		export PATH=$PATH:/opt/homebrew/bin/
		export PATH=$PATH:/opt/homebrew/sbin/
	else
		export PATH=$PATH:/usr/local/bin/
		export PATH=$PATH:/usr/local/sbin/
	fi
fi

#------------------------------------------
# Environment and Config Sources
#------------------------------------------
# Source environment variables
if [ -f ~/.env ]; then
    source ~/.env
else
    echo "No ~/.env file found."
fi

# Source configuration files

source $ZSH/oh-my-zsh.sh
source $HOME/dotfiles/zsh/plugins/vi-mode.plugin.zsh
source $HOME/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/dotfiles/zsh/keybindings.sh
source $HOME/dotfiles/zsh/plugins/fixls.zsh

#===
source ~/dotfiles/zsh/alias.sh
source ~/dotfiles/zsh/functions.sh
source $HOME/dotfiles/zsh/venv.sh

# Skip global compinit on Ubuntu
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	skip_global_compinit=1
fi




#------------------------------------------
# Plugin Setup
#------------------------------------------
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
    compinit
else
    compinit -C
fi
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
# Key Bindings
#------------------------------------------
# Fix for arrow-key searching
# start typing + [Up-Arrow] - fuzzy find history forward
if [[ "${terminfo[kcuu1]}" != "" ]]; then
	autoload -U up-line-or-beginning-search
	zle -N up-line-or-beginning-search
	bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
fi
# start typing + [Down-Arrow] - fuzzy find history backward
if [[ "${terminfo[kcud1]}" != "" ]]; then
	autoload -U down-line-or-beginning-search
	zle -N down-line-or-beginning-search
	bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
fi

#------------------------------------------
# Virtual Environment
#------------------------------------------
source $HOME/dotfiles/zsh/venv.sh
# if [ -f "$VIRTUAL_ENV" ]; then
#     source $VIRTUAL_ENV
# fi
alias atv="auto_source"


# PS1 insert machine name
PS1=$"cname|$PS1"

export PATH=$PATH:~/dotfiles/custom-tools