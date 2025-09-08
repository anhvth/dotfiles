#!/usr/bin/env fish

# Fish keybindings configuration
# Porting key zsh keybindings to fish

#============================================================================
# Git Commands
#============================================================================

function git_prepare
    set current_line (commandline)
    if test -n "$current_line"
        commandline "git add -A && git commit -m \"$current_line\""
    else
        commandline "git add -A && git commit -v"
    end
    commandline -f execute
end

#============================================================================
# Command Editing and Execution
#============================================================================

function edit_and_run
    commandline "fc"
    commandline -f execute
end

function add_sudo
    set current_line (commandline)
    commandline "sudo $current_line"
    commandline -f end-of-line
end

function add_code_debug
    set current_line (commandline)
    commandline "code-debug \"$current_line\""
    commandline -f end-of-line
end

#============================================================================
# Utility Commands
#============================================================================

function ctrl_l_clear
    commandline "clear"
    commandline -f execute
end

function ctrl_n_ls
    commandline "ls"
    commandline -f execute
end

#============================================================================
# History Search
#============================================================================

function search_history_fzf
    set cmd (history | fzf --tac)
    if test -n "$cmd"
        commandline "$cmd"
        commandline -f end-of-line
    end
end

#============================================================================
# Autosuggestions Toggle
#============================================================================

function autosuggestions_toggle_func
    if test "$fish_autosuggestion_enabled" = "1"
        fish_disable_suggestions
    else
        fish_enable_suggestions
    end
end

#============================================================================
# Help Function
#============================================================================

function show_keybindings_help
    echo ""
    echo "Available key bindings:"
    echo "======================="
    echo "ctrl+g                          Git commit preparation"
    echo "ctrl+v                          Edit and rerun command"
    echo "ctrl+s                          Add sudo to the current command"
    echo "ctrl+o                          Add code-debug to the current command"
    echo "ctrl+l                          Clear screen"
    echo "ctrl+n                          List files"
    echo "ctrl+r                          Search history using fzf"
    echo "ctrl+a                          Toggle autosuggestions"
    echo "ctrl+h                          Show this help message"
    echo ""
    echo "Functions:"
    echo "=========="
    echo "set_env <varname> <value>       Set an environment variable in ~/.env"
    echo "unset_env <varname>             Unset an environment variable from ~/.env"
    echo ""
    commandline -f repaint
end

#============================================================================
# Key Binding Assignments
#============================================================================

# Bind functions to keys
bind \cg git_prepare
bind \cv edit_and_run
bind \cs add_sudo
bind \co add_code_debug
bind \cl ctrl_l_clear
bind \cn ctrl_n_ls
bind \cr search_history_fzf
bind \ca autosuggestions_toggle_func
bind \ch show_keybindings_help