#!/usr/bin/env fish

function tm
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
    
    set session (tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0)
    if test -n "$session"
        tmux $change -t "$session"
    else
        echo "No sessions found."
    end
end