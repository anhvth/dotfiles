#!/bin/bash

# Bash Keybindings Configuration
# Enhanced keyboard shortcuts for better bash experience

# Ensure we're in emacs mode (default for bash)
# set -o emacs

fzf-history-search() {
    local selected_command
    selected_command=$(history | fzf +s --tac --height 40% --reverse --border --ansi --preview 'echo {}' | sed 's/ *[0-9]* *//')
    if [ -n "$selected_command" ]; then
        READLINE_LINE=$selected_command
        READLINE_POINT=${#READLINE_LINE}
    fi
}

if command -v fzf >/dev/null 2>&1; then
    bind -x '"\C-r": fzf-history-search'
fi

# Ctrl+G git commit with vim
git-commit() {
    if [ -n "$(git status --porcelain)" ]; then
        if [ -n "$READLINE_LINE" ]; then
            git add -A && git commit -m "$READLINE_LINE"
            READLINE_LINE=""
            READLINE_POINT=0
        else
            git add -A && EDITOR=vim git commit -v
        fi
    else
        echo "No changes to commit."
    fi
}
bind -x '"\C-g": git-commit'