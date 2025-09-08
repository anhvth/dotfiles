#!/usr/bin/env fish

function unset_env
    set varname $argv[1]

    if test -z "$varname"
        echo "Usage: unset_env <varname>"
        return 1
    end

    # Remove the entry for the variable
    if grep -q "^$varname=" ~/.env
        sed -i.bak "/^$varname=/d" ~/.env
        echo "Unset $varname from ~/.env"
    else
        echo "$varname not found in ~/.env"
    end
end