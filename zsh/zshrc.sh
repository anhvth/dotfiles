ZSH_THEME="fino"
# Oh My Zsh theem
export ZSH="$HOME/dotfiles/zsh/plugins/oh-my-zsh"
source $ZSH/oh-my-zsh.sh


# Exports
export PATH=$PATH:$HOME/dotfiles/utils/ripgrep_all-v0.9.5-x86_64-unknown-linux-musl/
export VISUAL=vim
export PATH=$PATH:$HOME/dotfiles/utils
# Vars
HISTFILE=$HOME/.zsh_history
SAVEHIST=1000 
setopt inc_append_history # To save every command before it is executed 
setopt share_history #
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

source $HOME/dotfiles/zsh/plugins/vi-mode.plugin.zsh
source $HOME/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/dotfiles/zsh/keybindings.sh
source $HOME/dotfiles/zsh/plugins/fixls.zsh
# source $HOME/dotfiles/zsh/prompt.sh
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
export PATH=$PATH=$HOME/.local/bin
export PATH=$HOME/.fzf/bin/:$PATH
# Brew
if [ -d /opt/homebrew/bin ]; then
	export PATH=$PATH:/opt/homebrew/bin/
	export PATH=$PATH:/opt/homebrew/sbin/
else
	export PATH=$PATH:/usr/local/bin/
	export PATH=$PATH:/usr/local/sbin/
fi


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

if [ -n "$VIRTUAL_ENV" ] && [ -d "$VIRTUAL_ENV" ]; then
	source "$VIRTUAL_ENV/bin/activate"
	echo "✅ $(basename $VIRTUAL_ENV) virtual environment is active."
fi



#=====================
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(git)


# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
