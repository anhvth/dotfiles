# Exports
export PATH=$PATH:$HOME/dotfiles/utils/ripgrep_all-v0.9.5-x86_64-unknown-linux-musl/
export VISUAL=vim
export PATH=$PATH:$HOME/dotfiles/utils
# Vars
HISTFILE=$HOME/.zsh_history
SAVEHIST=1000 
setopt inc_append_history # To save every command before it is executed 
setopt share_history # setopt inc_append_history

# git config --global push.default current

stty -ixon

if [ -f ~/.env ]; then
    source ~/.env
else
    echo "No ~/.env file found."
fi

source $HOME/dotfiles/zsh/venv.sh


autoload -U compinit
plugins=(
	docker
)

for plugin ($plugins); do
    fpath=($HOME/dotfiles/zsh/plugins/oh-my-zsh/plugins/$plugin $fpath)
done

compinit

source $HOME/dotfiles/zsh/plugins/oh-my-zsh/lib/history.zsh
source $HOME/dotfiles/zsh/plugins/oh-my-zsh/lib/key-bindings.zsh
source $HOME/dotfiles/zsh/plugins/oh-my-zsh/lib/completion.zsh
source $HOME/dotfiles/zsh/plugins/vi-mode.plugin.zsh
source $HOME/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/dotfiles/zsh/keybindings.sh
source $HOME/dotfiles/zsh/plugins/fixls.zsh
source $HOME/dotfiles/zsh/prompt.sh
source ~/dotfiles/zsh/alias.sh
source ~/dotfiles/zsh/functions.sh

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



export PATH=$PATH:$HOME/dotfiles/squashfs-root/usr/bin/
export PATH=$PATH:$HOME/dotfiles/tools/bin/
export PATH=$PATH:$HOME/dotfiles/bin/dist
export PATH=$PATH:$HOME/dotfiles/custom-tools/
export PATH=$PATH:$HOME/.local/bin
export PATH=$HOME/.fzf/bin/:$PATH


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

# Function to set aliases persistently
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

# Create a helper function to list all method
helper_zsh_methods() {
	# Print the usage of all methods per line
	echo "Usage:"
	echo "  set_env <varname> <value>       # Set an environment variable in ~/.env"
	echo "  unset_env <varname>            # Unset an environment variable from ~/.env"
	echo "  set_alias <aliasname> <command> # Set an alias in your alias file"
	echo "  venv_list                      # List all available Python virtual environments"
	echo "  venv_atv                       # Activate a selected Python virtual environment"
	echo "  venv_create <python-version> <venv-name>  # Create a new Python virtual environment"
	echo "  venv_remove                    # Remove a selected Python virtual environment"
	echo "  venv                           # Set and activate the default Python virtual environment"
	echo "  atv [venv-name]                # Activate the default or a specific Python virtual environment"
}