# ------------------------------
# Directory Navigation
# ------------------------------


# ------------------------------
# Git Commands
# ------------------------------

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

# ------------------------------
# Command Editing and Execution
# ------------------------------

# Edit and rerun command
function edit_and_run() {
	BUFFER="fc"
	zle accept-line
}
zle -N edit_and_run
bindkey "^v" edit_and_run

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

# ------------------------------
# Utility Commands
# ------------------------------

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

# ------------------------------
# File Transfer
# ------------------------------

# Pull file using rsync
# function rs_pull() {
# 	hostname=$(awk '/Host / {print $2}' ~/.ssh/config | fzf)
# 	BUFFER="rs $hostname:/"
# 	zle end-of-line
# }
# zle -N rs_pull
# bindkey "^y" rs_pull

# ------------------------------
# Remote Setup
# ------------------------------

# Run remote setup script
# function remote_config() {
# 	BUFFER="~/.remote_setup.sh"
# 	zle accept-line
# }
# zle -N remote_config
# bindkey "^z" remote_config

# ------------------------------
# History Search
# ------------------------------

# Search history using fzf
function search_history() {
	if command -v tac &>/dev/null; then
		BUFFER=$(history | tac | fzf | awk '{$1=""; print substr($0,2)}')
	else
		BUFFER=$(history | tail -r | fzf | awk '{$1=""; print substr($0,2)}')
	fi
	zle end-of-line
}
zle -N search_history
bindkey "^r" search_history

# ------------------------------
# Echo Helper
# ------------------------------

# Echo a message
HELPER_MESSAGES=(
  "ctrl+g:Git commit preparation"
  "ctrl+v:Edit and rerun command"
  "ctrl+s:Add sudo to the current command"
  "ctrl+o:Add code-debug to the current command"
  "ctrl+l:Clear screen"
  "ctrl+n:List files"
  "ctrl+r:Search history using fzf"
  "ctrl+shift+a:Toggle autosuggestions on/off"
  "ctrl+h:Show this help message"
  ""
  "set_env <varname> <value>:Set an environment variable in ~/.env"
  "unset_env <varname>:Unset an environment variable from ~/.env"
  "set_alias <aliasname> <command>:Set an alias in your alias file"
)

function show_keybindings_help() {
  echo "\nAvailable key bindings:"
  echo "======================="
  for msg in "${HELPER_MESSAGES[@]}"; do
    if [ -z "$msg" ]; then
      echo ""
    elif [[ "$msg" == *":"* ]]; then
      key="${msg%%:*}"
      description="${msg#*:}"
      printf "%-40s %s\n" "$key" "$description"
    else
      echo "$msg"
    fi
  done
  echo ""
  zle redisplay
}
zle -N show_keybindings_help
bindkey "^h" show_keybindings_help


# ------------------------------
# Autosuggestions Toggle
# ------------------------------

# Toggle autosuggestions - Ctrl+Shift+A
function toggle_autosuggestions_widget() {
  autosuggestions_toggle
  zle reset-prompt
}
zle -N toggle_autosuggestions_widget
bindkey "^a" toggle_autosuggestions_widget

# Pytools and enter
function pytools_and_enter() {
  BUFFER="pytools"
  zle accept-line
}
zle -N pytools_and_enter
bindkey "^p" pytools_and_enter