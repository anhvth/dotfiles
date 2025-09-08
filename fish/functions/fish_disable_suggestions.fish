#!/usr/bin/env fish

function fish_disable_suggestions
    echo "🚫 Disabling autosuggestions..."
    rm -f ~/.fish_suggestions_enabled
    set -g fish_autosuggestion_enabled 0
    echo "✅ Autosuggestions disabled!"
end