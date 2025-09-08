#!/usr/bin/env fish

function c
    if test -d "$argv[1]"
        cd "$argv[1]"
    else if test -f "$argv[1]"
        cd (dirname "$argv[1]")
    else
        set_color red
        echo "$argv[1] is not a valid file or directory"
        set_color normal
        return 1
    end
    set_color green
    echo "cd to "(pwd)
    set_color normal
    ls
end