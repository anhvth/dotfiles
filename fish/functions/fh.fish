#!/usr/bin/env fish

function fh
    # This function uses fzf to select a command from the history and executes it.
    set cmd (history | fzf +s --tac | string replace -r '^ *[0-9]*\*? *' '')
    if test -n "$cmd"
        eval $cmd
    end
end