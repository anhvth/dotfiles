#!/usr/bin/env fish

function tm
    # Ensure tmux is available
    if not type -q tmux
        echo "tm: 'tmux' is not installed or not in PATH."
        echo "    Install on macOS with: brew install tmux"
        return 127
    end

    # Detect fzf availability (optional convenience)
    set -l have_fzf 1
    if not type -q fzf
        set have_fzf 0
    end

    if test -n "$TMUX"
        set change "switch-client"
    else
        set change "attach-session"
    end
    
    if test -n "$argv[1]"
        tmux $change -t "$argv[1]" 2>/dev/null; or begin
            tmux new-session -d -s "$argv[1]"
            tmux $change -t "$argv[1]"
        end
        return
    end
    
    set -l session ""
    if test $have_fzf -eq 1
        set session (tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0)
    else
        set -l sessions (tmux list-sessions -F "#{session_name}" 2>/dev/null)
        if test (count $sessions) -eq 0
            echo "No sessions found."
            return 0
        end
        echo "Available tmux sessions:"
        printf '%s\n' $sessions
        read -P "Enter session name (or press Enter to cancel): " session
    end

    if test -n "$session"
        tmux $change -t "$session"
    else
        echo "No sessions selected."
    end
end