#!/usr/bin/env fish

function set_env
    set varname $argv[1]
    set value $argv[2]

    if test -z "$varname" -o -z "$value"
        echo "Usage: set_env <varname> <value>"
        return 1
    end

    # Remove existing entry for the variable
    if grep -q "^$varname=" ~/.env
        sed -i.bak "/^$varname=/d" ~/.env
    end

    # Add the new value
    echo "$varname=$value" >> ~/.env
    echo "Set $varname=$value in ~/.env"
end