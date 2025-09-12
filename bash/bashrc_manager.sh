#!/bin/bash

# Bash Configuration Manager
# This script manages the main bash configuration and provides timing functionality

# Performance timing function
time_out () { 
    timeout "$1" "${@:2}"
}

# Source the main bash configuration
source "$HOME/dotfiles/bash/bashrc.sh"

# Add dotfiles bin to PATH
export PATH="$PATH:$HOME/dotfiles/bin"

# Bash completion
if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Custom bash completions directory
if [ -d "$HOME/.bash_completion.d" ]; then
    for file in "$HOME/.bash_completion.d"/*; do
        [ -r "$file" ] && source "$file"
    done
fi