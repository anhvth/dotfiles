#!/usr/bin/env fish

#============================================================================
# Fish Performance Mode System
# Modes: fastest, balanced, full
# Use: fish_toggle_mode to switch between modes
#============================================================================

# Start timing for performance measurement
if command -v gdate > /dev/null
    # Use GNU date if available (via homebrew coreutils)
    set -g FISH_START_TIME (gdate +%s%3N)
else
    # Fallback to seconds for macOS built-in date
    set -g FISH_START_TIME (date +%s)000
end

# Determine current mode
set -g FISH_MODE "balanced"  # Default to balanced mode
set -g FISH_MODE_FILE "$HOME/.fish_mode"

# Load saved mode if exists
if test -f "$FISH_MODE_FILE"
    set FISH_MODE (cat "$FISH_MODE_FILE")
end

#============================================================================
# Mode Toggle Functions
#============================================================================
function fish_toggle_mode
    set current_mode "$FISH_MODE"
    
    switch "$current_mode"
        case fastest
            set new_mode "balanced"
        case balanced
            set new_mode "full"
        case full
            set new_mode "fastest"
        case '*'
            set new_mode "balanced"
    end
    
    echo "$new_mode" > "$FISH_MODE_FILE"
    echo "🔄 Switching from $current_mode to $new_mode mode"
    echo "💡 Restart your terminal or run: exec fish"
    
    set -gx FISH_MODE "$new_mode"
end

function fish_set_mode
    set mode "$argv[1]"
    if string match -qr "^(fastest|balanced|full)\$" "$mode"
        echo "$mode" > "$FISH_MODE_FILE"
        echo "✅ Set mode to: $mode"
        echo "💡 Restart your terminal or run: exec fish"
        set -gx FISH_MODE "$mode"
    else
        echo "❌ Invalid mode. Use: fastest, balanced, or full"
        echo "Current mode: $FISH_MODE"
    end
end

function convert_env_to_fish
    if test -r ~/.env
        echo "🔄 Converting ~/.env to Fish format..."
        echo "# Fish-compatible environment variables" > ~/.env.fish
        echo "# Generated from ~/.env on "(date) >> ~/.env.fish
        echo "" >> ~/.env.fish
        
        # Convert each non-comment, non-empty line
        grep -v '^#' ~/.env | grep -v '^$' | while read -l line
            set var_name (echo $line | cut -d= -f1)
            set var_value (echo $line | cut -d= -f2- | sed 's/^"//' | sed 's/"$//')
            echo "set -gx $var_name \"$var_value\"" >> ~/.env.fish
        end
        
        echo "✅ Created ~/.env.fish"
        echo "💡 You can now remove ~/.env if you want to use only Fish format"
    else
        echo "❌ ~/.env file not found"
    end
end

#============================================================================
# FASTEST MODE - Minimal setup for maximum speed
#============================================================================
if test "$FISH_MODE" = "fastest"
    # Basic essentials only
    set -g fish_greeting ""
    
    # Essential environment
    set -gx VISUAL vim
    set -gx EDITOR vim
    
    # Minimal path setup
    fish_add_path $HOME/dotfiles/custom-tools
    fish_add_path $HOME/.local/bin
    
    # Homebrew (macOS only)
    if test (uname -s) = "Darwin"
        if test -d /opt/homebrew/bin
            fish_add_path /opt/homebrew/bin
            fish_add_path /opt/homebrew/sbin
        else if test -d /usr/local/bin
            fish_add_path /usr/local/bin
            fish_add_path /usr/local/sbin
        end
    end
    
    # Load only critical files
    # Load environment variables (convert bash format to fish format if needed)
    if test -r ~/.env
        # Convert bash-style env vars to fish format and source them
        if test -r ~/.env.fish
            source ~/.env.fish
        else
            # Create fish-compatible version from bash .env file
            grep -v '^#' ~/.env | grep -v '^$' | sed 's/^/set -gx /' | sed 's/=/  /' | source
        end
    end
    test -f ~/dotfiles/fish/aliases.fish && source ~/dotfiles/fish/aliases.fish
    
    # Show startup time
    if command -v gdate > /dev/null
        set FISH_END_TIME (gdate +%s%3N)
    else
        set FISH_END_TIME (date +%s)000
    end
    set FISH_LOAD_TIME (math "$FISH_END_TIME - $FISH_START_TIME")
    echo "⚡ Fish Fastest Mode Active ($FISH_LOAD_TIME ms)"

else if test "$FISH_MODE" = "balanced"
    # Basic configuration
    set -g fish_greeting ""
    
    set -gx VISUAL vim
    set -gx EDITOR vim
    
    # Optimized path setup
    fish_add_path $HOME/dotfiles/custom-tools
    fish_add_path $HOME/.local/bin
    fish_add_path $HOME/dotfiles/utils
    fish_add_path $HOME/dotfiles/bin
    
    # Homebrew paths (macOS only)
    if string match -q "darwin*" "$OSTYPE"
        if test -d /opt/homebrew/bin
            fish_add_path /opt/homebrew/bin
            fish_add_path /opt/homebrew/sbin
        else if test -d /usr/local/bin
            fish_add_path /usr/local/bin
            fish_add_path /usr/local/sbin
        end
    end
    
    # Load essential configurations
    # Load environment variables (convert bash format to fish format if needed)
    if test -r ~/.env
        # Convert bash-style env vars to fish format and source them
        if test -r ~/.env.fish
            source ~/.env.fish
        else
            # Create fish-compatible version from bash .env file
            grep -v '^#' ~/.env | grep -v '^$' | sed 's/^/set -gx /' | sed 's/=/  /' | source
        end
    end
    test -f ~/dotfiles/fish/aliases.fish && source ~/dotfiles/fish/aliases.fish
    test -f ~/dotfiles/fish/keybindings.fish && source ~/dotfiles/fish/keybindings.fish
    
    # Load autosuggestions if enabled
    if test -f ~/.fish_suggestions_enabled
        # Fish has built-in autosuggestions, just configure them
        set -g fish_autosuggestion_enabled 1
    end
    
    # Show startup time
    if command -v gdate > /dev/null
        set FISH_END_TIME (gdate +%s%3N)
    else
        set FISH_END_TIME (date +%s)000
    end
    set FISH_LOAD_TIME (math "$FISH_END_TIME - $FISH_START_TIME")
    echo "⚖️  Fish Balanced Mode Active ($FISH_LOAD_TIME ms)"

else
    # FULL MODE - All features with performance optimizations
# Basic Configuration
set -g fish_greeting ""

set -gx VISUAL vim
set -gx EDITOR vim

# Full path configuration
fish_add_path $HOME/dotfiles/utils/ripgrep_all-v0.9.5-x86_64-unknown-linux-musl
fish_add_path $HOME/dotfiles/utils
fish_add_path $HOME/dotfiles/squashfs-root/usr/bin
fish_add_path $HOME/dotfiles/tools/bin
fish_add_path $HOME/dotfiles/bin/dist
fish_add_path $HOME/dotfiles/custom-tools
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.fzf/bin

# Homebrew paths (macOS only)
if test (uname -s) = "Darwin"
    if test -d /opt/homebrew/bin
        fish_add_path /opt/homebrew/bin
        fish_add_path /opt/homebrew/sbin
    else if test -d /usr/local/bin
        fish_add_path /usr/local/bin
        fish_add_path /usr/local/sbin
    end
end

# Load all configurations
# Load environment variables (convert bash format to fish format if needed)
if test -r ~/.env
    # Convert bash-style env vars to fish format and source them
    if test -r ~/.env.fish
        source ~/.env.fish
    else
        # Create fish-compatible version from bash .env file
        grep -v '^#' ~/.env | grep -v '^$' | sed 's/^/set -gx /' | sed 's/=/  /' | source
    end
end
test -f ~/dotfiles/fish/aliases.fish && source ~/dotfiles/fish/aliases.fish
test -f ~/dotfiles/fish/keybindings.fish && source ~/dotfiles/fish/keybindings.fish

# Enable autosuggestions
set -g fish_autosuggestion_enabled 1

# Show startup time
if command -v gdate > /dev/null
    set FISH_END_TIME (gdate +%s%3N)
else
    set FISH_END_TIME (date +%s)000
end
set FISH_LOAD_TIME (math "$FISH_END_TIME - $FISH_START_TIME")
echo "🚀 Fish Full Mode Active ($FISH_LOAD_TIME ms)"

# Fish-specific configurations
set -g fish_color_command blue
set -g fish_color_param cyan
set -g fish_color_redirection magenta
set -g fish_color_comment red
set -g fish_color_error red --bold
set -g fish_color_escape yellow
set -g fish_color_operator green
set -g fish_color_quote yellow
set -g fish_color_autosuggestion 555

# History configuration
set -g fish_history_max 10000

# Disable fish greeting in all modes after first setup
set -g fish_greeting ""

end  # End of mode conditional block
