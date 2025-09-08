#!/usr/bin/env fish

function my-autossh
    set hostname "$argv[1]"
    set force_restart true
    
    # check if restart is forced
    if test "$force_restart" = true
        pkill -f "autossh.*$hostname"
    end

    if test -z "$hostname"
        echo "Usage: my-autossh <hostname>"
        return 1
    end

    # Check if autossh tunnel is already running
    if pgrep -f "autossh.*$hostname" > /dev/null
        echo "autossh connection to $hostname is already running."
    else
        echo "Starting autossh connection to $hostname..."
        autossh -f -M 0 -N "$hostname"

        if test $status -eq 0
            echo "autossh connection to $hostname started successfully."
        else
            echo "Failed to start autossh connection to $hostname."
        end
    end
end