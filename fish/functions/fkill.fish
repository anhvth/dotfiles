#!/usr/bin/env fish

function fkill
    set pid (ps -ef | sed 1d | fzf -m | awk '{print $2}')

    if test -n "$pid"
        echo $pid | xargs kill -(test -n "$argv[1]"; and echo "$argv[1]"; or echo "9")
    end
end