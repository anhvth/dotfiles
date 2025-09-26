#!/usr/bin/env zsh
# ==============================================================================
# Virtual Environment Management - Unified System
# ==============================================================================
# All Python virtual environment related functions in one place
# Each function has single responsibility and supports --help

# Global variables
VENV_HISTORY_FILE="$HOME/.cache/dotfiles/venv_history"
VENV_HISTORY_LIMIT=30

# Helper function to show usage
_venv_show_help() {
    local func_name="$1"
    case "$func_name" in
        "venv-activate"|"va")
            cat << 'EOF'
Usage: venv-activate [PATH|--help] 
       va [PATH|--help]

Activate a Python virtual environment.

Arguments:
  PATH          Path to virtualenv directory or activate script
                If omitted, tries current $VIRTUAL_ENV or .venv

Examples:
  va                    # Activate .venv in current directory
  va /path/to/myenv     # Activate specific environment
  va myenv/bin/activate # Activate using activate script path

Note: Automatically enables auto-activation and saves to history.
EOF
            ;;
        "venv-deactivate"|"vd")
            cat << 'EOF'
Usage: venv-deactivate [--help]
       vd [--help]

Deactivate current virtual environment and disable auto-activation.
EOF
            ;;
        "venv-create"|"vc")
            cat << 'EOF'
Usage: venv-create [PATH] [PACKAGES...] [--help]
       vc [PATH] [PACKAGES...] [--help]

Create a new Python virtual environment using UV.

Arguments:
  PATH          Path for new virtualenv (default: .venv)
  PACKAGES      Additional packages to install

Examples:
  vc                           # Create .venv with basic packages
  vc myenv                     # Create myenv with basic packages  
  vc .venv numpy pandas        # Create .venv with extra packages

Basic packages installed: pip, poetry, jupyter, ipython
EOF
            ;;
        "venv-select"|"vs")
            cat << 'EOF'
Usage: venv-select [--help]
       vs [--help]

Select and activate a virtual environment from history using fzf.
Fallback to most recent if fzf is not available.
EOF
            ;;
        "venv-auto"|"venv-auto-toggle")
            cat << 'EOF'
Usage: venv-auto [on|off|status|--help]

Control automatic virtual environment activation.

Commands:
  on       Enable auto-activation on shell startup
  off      Disable auto-activation  
  status   Show current auto-activation status (default)

Environment Variables:
  VENV_AUTO_ACTIVATE      - on/off flag
  VENV_AUTO_ACTIVATE_PATH - path to activate script
EOF
            ;;
        "venv-list"|"vl")
            cat << 'EOF'
Usage: venv-list [--help]
       vl [--help]

List all virtual environments from history with details.
Shows path, existence status, and Python version if available.
EOF
            ;;
        "venv-detect")
            cat << 'EOF'
Usage: venv-detect [--help]

Detect and activate virtual environment in current directory.
Looks for:
  1. UV projects (pyproject.toml or uv.lock) 
  2. Standard .venv directory
  3. Other common venv directory names

Used internally by auto-activation system.
EOF
            ;;
        "venv-help"|"vh")
            cat << 'EOF'
Virtual Environment Management Commands:

Core Commands:
  venv-activate, va [PATH]     Activate virtual environment
  venv-deactivate, vd          Deactivate current environment  
  venv-create, vc [PATH] [PKG] Create new UV virtual environment
  venv-select, vs              Select from history with fzf

Management:
  venv-auto [on|off|status]    Control auto-activation
  venv-list, vl                List environments from history
  venv-detect                  Auto-detect environment in current dir

Help:
  venv-help, vh                Show this help
  [command] --help             Show help for specific command

Examples:
  va                           # Activate .venv 
  vc myproject numpy pandas    # Create environment with packages
  vs                          # Select from history
  venv-auto on                # Enable auto-activation
EOF
            ;;
        *)
            echo "Unknown function: $func_name"
            echo "Run 'venv-help' for available commands."
            return 1
            ;;
    esac
}

# ==============================================================================
# Core Functions
# ==============================================================================

# Activate virtual environment
venv-activate() {
    if [[ "$1" == "--help" ]]; then
        _venv_show_help "venv-activate"
        return 0
    fi

    local target="$1"
    local activate_path=""

    # Determine target
    if [[ -z "$target" ]]; then
        # Check if .venv/bin/activate exists in current directory
        if [[ -f ".venv/bin/activate" ]]; then
            local current_venv_path="$(realpath .venv)"
            # If already in the same venv, show status; otherwise activate local .venv
            if [[ -n "$VIRTUAL_ENV" && "$(realpath "$VIRTUAL_ENV")" == "$current_venv_path" ]]; then
                echo "ℹ️  Virtual environment already active: $(basename "$VIRTUAL_ENV")"
                echo "📁 Path: $VIRTUAL_ENV"
                echo "💡 Use 'vs' to switch to another environment"
                return 0
            else
                target=".venv"
            fi
        else
            # No local .venv found, show selection
            if [[ -n "$VIRTUAL_ENV" ]]; then
                echo "ℹ️  Current environment: $(basename "$VIRTUAL_ENV")"
                echo "ℹ️  No .venv/bin/activate found in current directory"
            else
                echo "ℹ️  No .venv/bin/activate found in current directory"
            fi
            echo "🔍 Select from available environments:"
            venv-select
            return $?
        fi
    fi

    # Find activate script
    if [[ -d "$target" ]]; then
        if [[ -f "$target/bin/activate" ]]; then
            activate_path="$target/bin/activate"
        elif [[ -f "$target/activate" ]]; then
            activate_path="$target/activate"
        fi
    elif [[ -f "$target" ]]; then
        activate_path="$target"
    fi

    # Validate activate script
    if [[ -z "$activate_path" || "${activate_path##*/}" != "activate" ]]; then
        echo "❌ venv-activate: could not find activate script for '$target'"
        return 1
    fi

    activate_path="${activate_path:A}"
    if [[ ! -f "$activate_path" ]]; then
        echo "❌ venv-activate: activate script not found at $activate_path"
        return 1
    fi

    # Activate environment
    echo "🔄 Activating virtualenv..."
    if ! source "$activate_path"; then
        echo "❌ Failed to source activate script: $activate_path"
        return 1
    fi
    
    local env_root="${activate_path:h}"
    echo "✅ Activated virtualenv at ${env_root}"
    
    # Verify activation worked
    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo "⚠️  Warning: VIRTUAL_ENV not set after activation"
        return 1
    fi
    
    # Enable auto-activation
    set_env VENV_AUTO_ACTIVATE on
    set_env VENV_AUTO_ACTIVATE_PATH "$activate_path"
    export VENV_AUTO_ACTIVATE="on"
    export VENV_AUTO_ACTIVATE_PATH="$activate_path"

    # Update history
    _venv_update_history "$activate_path"
}

# Deactivate virtual environment  
venv-deactivate() {
    if [[ "$1" == "--help" ]]; then
        _venv_show_help "venv-deactivate"
        return 0
    fi

    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo "ℹ️  No virtual environment currently active"
        return 0
    fi

    local old_env="$VIRTUAL_ENV"
    deactivate 2>/dev/null || true
    
    # Disable auto-activation
    set_env VENV_AUTO_ACTIVATE off
    unset_env VENV_AUTO_ACTIVATE_PATH
    export VENV_AUTO_ACTIVATE="off"
    unset VENV_AUTO_ACTIVATE_PATH

    echo "✅ Deactivated virtualenv: $(basename "$old_env")"
}

# Create new virtual environment
venv-create() {
    if [[ "$1" == "--help" ]]; then
        _venv_show_help "venv-create"
        return 0
    fi

    local venv_path="${1:-.venv}"
    shift
    local extra_packages=("$@")
    
    if ! command -v uv >/dev/null 2>&1; then
        echo "❌ UV not found. Please install UV first."
        return 1
    fi

    echo "🔨 Creating virtual environment at: $venv_path"
    uv venv "$venv_path" || return 1
    
    echo "📦 Installing basic packages..."
    local activate_script="$venv_path/bin/activate"
    source "$activate_script"
    
    # Install basic packages
    uv pip install pip poetry jupyter ipython "${extra_packages[@]}" || return 1
    
    echo "✅ Virtual environment created and activated!"
    echo "📍 pip: $(which pip)"
    echo "🐍 python: $(which python)" 
    echo "📓 ipython: $(which ipython)"
    
    # Enable auto-activation and update history
    set_env VENV_AUTO_ACTIVATE on
    set_env VENV_AUTO_ACTIVATE_PATH "$activate_script"
    export VENV_AUTO_ACTIVATE="on"
    export VENV_AUTO_ACTIVATE_PATH="$activate_script"
    
    _venv_update_history "$activate_script"
}

# Select from history
venv-select() {
    if [[ "$1" == "--help" ]]; then
        _venv_show_help "venv-select"
        return 0
    fi

    if [[ ! -f "$VENV_HISTORY_FILE" ]]; then
        echo "❌ No virtual environment history found. Use 'venv-activate' to create history."
        return 1
    fi

    local selection=""
    if command -v fzf >/dev/null 2>&1; then
        selection=$(fzf --prompt="🐍 venv> " --height=40% --reverse < "$VENV_HISTORY_FILE")
    else
        selection=$(head -n 1 "$VENV_HISTORY_FILE")
        if [[ -n "$selection" ]]; then
            echo "ℹ️  fzf not found; using most recent: $selection"
        fi
    fi

    if [[ -z "$selection" ]]; then
        echo "❌ No environment selected"
        return 1
    fi

    venv-activate "$selection"
}

# ==============================================================================
# Management Functions  
# ==============================================================================

# Auto-activation control
venv-auto() {
    local mode="${1:-status}"
    
    if [[ "$mode" == "--help" ]]; then
        _venv_show_help "venv-auto"
        return 0
    fi

    case "${mode:l}" in
        status)
            local current=$(print -r -- ${VENV_AUTO_ACTIVATE:-off})
            local path="${VENV_AUTO_ACTIVATE_PATH:-none}"
            echo "🔧 Auto-activation: $current"
            echo "📁 Path: $path"
            ;;
        on|1|true|yes)
            set_env VENV_AUTO_ACTIVATE on
            echo "✅ Enabled auto-activation on shell startup"
            ;;
        off|0|false|no)
            unset_env VENV_AUTO_ACTIVATE
            unset_env VENV_AUTO_ACTIVATE_PATH
            export VENV_AUTO_ACTIVATE="off"
            unset VENV_AUTO_ACTIVATE_PATH
            echo "❌ Disabled auto-activation"
            ;;
        *)
            echo "❌ Invalid option: $mode"
            echo "Usage: venv-auto [on|off|status|--help]"
            return 1
            ;;
    esac
}

# List environments
venv-list() {
    if [[ "$1" == "--help" ]]; then
        _venv_show_help "venv-list"
        return 0
    fi

    if [[ ! -f "$VENV_HISTORY_FILE" ]]; then
        echo "❌ No virtual environment history found"
        return 1
    fi

    echo "🐍 Virtual Environment History:"
    echo "================================"
    
    local count=1
    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        
        local env_dir="${path:h}"
        local exists="❌"
        local python_version=""
        
        if [[ -f "$path" ]]; then
            exists="✅"
            # Try to get Python version
            local python_exec="$env_dir/bin/python"
            if [[ -f "$python_exec" ]]; then
                python_version=$("$python_exec" --version 2>/dev/null | cut -d' ' -f2)
            fi
        fi
        
        printf "%2d. %s %s\n" "$count" "$exists" "$(basename "$env_dir")"
        printf "    📁 %s\n" "$env_dir"
        [[ -n "$python_version" ]] && printf "    🐍 Python %s\n" "$python_version"
        echo
        
        ((count++))
    done < "$VENV_HISTORY_FILE"
}

# Auto-detect environment in current directory
venv-detect() {
    if [[ "$1" == "--help" ]]; then
        _venv_show_help "venv-detect"
        return 0
    fi

    # Check for UV projects first
    if [[ -f "pyproject.toml" || -f "uv.lock" ]]; then
        if command -v uv >/dev/null 2>&1; then
            local python_exec=$(uv run python -c "import sys; print(sys.executable)" 2>/dev/null)
            if [[ "$python_exec" == *".venv"* ]]; then
                local activate_path="${python_exec%python*}activate"
                if [[ -f "$activate_path" ]]; then
                    echo "🔍 Detected UV project environment"
                    venv-activate "$activate_path"
                    return 0
                fi
            fi
        fi
    fi

    # Check for standard virtualenv directories
    local venv_dirs=(".venv" "venv" "env" ".env")
    for dir in "${venv_dirs[@]}"; do
        if [[ -f "$dir/bin/activate" ]]; then
            echo "🔍 Detected virtualenv: $dir"
            venv-activate "$dir"
            return 0
        fi
    done

    echo "ℹ️  No virtual environment detected in current directory"
    return 1
}

# Help function
venv-help() {
    _venv_show_help "venv-help"
}

# ==============================================================================
# Internal Helper Functions
# ==============================================================================

# Update history file
_venv_update_history() {
    local activate_path="$1"
    
    mkdir -p "${VENV_HISTORY_FILE:h}"
    local -a entries
    entries=()
    entries+=("$activate_path")
    
    if [[ -f "$VENV_HISTORY_FILE" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" == "$activate_path" ]] && continue
            entries+=("$line")
        done < "$VENV_HISTORY_FILE"
    fi
    
    if (( ${#entries} > VENV_HISTORY_LIMIT )); then
        entries=("${(@)entries[1,$VENV_HISTORY_LIMIT]}")
    fi
    
    : >| "$VENV_HISTORY_FILE"
    for line in "${entries[@]}"; do
        printf '%s\n' "$line"
    done >> "$VENV_HISTORY_FILE"
}

# Auto-startup function (called from zshrc)
_venv_auto_startup() {
    local flag="${VENV_AUTO_ACTIVATE:-off}"
    if [[ "${flag:l}" != "on" ]]; then
        return
    fi

    local activate_path="${VENV_AUTO_ACTIVATE_PATH:-}"
    if [[ -z "$activate_path" || ! -f "$activate_path" ]]; then
        return
    fi

    local env_root="${activate_path:h}"
    if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$env_root" ]]; then
        return
    fi

    echo "🐍 source \033[32m'$activate_path'\033[0m"
    source "$activate_path"
}

# ==============================================================================
# Aliases for convenience
# ==============================================================================

# Short aliases
alias va='venv-activate'
alias vd='venv-deactivate' 
alias vc='venv-create'
alias vs='venv-select'
alias vl='venv-list'
alias vh='venv-help'

# Legacy compatibility (will be removed)
alias atv='venv-activate'
alias atv_select='venv-select' 
alias auto_atv_disable='vd && venv-auto off'