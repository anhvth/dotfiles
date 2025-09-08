#!/usr/bin/env fish

function fif
    set search_terms (string join " " $argv)
    set _file (grep --line-buffered --color=never -I -r "$search_terms" * | fzf)
    set -g _file $_file
    set file (echo "$_file" | string split ":" | head -n1)
    echo $file
end