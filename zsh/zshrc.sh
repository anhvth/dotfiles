
# Exports
    export PATH=$PATH:$HOME/dotfiles/utils/ripgrep_all-v0.9.5-x86_64-unknown-linux-musl/
	export VISUAL=vim
    export PATH=$PATH:$HOME/dotfiles/utils
# Vars
	HISTFILE=$HOME/.zsh_history
	SAVEHIST=1000 
	setopt inc_append_history # To save every command before it is executed 
	setopt share_history # setopt inc_append_history

	git config --global push.default current

# Aliases
	mkdir -p /tmp/log
	
	stty -ixon


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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


export PATH=$PATH:$HOME/dotfiles/squashfs-root/usr/bin/
export PATH=$PATH:$HOME/dotfiles/tools/bin/
export PATH=$PATH:$HOME/dotfiles/custom-tools/


