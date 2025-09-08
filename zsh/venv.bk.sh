### Expected behavior:
# - create_env <env_name> should create a new virtual environment, and do 
# - atv <env_name> should activate the specified virtual environment


### VENV - Optimized version with comprehensive environment management
export PATH=$PATH:$HOME/.local/bin/
# Helper function to set environment variables
set_env() {
    export "$1"="$2"
}

# Install uv package manager if not already installed
install_uv(){
    if command -v uv >/dev/null 2>&1; then
        echo "uv is already installed"
        uv --version
        return 0
    fi
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Source the shell profile to make uv available
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi
    
    # Check if installation was successful
    if command -v uv >/dev/null 2>&1; then
        echo "uv installed successfully!"
        uv --version
    else
        echo "uv installation completed, but command not found in PATH."
        echo "You may need to restart your shell or run: source ~/.zshrc"
        echo "uv is typically installed to ~/.cargo/bin/uv"
    fi
}



# Color helpers
c_red()   { echo -e "\033[31m$1\033[0m"; }
c_green() { echo -e "\033[32m$1\033[0m"; }
c_yellow(){ echo -e "\033[33m$1\033[0m"; }
c_blue()  { echo -e "\033[34m$1\033[0m"; }

venv-create() {
    local venv_name=$1; shift
    local venv_path="$HOME/.venvs/$venv_name"
    local extra=("$@")

    [[ -z "$venv_name" ]] && c_red "Usage: venv-create <name> [--python=3.12]" && return 1
    [[ ! "$venv_name" =~ ^[a-zA-Z0-9_-]+$ ]] && c_red "Invalid name: $venv_name" && return 1
    
    # Check if venv already exists in ~/.venvs
    if [[ -d "$venv_path" ]]; then
        c_yellow "Virtual environment already exists: $venv_path"
        printf "Overwrite $venv_path? [y/N] "
        read -r _c
        case "$_c" in
            y|Y)
                c_yellow "Removing existing $venv_path"
                /bin/rm -rf "$venv_path"
                ;;
            *)
                c_yellow "Cancelled. Not overwriting $venv_path."
                return 1
                ;;
        esac
    fi
    
    # Check if environment name already exists in global tracking
    local global_env_file="$HOME/.venv_all_env"
    if [[ -f "$global_env_file" ]]; then
        local existing_path
        existing_path=$(awk -v env="$venv_name" '$1==env{print $2}' "$global_env_file")
        if [[ -n "$existing_path" ]]; then
            local existing_venv_dir=$(dirname "$(dirname "$existing_path")")
            c_yellow "Environment name '$venv_name' already tracked at: $existing_venv_dir"
            printf "Overwrite tracking for '%s'? [y/N] " "$venv_name"
            read -r _c
            case "$_c" in
                y|Y)
                    c_yellow "Will overwrite tracking for: $venv_name"
                    # Remove from global tracking (will be re-added later)
                    grep -v "^$venv_name " "$global_env_file" > "$global_env_file.tmp" && mv "$global_env_file.tmp" "$global_env_file"
                    ;;
                *)
                    c_yellow "Cancelled. Environment name already in use."
                    return 1
                    ;;
            esac
        fi
    fi
    
    c_blue "Creating venv: $venv_name at $venv_path ${extra[*]}"

    # Try uv first
    local uv_path
    uv_path=$(command -v uv 2>/dev/null)
    if [[ -n "$uv_path" && -x "$uv_path" ]]; then
        c_blue "Found uv, attempting to create venv..."
        if "$uv_path" venv "${extra[@]}" "$venv_path"; then
            c_green "Created with uv: $venv_path"
            
            # Register in global tracking
            local activate_script="$venv_path/bin/activate"
            mkdir -p "$(dirname "$global_env_file")"
            echo "$venv_name $activate_script" >> "$global_env_file"
            c_blue "Registered $venv_name in global tracking"
            
            venv-activate "$venv_name"
            return 0
        else
            c_yellow "uv failed, trying to install Python and retry..."
            if "$uv_path" python install && "$uv_path" venv "${extra[@]}" "$venv_path"; then
                c_green "Created with uv (after Python install): $venv_path"
                
                # Register in global tracking
                local activate_script="$venv_path/bin/activate"
                mkdir -p "$(dirname "$global_env_file")"
                echo "$venv_name $activate_script" >> "$global_env_file"
                c_blue "Registered $venv_name in global tracking"
                
                venv-activate "$venv_name"
                return 0
            fi
        fi
    fi
    # Try python3
    local py3_path
    py3_path=$(command -v python3 2>/dev/null)
    if [[ -n "$py3_path" && -x "$py3_path" ]]; then
        c_blue "Found python3, attempting to create venv..."
        [[ ${#extra[@]} -gt 0 ]] && c_yellow "Extra args ignored for python3: ${extra[*]}"
        if "$py3_path" -m venv "$venv_path"; then
            c_green "Created with python3: $venv_path"
            
            # Register in global tracking
            local activate_script="$venv_path/bin/activate"
            mkdir -p "$(dirname "$global_env_file")"
            echo "$venv_name $activate_script" >> "$global_env_file"
            c_blue "Registered $venv_name in global tracking"
            
            venv-activate "$venv_name"
            return 0
        fi
    fi
    # Try python
    local py_path
    py_path=$(command -v python 2>/dev/null)
    if [[ -n "$py_path" && -x "$py_path" ]]; then
        c_blue "Found python, attempting to create venv..."
        [[ ${#extra[@]} -gt 0 ]] && c_yellow "Extra args ignored for python: ${extra[*]}"
        if "$py_path" -m venv "$venv_path"; then
            c_green "Created with python: $venv_path"
            
            # Register in global tracking
            local activate_script="$venv_path/bin/activate"
            mkdir -p "$(dirname "$global_env_file")"
            echo "$venv_name $activate_script" >> "$global_env_file"
            c_blue "Registered $venv_name in global tracking"
            
            venv-activate "$venv_name"
            return 0
        fi
    fi
    c_red "No Python/uv found or all attempts failed. Run install_uv or install Python."
    return 1
}



venv-activate() {
    local name=$1 activate realpath
    [[ -z "$name" ]] && c_red "Usage: venv-activate <name|path>" && venv-list && return 1
    
    # First check if it's a direct path to venv or activate script
    if [[ -d "$name" && -f "$name/bin/activate" ]]; then
        realpath=$(realpath "$name")
        activate="$realpath/bin/activate"
    elif [[ -f "$name" ]]; then
        activate=$(realpath "$name")
        realpath=$(dirname "$(dirname "$activate")")
    else
        # Look up in global tracking file
        local global_env_file="$HOME/.venv_all_env"
        if [[ -f "$global_env_file" ]]; then
            activate=$(awk -v env="$name" '$1==env{print $2}' "$global_env_file")
            if [[ -n "$activate" && -f "$activate" ]]; then
                realpath=$(dirname "$(dirname "$activate")")
            else
                # Try ~/.venvs/<name>
                if [[ -d "$HOME/.venvs/$name" && -f "$HOME/.venvs/$name/bin/activate" ]]; then
                    realpath="$HOME/.venvs/$name"
                    activate="$HOME/.venvs/$name/bin/activate"
                else
                    c_red "Environment '$name' not found in global tracking or ~/.venvs/$name"; venv-list; return 1
                fi
            fi
        else
            # Try ~/.venvs/<name>
            if [[ -d "$HOME/.venvs/$name" && -f "$HOME/.venvs/$name/bin/activate" ]]; then
                realpath="$HOME/.venvs/$name"
                activate="$HOME/.venvs/$name/bin/activate"
            else
                c_red "No global environment tracking file found and '$name' is not a valid path or ~/.venvs/$name does not exist"; return 1
            fi
        fi
    fi
    [[ ! -f "$activate" ]] && c_red "No activate script: $activate" && return 1
    set_env VIRTUAL_ENV "$realpath"
    echo "$name" > "$HOME/.last_venv"
    
    # Store PWD-to-venv association in new atv_history format
    local atv_history_file="$HOME/.config/atv_history"
    mkdir -p "$(dirname "$atv_history_file")"
    
    # Remove any previous entry for this PWD
    if [[ -f "$atv_history_file" ]]; then
        grep -v "^$PWD:" "$atv_history_file" > "$atv_history_file.tmp" && mv "$atv_history_file.tmp" "$atv_history_file"
    fi
    echo "$PWD:$name" >> "$atv_history_file"
    
    # Also maintain old format for backward compatibility
    local assoc_file="$HOME/.venv_pdirs"
    local pwd_escaped
    pwd_escaped=$(printf '%s' "$PWD" | sed 's/\//\\\//g')
    # Remove any previous entry for this PWD
    if [[ -f "$assoc_file" ]]; then
        grep -v "^$PWD:" "$assoc_file" > "$assoc_file.tmp" && mv "$assoc_file.tmp" "$assoc_file"
    fi
    echo "$PWD:$name" >> "$assoc_file"
    
    source "$activate" 2>/dev/null || { c_red "Failed to activate: $activate"; return 1; }
    c_green "Activated: $(basename "$realpath")"
}

# Deactivate current virtual environment
venv-deactivate() {
    [[ -n "$VIRTUAL_ENV" ]] && local n=$(basename "$VIRTUAL_ENV") && deactivate 2>/dev/null || true && unset VIRTUAL_ENV && c_yellow "Deactivated: $n" || c_yellow "No venv active"
}

# List all virtual environments
venv-list() {
    local global_env_file="$HOME/.venv_all_env"
    
    if [[ ! -f "$global_env_file" ]]; then
        c_yellow "No global environment tracking file found: $global_env_file"
        return 0
    fi
    
    if [[ ! -s "$global_env_file" ]]; then
        c_yellow "No virtual environments tracked in $global_env_file"
        return 0
    fi
    
    c_blue "Tracked virtual environments:"
    local count=0
    while IFS=' ' read -r env_name activate_path; do
        [[ -z "$env_name" || -z "$activate_path" ]] && continue
        
        local venv_path=$(dirname "$(dirname "$activate_path")")
        
        # Check if environment still exists
        if [[ -f "$activate_path" ]]; then
            if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$venv_path" ]]; then
                c_green "* $env_name (active) - $venv_path"
            else
                echo "  $env_name - $venv_path"
            fi
            ((count++))
        else
            c_yellow "  $env_name - $venv_path (missing)"
        fi
    done < "$global_env_file"
    
    if [[ $count -eq 0 ]]; then
        c_yellow "No valid virtual environments found"
    fi
}

# Delete a virtual environment
venv-delete() {
    local n="$1"
    shift
    if [[ $# -gt 0 ]]; then
        c_red "Error: venv-delete only accepts one argument (the venv name). Extra args: $*"
        return 1
    fi
    [[ -z "$n" ]] && c_red "Usage: venv-delete <name>" && venv-list && return 1
    
    # Find the environment in global tracking
    local global_env_file="$HOME/.venv_all_env"
    local activate_path
    if [[ -f "$global_env_file" ]]; then
        activate_path=$(awk -v env="$n" '$1==env{print $2}' "$global_env_file")
    fi
    
    if [[ -z "$activate_path" ]]; then
        c_red "Environment '$n' not found in global tracking"
        venv-list
        return 1
    fi
    
    local path=$(dirname "$(dirname "$activate_path")")
    
    [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$path" ]] && c_red "Cannot delete active venv: $n" && return 1
    
    # Safety: never allow empty, /, or $HOME as a deletion target
    if [[ -z "$path" || "$path" == "/" || "$path" == "$HOME" ]]; then
        c_red "Refusing to delete unsafe path: '$path'"
        return 1
    fi
    
    if [[ ! -d "$path" || ! -f "$activate_path" ]]; then
        c_red "Refusing to delete: '$path' is not a valid venv directory"
        return 1
    fi
    
    printf "Delete %s at %s? [y/N] " "$n" "$path"
    read -r _c
    case "$_c" in
        y|Y)
            if /bin/rm -rf "$path"; then
                # Remove from global tracking file
                if [[ -f "$global_env_file" ]]; then
                    grep -v "^$n " "$global_env_file" > "$global_env_file.tmp" && mv "$global_env_file.tmp" "$global_env_file"
                fi
                c_green "Deleted: $n ($path)"
            else
                c_red "Failed to delete: $n"
            fi
            ;;
        *)
            c_yellow "Cancelled"
            ;;
    esac
}

# Show current virtual environment info
venv-info() {
    local venv="$VIRTUAL_ENV"
    local py="$(command -v python)"
    local pyv="$(python --version 2>&1)"
    if [[ -n "$venv" ]]; then
        if [[ "$py" == "$venv"*/bin/python* ]]; then
            c_green "🟢 Active: $(basename "$venv")\n📁 $venv\n🐍 $py\n🔢 $pyv"
        else
            c_yellow "🟡 VIRTUAL_ENV is set, but Python is not from venv!\n📁 $venv\n🐍 $py\n🔢 $pyv"
        fi
    else
        if [[ "$py" == *venv* || "$py" == *env* ]]; then
            c_yellow "🟡 Python is from a venv, but VIRTUAL_ENV is not set!\n🐍 $py\n🔢 $pyv"
        else
            c_red "🔴 No venv active.\n🐍 $py\n🔢 $pyv"
        fi
        venv-list
    fi
}

venv-which() {
    local name=$1
    [[ -z "$name" ]] && c_red "Usage: venv-which <name>" && return 1
    
    # Look up in global tracking file
    local global_env_file="$HOME/.venv_all_env"
    if [[ -f "$global_env_file" ]]; then
        local activate_path
        activate_path=$(awk -v env="$name" '$1==env{print $2}' "$global_env_file")
        if [[ -n "$activate_path" && -f "$activate_path" ]]; then
            local venv_path=$(dirname "$(dirname "$activate_path")")
            c_blue "Would activate: $venv_path"
        else
            c_red "Environment '$name' not found in global tracking"
        fi
    else
        c_red "No global environment tracking file found"
    fi
}

venv-install() {
    [[ -z "$VIRTUAL_ENV" ]] && c_red "No venv active" && return 1
    [[ $# -eq 0 ]] && c_red "Usage: venv-install <pkg>..." && return 1
    c_blue "Installing: $*"
    command -v uv >/dev/null 2>&1 && uv pip install "$@" && c_green "Installed with uv" && return 0
    command -v pip >/dev/null 2>&1 && pip install "$@" && c_green "Installed with pip" && return 0
    c_red "No uv or pip found in venv"
}

ve-installed() {
    [[ -z "$VIRTUAL_ENV" ]] && c_red "No venv active" && return 1
    command -v uv >/dev/null 2>&1 && uv pip list && return 0
    command -v pip >/dev/null 2>&1 && pip list && return 0
    c_red "No uv or pip found in venv"
}

ve-uninstall() {
    [[ -z "$VIRTUAL_ENV" ]] && c_red "No venv active" && return 1
    [[ $# -eq 0 ]] && c_red "Usage: ve uninstall <pkg>..." && return 1
    c_blue "Uninstalling: $*"
    if command -v uv >/dev/null 2>&1; then
        uv pip uninstall "$@" && c_green "Uninstalled with uv" && return 0
    fi
    if command -v pip >/dev/null 2>&1; then
        pip uninstall -y "$@" && c_green "Uninstalled with pip" && return 0
    fi
    c_red "No uv or pip found in venv"
}

ve-search() {
    [[ $# -eq 0 ]] && c_red "Usage: ve search <pkg>" && return 1
    local search_term="$1"
    c_blue "Opening PyPI search for '$search_term' in browser..."
    
    # Try to open in browser
    if command -v open >/dev/null 2>&1; then
        # macOS
        open "https://pypi.org/search/?q=${search_term}"
    elif command -v xdg-open >/dev/null 2>&1; then
        # Linux
        xdg-open "https://pypi.org/search/?q=${search_term}"
    elif command -v start >/dev/null 2>&1; then
        # Windows
        start "https://pypi.org/search/?q=${search_term}"
    else
        c_yellow "Cannot open browser automatically. Please visit:"
        c_blue "https://pypi.org/search/?q=${search_term}"
    fi
}

ve-update() {
    [[ -z "$VIRTUAL_ENV" ]] && c_red "No venv active" && return 1
    [[ $# -eq 0 ]] && c_red "Usage: ve update <pkg>..." && return 1
    c_blue "Updating: $*"
    command -v uv >/dev/null 2>&1 && uv pip install -U "$@" && c_green "Updated with uv" && return 0
    command -v pip >/dev/null 2>&1 && pip install -U "$@" && c_green "Updated with pip" && return 0
    c_red "No uv or pip found in venv"
}

ve-run() {
    [[ -z "$VIRTUAL_ENV" ]] && c_red "No venv active" && return 1
    [[ $# -eq 0 ]] && c_red "Usage: ve run <cmd>..." && return 1
    c_blue "Running in venv: $*"
    "$@"
}

# Auto-activation toggle function
venv-autoatv() {
    local state="$1"
    case "$state" in
        on)
            set_env VENV_AUTO_ACTIVATE on
            c_green "Enabled login-time auto-activation (VENV_AUTO_ACTIVATE=on)."
            ;;
        off)
            unset VENV_AUTO_ACTIVATE
            c_yellow "Disabled login-time auto-activation."
            ;;
        *)
            c_red "Usage: ve autoatv on|off"
            return 1
            ;;
    esac
}

# Help function for the ve command
venv-help() {
    cat << 'EOF'
Virtual Environment Management (ve) - Commands:

  ve create <name> [options]    Create a new virtual environment
  ve activate <name>            Activate a virtual environment  
  ve deactivate                 Deactivate current virtual environment
  ve list                       List all virtual environments
  ve delete <name>              Delete a virtual environment
  ve remove <name>              Remove a virtual environment (alias for delete)
  ve info                       Show current virtual environment info
  ve which <name>               Show path to virtual environment
  ve install <pkg>...           Install packages in active venv
  ve installed                  List installed packages in active venv
  ve uninstall <pkg>...         Uninstall packages from active venv
  ve search <pkg>               Search for packages
  ve update <pkg>...            Update packages in active venv
  ve run <cmd>...               Run command in active venv
  ve autoatv on|off             Toggle login-time auto-activation
  ve help                       Show this help

ATV History Commands:
  atv-history                   Show directory -> environment mappings
  atv-clear-history             Clear all atv history

Aliases:
  create_env <name> [options]   Same as 've create'
  atv <name>                    Same as 've activate' (with auto-directory mapping)
  veremove <name>               Same as 've remove'
  veremoveallexceptbase         Same as 've remove-all-except-base'

Auto-Activation:
  When you use 'atv <name>' to activate an environment, the current directory
  is mapped to that environment. When you 'cd' to that directory later,
  the environment will be automatically activated.

Examples:
  ve create myproject --python=3.12
  cd /path/to/myproject
  atv myproject                 # Creates directory mapping
  cd elsewhere
  cd /path/to/myproject         # Automatically activates myproject
  atv-history                   # Show all directory mappings
EOF
}

venv-remove-all-except-base() {
    local global_env_file="$HOME/.venv_all_env"
    if [[ ! -f "$global_env_file" ]]; then
        c_yellow "No global environment tracking file found"
        return 0
    fi
    
    local envs_to_delete=()
    while IFS=' ' read -r env_name activate_path; do
        [[ -z "$env_name" || -z "$activate_path" ]] && continue
        [[ "$env_name" == "base" ]] && continue
        envs_to_delete+=("$env_name")
    done < "$global_env_file"
    
    if [[ ${#envs_to_delete[@]} -eq 0 ]]; then
        c_yellow "No environments to delete (only 'base' environments are preserved)"
        return 0
    fi
    
    c_blue "Will delete ${#envs_to_delete[@]} environments (preserving 'base'):"
    for env in "${envs_to_delete[@]}"; do
        echo "  $env"
    done
    
    printf "Continue? [y/N] "
    read -r _c
    case "$_c" in
        y|Y)
            for env in "${envs_to_delete[@]}"; do
                venv-delete "$env"
            done
            ;;
        *)
            c_yellow "Cancelled"
            ;;
    esac
}

# Show atv history (directory -> environment mappings)
atv-history() {
    local atv_history_file="$HOME/.config/atv_history"
    if [[ ! -f "$atv_history_file" ]]; then
        c_yellow "No atv history file found: $atv_history_file"
        return 0
    fi
    
    if [[ ! -s "$atv_history_file" ]]; then
        c_yellow "atv history is empty"
        return 0
    fi
    
    c_blue "Directory -> Environment mappings:"
    while IFS=: read -r dir env; do
        if [[ "$PWD" == "$dir" ]]; then
            c_green "* $dir -> $env (current)"
        else
            echo "  $dir -> $env"
        fi
    done < "$atv_history_file"
}

# Clear atv history
atv-clear-history() {
    local atv_history_file="$HOME/.config/atv_history"
    if [[ -f "$atv_history_file" ]]; then
        rm "$atv_history_file"
        c_green "Cleared atv history"
    else
        c_yellow "No atv history file to clear"
    fi
}

ve() {
    local cmd="$1"
    if [[ $# -gt 0 ]]; then shift; fi
    case "$cmd" in
        help|-h|--help|'') venv-help ;;
        create)
            if venv-create "$@"; then
                c_blue "Installing basic packages..."
                ve install pip poetry wheel setuptools
            fi
            ;;
        activate) venv-activate "$@" ;;
        deactivate) venv-deactivate ;;
        list) venv-list ;;
        delete) venv-delete "$@" ;;
        remove) venv-delete "$@" ;;
        remove-all-except-base) venv-remove-all-except-base ;;
        info) venv-info ;;
        which) venv-which "$@" ;;
        install) venv-install "$@" ;;
        installed) ve-installed ;;
        uninstall) ve-uninstall "$@" ;;
        search) ve-search "$@" ;;
        update) ve-update "$@" ;;
        run) ve-run "$@" ;;
        autoatv) venv-autoatv "$@" ;;
        history) atv-history ;;
        clear-history) atv-clear-history ;;
        *) c_red "Unknown command: $cmd"; venv-help ;;
    esac
}



# Auto-activate venv when changing directories based on atv_history
# Toggle controls:
#   - VENV_AUTO_CHDIR: on|1|true|yes to enable, off|0|false|no to disable.
#                      Default: on (enabled). Checked on every directory change.
#   - VENV_AUTO_ACTIVATE: on|1|true|yes to attempt activation once at shell start.
#                         Default: unset (disabled). Only acted upon at login if set.
_atv_auto_activate() {
    local atv_history_file="$HOME/.config/atv_history"
    local current_venv_name=""

    # Respect toggle for cd-based auto activation (defaults to on)
    local _auto_cd_val
    _auto_cd_val=$(printf '%s' "${VENV_AUTO_CHDIR:-on}" | tr '[:upper:]' '[:lower:]')
    case "$_auto_cd_val" in
        off|0|false|no)
            return
            ;;
    esac
    
    # Get current active venv name if any
    if [[ -n "$VIRTUAL_ENV" ]]; then
        current_venv_name=$(basename "$VIRTUAL_ENV")
    fi
    
    # Check if there's a known environment for current directory
    if [[ -f "$atv_history_file" ]]; then
        local target_venv
        target_venv=$(awk -F: -v d="$PWD" '$1==d{print $2}' "$atv_history_file" | tail -n1)
        
        if [[ -n "$target_venv" ]]; then
            # Check if we need to switch environments
            if [[ "$current_venv_name" != "$target_venv" ]]; then
                # Look up environment in global tracking
                local global_env_file="$HOME/.venv_all_env"
                local activate_path
                if [[ -f "$global_env_file" ]]; then
                    activate_path=$(awk -v env="$target_venv" '$1==env{print $2}' "$global_env_file")
                fi
                
                if [[ -n "$activate_path" && -f "$activate_path" ]]; then
                    local venv_dir=$(dirname "$(dirname "$activate_path")")
                    
                    # Deactivate current environment if active
                    if [[ -n "$VIRTUAL_ENV" ]]; then
                        deactivate 2>/dev/null || true
                    fi
                    
                    # Activate the target environment
                    if source "$activate_path" 2>/dev/null; then
                        set_env VIRTUAL_ENV "$venv_dir"
                        c_green "[auto] Switched to venv for $PWD: $target_venv"
                    else
                        c_red "[auto] Failed to activate venv for $PWD: $target_venv"
                    fi
                else
                    c_yellow "[auto] Venv not found in global tracking for $target_venv (removing from history)"
                    # Remove the invalid entry
                    grep -v "^$PWD:" "$atv_history_file" > "$atv_history_file.tmp" && mv "$atv_history_file.tmp" "$atv_history_file"
                fi
            fi
        fi
    fi
}

# Set up directory change hook for zsh
if [[ -n "$ZSH_VERSION" ]]; then
    # Add our function to chpwd_functions array
    autoload -U add-zsh-hook
    add-zsh-hook chpwd _atv_auto_activate
fi


# Auto-activate venv associated with $PWD, else fallback to last venv
# Only run when VENV_AUTO_ACTIVATE is set to on/1/true/yes (case-insensitive).
if [[ -n "${VENV_AUTO_ACTIVATE:-}" ]]; then
    _venv_auto_val=$(printf '%s' "$VENV_AUTO_ACTIVATE" | tr '[:upper:]' '[:lower:]')
    case "$_venv_auto_val" in
        on|1|true|yes)
            assoc_file="$HOME/.venv_pdirs"
            auto_venv=""
            if [[ -f "$assoc_file" ]]; then
                auto_venv=$(awk -F: -v d="$PWD" '$1==d{print $2}' "$assoc_file" | tail -n1)
            fi
            if [[ -n "$auto_venv" ]]; then
                # Look up in global tracking file
                local global_env_file="$HOME/.venv_all_env"
                local activate_path
                if [[ -f "$global_env_file" ]]; then
                    activate_path=$(awk -v env="$auto_venv" '$1==env{print $2}' "$global_env_file")
                fi
                
                if [[ -n "$activate_path" && -f "$activate_path" ]]; then
                    local venv_dir=$(dirname "$(dirname "$activate_path")")
                    if source "$activate_path" 2>/dev/null; then
                        set_env VIRTUAL_ENV "$venv_dir"
                        c_green "[auto] Activated venv for $PWD: $auto_venv"
                    else
                        c_red "[auto] Failed to activate venv for $PWD: $auto_venv"
                    fi
                else
                    c_red "[auto] Venv not found in global tracking: $auto_venv"
                fi
            elif [[ -f "$HOME/.last_venv" ]]; then
                last_venv=$(<"$HOME/.last_venv")
                # Look up in global tracking file
                local global_env_file="$HOME/.venv_all_env"
                local activate_path
                if [[ -f "$global_env_file" ]]; then
                    activate_path=$(awk -v env="$last_venv" '$1==env{print $2}' "$global_env_file")
                fi
                
                if [[ -n "$activate_path" && -f "$activate_path" ]]; then
                    local venv_dir=$(dirname "$(dirname "$activate_path")")
                    if source "$activate_path" 2>/dev/null; then
                        set_env VIRTUAL_ENV "$venv_dir"
                        c_green "[auto] Activated last venv: $last_venv"
                    else
                        c_red "[auto] Failed to activate last venv: $last_venv"
                    fi
                else
                    c_red "[auto] Last venv not found in global tracking: $last_venv"
                fi
            fi
            ;;
        *)
            # VENV_AUTO_ACTIVATE set but not truthy -> skip auto-activation
            ;;
    esac
    unset _venv_auto_val
fi


alias atv='ve activate'