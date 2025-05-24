#------------------------------------------
# Theme and Oh-My-Zsh Setup
#------------------------------------------

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
#== Auto suggess

# unset zle_bracketed_paste
# source $HOME/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# pasteinit() {
#   zle autosuggest-disable
# }

# pastefinish() {
#   zle autosuggest-enable
# }

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
# Plugin configuration
autoload -U compinit
plugins=(
	docker 
)

for plugin ($plugins); do
    fpath=($HOME/dotfiles/zsh/plugins/oh-my-zsh/plugins/$plugin $fpath)
done

compinit

#------------------------------------------
# Functions
#------------------------------------------
# Environment variable management
set_env() {
	local varname=$1
	local value=$2

	if [ -z "$varname" ] || [ -z "$value" ]; then
		echo "Usage: set_env <varname> <value>"
		return 1
	fi

	# Remove existing entry for the variable
	if grep -q "^${varname}=" ~/.env; then
		sed -i.bak "/^${varname}=/d" ~/.env
	fi

	# Add the new value
	echo "${varname}=${value}" >> ~/.env
	echo "Set ${varname}=${value} in ~/.env"
}

unset_env() {
	local varname=$1

	if [ -z "$varname" ]; then
		echo "Usage: unset_env <varname>"
		return 1
	fi

	# Remove the entry for the variable
	if grep -q "^${varname}=" ~/.env; then
		sed -i.bak "/^${varname}=/d" ~/.env
		echo "Unset ${varname} from ~/.env"
	else
		echo "${varname} not found in ~/.env"
	fi
}

# Alias management
set_alias() {
	local aliasname=$1
	local command=$2

	if [ -z "$aliasname" ] || [ -z "$command" ]; then
		echo "Usage: set_alias <aliasname> <command>"
		return 1
	fi

	local alias_file="$HOME/dotfiles/zsh/alias.sh"
	
	# Remove existing alias if it exists
	if grep -q "^alias ${aliasname}=" "$alias_file"; then
		sed -i.bak "/^alias ${aliasname}=/d" "$alias_file"
	fi

	# Add the new alias
	echo "alias ${aliasname}=\"${command}\"" >> "$alias_file"
	
	# Source the alias file to make it immediately available
	source "$alias_file"
	
	echo "Set alias ${aliasname}=\"${command}\" in $alias_file"
}

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

