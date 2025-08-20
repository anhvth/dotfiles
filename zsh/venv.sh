### Expected behavior:
# - create_env <env_name> should create a new virtual environment, and do 
# - atv <env_name> should activate the specified virtual environment


### VENV - Optimized version with comprehensive environment management
VENV_ROOT_DIR=$HOME/venvs
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
    local base="$VENV_ROOT_DIR/venvs"
    local venv_path="$base/$venv_name"
    local extra=("$@")

    [[ -z "$venv_name" ]] && c_red "Usage: venv-create <name> [--python=3.12]" && return 1
    [[ ! "$venv_name" =~ ^[a-zA-Z0-9_-]+$ ]] && c_red "Invalid name: $venv_name" && return 1
    if [[ -d "$venv_path" ]]; then
        c_yellow "Virtual environment already exists: $venv_path"
        printf "Overwrite %s? [y/N] " "$venv_name"
        read -r _c
        case "$_c" in
            y|Y)
                c_yellow "Removing existing venv: $venv_name"
                /bin/rm -rf "$venv_path"
                ;;
            *)
                c_yellow "Cancelled. Not overwriting $venv_name."
                return 1
                ;;
        esac
    fi
    # Ensure base directory exists
    /bin/mkdir -p "$base" || { c_red "Failed to create directory: $base"; return 1; }
    c_blue "Creating venv: $venv_name ${extra[*]}"

    # Try uv first
    local uv_path
    uv_path=$(command -v uv 2>/dev/null)
    if [[ -n "$uv_path" && -x "$uv_path" ]]; then
        c_blue "Found uv, attempting to create venv..."
        if "$uv_path" venv "${extra[@]}" "$venv_path"; then
            c_green "Created with uv: $venv_path"
            venv-activate "$venv_name"
            return 0
        else
            c_yellow "uv failed, trying to install Python and retry..."
            if "$uv_path" python install && "$uv_path" venv "${extra[@]}" "$venv_path"; then
                c_green "Created with uv (after Python install): $venv_path"
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
            venv-activate "$venv_name"
            return 0
        fi
    fi
    c_red "No Python/uv found or all attempts failed. Run install_uv or install Python."
    return 1
}



venv-activate() {
    local name=$1 base="$VENV_ROOT_DIR/venvs" realpath activate
    [[ -z "$name" ]] && c_red "Usage: venv-activate <name|path>" && venv-list && return 1
    if [[ ! "$name" == */* && -d "$base/$name" ]]; then
        realpath=$(realpath "$base/$name")
        activate="$realpath/bin/activate"
    elif [[ -d "$name" && -f "$name/bin/activate" ]]; then
        realpath=$(realpath "$name")
        activate="$realpath/bin/activate"
    elif [[ -f "$name" ]]; then
        activate=$(realpath "$name")
        realpath=$(dirname "$(dirname "$activate")")
    else
        c_red "Invalid venv: $name"; venv-list; return 1
    fi
    [[ ! -f "$activate" ]] && c_red "No activate script: $activate" && return 1
    set_env VIRTUAL_ENV "$realpath"
    echo "$name" > "$HOME/.last_venv"
    # Store PWD-to-venv association
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
    local base="$VENV_ROOT_DIR/venvs"; [[ ! -d "$base" ]] && c_yellow "No venv dir: $base" && return 1
    local envs=() v
    for v in "$base"/*/; do [[ -d "$v" && -f "$v/bin/activate" ]] && envs+=("$(basename "$v")"); done
    [[ ${#envs[@]} -eq 0 ]] && c_yellow "No venvs in $base" && return 0
    c_blue "Envs in $base:"; for e in "${envs[@]}"; do [[ "$VIRTUAL_ENV" == "$base/$e"* ]] && c_green "* $e (active)" || echo "  $e"; done
}

# Delete a virtual environment
venv-delete() {
    local n="$1"
    local base="$VENV_ROOT_DIR/venvs"
    local path="$base/$n"
    shift
    if [[ $# -gt 0 ]]; then
        c_red "Error: venv-delete only accepts one argument (the venv name). Extra args: $*"
        return 1
    fi
    [[ -z "$n" ]] && c_red "Usage: venv-delete <name>" && venv-list && return 1
    [[ ! -d "$path" ]] && c_red "No venv: $n" && venv-list && return 1
    [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$path" ]] && c_red "Cannot delete active venv: $n" && return 1
    # Safety: never allow empty, /, or $HOME as a deletion target
    if [[ -z "$path" || "$path" == "/" || "$path" == "$HOME" ]]; then
        c_red "Refusing to delete unsafe path: '$path'"
        return 1
    fi
    if [[ ! -d "$path" || ! -f "$path/bin/activate" ]]; then
        c_red "Refusing to delete: '$path' is not a valid venv directory"
        return 1
    fi
    printf "Delete %s? [y/N] " "$n"
    read -r _c
    case "$_c" in
        y|Y)
            /bin/rm -rf "$path" && c_green "Deleted: $n" || c_red "Failed to delete: $n"
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
    local name=$1 base="$VENV_ROOT_DIR/venvs"
    [[ -z "$name" ]] && c_red "Usage: venv-which <name>" && return 1
    local path="$base/$name"
    [[ -d "$path" && -f "$path/bin/activate" ]] && c_blue "Would activate: $path" || c_red "No venv: $name"
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
  ve help                       Show this help

Aliases:
  create_env <name> [options]   Same as 've create'
  atv <name>                    Same as 've activate'
  veremove <name>               Same as 've remove'
  veremoveallexceptbase         Same as 've remove-all-except-base'

Examples:
  ve create myproject --python=3.12
  ve activate myproject
  ve install numpy pandas
  ve info
  ve deactivate
EOF
}

venv-remove-all-except-base() {
    local base="$VENV_ROOT_DIR/venvs"
    local v
    for v in "$base"/*/; do
        local name="$(basename "$v")"
        [[ "$name" == "base" ]] && continue
        [[ -d "$v" && -f "$v/bin/activate" ]] && venv-delete "$name"
    done
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
        *) c_red "Unknown command: $cmd"; venv-help ;;
    esac
}



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
                venv_dir="$HOME/venvs/venvs/$auto_venv"
                if [[ -d "$venv_dir" && -f "$venv_dir/bin/activate" ]]; then
                    if source "$venv_dir/bin/activate" 2>/dev/null; then
                        c_green "[auto] Activated venv for $PWD: $auto_venv"
                    else
                        c_red "[auto] Failed to activate venv for $PWD: $auto_venv"
                    fi
                else
                    c_red "[auto] Venv directory or activate script missing for $auto_venv"
                fi
            elif [[ -f "$HOME/.last_venv" ]]; then
                last_venv=$(<"$HOME/.last_venv")
                venv_dir="$HOME/venvs/venvs/$last_venv"
                if [[ -d "$venv_dir" && -f "$venv_dir/bin/activate" ]]; then
                    if source "$venv_dir/bin/activate" 2>/dev/null; then
                        c_green "[auto] Activated last venv: $last_venv"
                    else
                        c_red "[auto] Failed to activate last venv: $last_venv"
                    fi
                else
                    c_red "[auto] Last venv directory or activate script missing: $last_venv"
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