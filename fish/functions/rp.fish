#!/usr/bin/env fish

function rp
    if test -z "$argv[1]"
        realpath (fzf)
    else
        realpath "$argv[1]"
    end
end