# up
	function up_widget() {
		BUFFER="cd .."
		zle accept-line
	}
	zle -N up_widget
	bindkey "^k" up_widget

# git
	function git_prepare() {
		if [ -n "$BUFFER" ];
			then
				BUFFER="git add -A && git commit -m \"$BUFFER\""
		fi

		if [ -z "$BUFFER" ];
			then
				BUFFER="git add -A && git commit -v && git push"
				# BUFFER="git add -A && git commit -v"
		fi
				
		zle accept-line
	}
	zle -N git_prepare
	bindkey "^g" git_prepare

# home
	#function goto_home() { 
	#	BUFFER="cd ~/"$BUFFER
	#	zle end-of-line
	#	zle accept-line
	#}
	#zle -N goto_home
	#bindkey "^h" goto_home
# search command
    # function search_cmd(){
    #     BUFFER="history > .history && python ~/dotfiles/tools/history_grep.py | fzf)"
	# 	zle accept-line
    # }
	# zle -N search_cmd
	# bindkey "^f" search_cmd
        

# Edit and rerun
	function edit_and_run() {
		BUFFER="fc"
		zle accept-line
	}
	zle -N edit_and_run
	bindkey "^v" edit_and_run

# LS
	function ctrl_l() {
		BUFFER="clear"
		zle accept-line
	}
	zle -N ctrl_l
	bindkey "^l" ctrl_l

# neovim-terminal
	function ctrl_n() {
		BUFFER="ls"
		zle accept-line
	}
	zle -N ctrl_n
	bindkey "^n" ctrl_n
# Enter
	function enter_line() {
		zle accept-line
	}
	zle -N enter_line
	bindkey "^o" enter_line

# Sudo
	function add_sudo() {
		BUFFER="sudo "$BUFFER
		zle end-of-line
	}
	zle -N add_sudo
	bindkey "^s" add_sudo

    function ctrl_e(){
        BUFFER="sh run.sh"
        zle accept-line
    }
    zle -N ctrl_e
    bindkey "^e" ctrl_e



# Git-rs
	function add_gitrs() {
        BUFFER="rs $BUFFER:$(pwd)/ $(pwd)/"
		zle end-of-line
	}
	zle -N add_gitrs
	bindkey "^u" add_gitrs
