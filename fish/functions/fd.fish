#!/usr/bin/env fish

function fd
    set dir (find (test -n "$argv[1]"; and echo "$argv[1]"; or echo ".") -path '*/\.*' -prune -o -type d -print 2>/dev/null | fzf +m)
    if test -n "$dir"
        cd "$dir"
    end
end