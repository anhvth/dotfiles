#!/usr/bin/env fish

function update_dotfiles
    # Update the dotfiles repository
    cd ~/dotfiles && git pull
    echo "Successfully updated dotfiles repository."
    source ~/.config/fish/config.fish
end