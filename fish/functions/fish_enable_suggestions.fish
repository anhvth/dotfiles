#!/usr/bin/env fish

function fish_enable_suggestions
    echo "💡 Enabling autosuggestions..."
    if not test -f ~/.fish_suggestions_enabled
        touch ~/.fish_suggestions_enabled
        set -g fish_autosuggestion_enabled 1
        echo "✅ Autosuggestions enabled!"
    else
        echo "ℹ️  Autosuggestions already enabled"
    end
end