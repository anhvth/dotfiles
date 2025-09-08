#!/usr/bin/env fish

function rs-git-sync
    set x "rsync -avzhe ssh --progress --filter=':- .gitignore' $argv[1] $argv[2] --delete"
    watch $x
end