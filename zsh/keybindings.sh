# Up one directory
function up_widget() {
	BUFFER="cd .."
	zle accept-line
}
zle -N up_widget
bindkey "^k" up_widget

# Git commit preparation
function git_prepare() {
	if [ -n "$BUFFER" ]; then
		BUFFER="git add -A && git commit -m \"$BUFFER\""
	else
		BUFFER="git add -A && git commit -v"
	fi
	zle accept-line
}
zle -N git_prepare
bindkey "^g" git_prepare

# Git sync
function git_sync() {
	BUFFER="git pull && git add -A && git commit -m 'code sync'"
	zle accept-line
}
zle -N git_sync
bindkey "^p" git_sync

# Edit and rerun command
function edit_and_run() {
	BUFFER="fc"
	zle accept-line
}
zle -N edit_and_run
bindkey "^v" edit_and_run

# Clear screen
function ctrl_l() {
	BUFFER="clear"
	zle accept-line
}
zle -N ctrl_l
bindkey "^l" ctrl_l

# List files
function ctrl_n() {
	BUFFER="ls"
	zle accept-line
}
zle -N ctrl_n
bindkey "^n" ctrl_n

# Add sudo to the current command
function add_sudo() {
	BUFFER="sudo $BUFFER"
	zle end-of-line
}
zle -N add_sudo
bindkey "^s" add_sudo

# Add code-debug to the current command
function add_code_debug() {
	BUFFER="code-debug \"$BUFFER\""
	zle end-of-line
}
zle -N add_code_debug
bindkey "^o" add_code_debug

# Push file using rsync
function rs_push() {
	filename=$(ls | fzf)
	hostname=$(awk '/Host / {print $2}' ~/.ssh/config | fzf)
	BUFFER="rs $filename $hostname:/"
	zle end-of-line
}
zle -N rs_push
bindkey "^u" rs_push

# Pull file using rsync
function rs_pull() {
	hostname=$(awk '/Host / {print $2}' ~/.ssh/config | fzf)
	BUFFER="rs $hostname:/"
	zle end-of-line
}
zle -N rs_pull
bindkey "^y" rs_pull

# Run remote setup script
function remote_config() {
	BUFFER="~/.remote_setup.sh"
	zle accept-line
}
zle -N remote_config
bindkey "^z" remote_config
