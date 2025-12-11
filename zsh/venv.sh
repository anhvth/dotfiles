#!/usr/bin/env zsh
# ==============================================================================
# Virtual Environment Management - Unified System
# ==============================================================================
# All Python virtual environment related functions in one place
# Each function has single responsibility and supports --help

# Global variables
VENV_STORAGE_CONFIG="$HOME/.config/.path_to_venv"

# Get or prompt for global venv storage path
_venv_get_storage_path() {
    # Check if config file exists and has content
    if [[ -f "$VENV_STORAGE_CONFIG" ]]; then
        local storage_path=$(cat "$VENV_STORAGE_CONFIG" 2>/dev/null | tr -d '\n\r')
        if [[ -n "$storage_path" ]] && [[ -d "$storage_path" ]]; then
            echo "$storage_path"
            return 0
        fi
    fi

    # Prompt user for storage path
    echo "" >&2
    echo "⚠️  No global virtual environment storage path configured." >&2
    echo "" >&2
    echo "To save disk space in your code directories, virtual environments" >&2
    echo "will be stored in a centralized location and symlinked." >&2
    echo "" >&2
    echo "Suggested locations:" >&2
    echo "  - /mnt/large_space/all_venvs/" >&2
    echo "  - $HOME/.local/share/venvs/" >&2
    echo "  - /opt/venvs/" >&2
    echo "" >&2
    printf "Enter path for storing virtual environments: " >&2
    read storage_path

    # Validate input
    if [[ -z "$storage_path" ]]; then
        echo "❌ No path provided" >&2
        return 1
    fi

    # Expand tilde and remove trailing slashes
    storage_path="${storage_path/#\~/$HOME}"
    storage_path="${storage_path%%/}"

    # Create directory if it doesn't exist
    if [[ ! -d "$storage_path" ]]; then
        echo "📁 Creating directory: $storage_path" >&2
        mkdir -p "$storage_path" || {
            echo "❌ Failed to create directory: $storage_path" >&2
            return 1
        }
    fi

    # Save to config file
    mkdir -p "$(dirname "$VENV_STORAGE_CONFIG")" || return 1
    echo "$storage_path" > "$VENV_STORAGE_CONFIG" || {
        echo "❌ Failed to save config to $VENV_STORAGE_CONFIG" >&2
        return 1
    }

    echo "✅ Saved storage path to: $VENV_STORAGE_CONFIG" >&2
    echo "$storage_path"
    return 0
}

# Persist VS Code Python interpreter without spamming jq errors
_venv_update_vscode_python_path() {
    local python_path="$1"
    local settings_file=".vscode/settings.json"

    [[ -f "$settings_file" ]] || return 1
    [[ -n "$python_path" ]] || return 1

    local err_file output
    local exit_status
    err_file="$(mktemp "${TMPDIR:-/tmp}/vscode-settings.err.XXXXXX")" || return 1

    output="$("$python_path" - "$settings_file" "$python_path" 2>"$err_file" <<'PY'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
python_path = sys.argv[2]


def strip_comments(source: str) -> str:
    result = []
    length = len(source)
    i = 0
    in_string = False
    escape = False

    while i < length:
        ch = source[i]

        if in_string:
            result.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            result.append(ch)
            i += 1
            continue

        if ch == '/' and i + 1 < length:
            nxt = source[i + 1]
            if nxt == '/':
                i += 2
                while i < length and source[i] not in '\n\r':
                    i += 1
                continue
            if nxt == '*':
                i += 2
                while i + 1 < length and not (source[i] == '*' and source[i + 1] == '/'):
                    i += 1
                i += 2
                continue

        result.append(ch)
        i += 1

    return ''.join(result)


try:
    text = settings_path.read_text(encoding="utf-8")
except FileNotFoundError:
    print("UNCHANGED")
    raise SystemExit(0)


clean_text = strip_comments(text).strip()
if clean_text:
    try:
        data = json.loads(clean_text)
    except json.JSONDecodeError as exc:
        print(f"invalid JSON: {exc}", file=sys.stderr)
        raise SystemExit(1)
else:
    data = {}

if not isinstance(data, dict):
    print("settings.json must contain a JSON object", file=sys.stderr)
    raise SystemExit(1)

needs_update = data.get("python.defaultInterpreterPath") != python_path
if needs_update:
    data["python.defaultInterpreterPath"] = python_path
    tmp_path = settings_path.with_suffix(settings_path.suffix + ".tmp")
    tmp_path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
    tmp_path.replace(settings_path)

print("UPDATED" if needs_update else "UNCHANGED")
PY
)"
    exit_status=$?
    if (( exit_status != 0 )); then
        local err_msg
        err_msg="$(<"$err_file")"
        rm -f "$err_file"
        [[ -n "$err_msg" ]] && echo "⚠️  Unable to update VS Code settings: ${err_msg%%$'\n'*}"
        return $exit_status
    fi

    rm -f "$err_file"
    if [[ "$output" == "UPDATED" ]]; then
        echo "✅ Updated VS Code python.defaultInterpreterPath to $python_path"
    fi
    return 0
}

# Helper function to show usage
_venv_show_help() {
    local func_name="$1"
    case "$func_name" in
        "venv-activate")
            cat << 'EOF'
Usage: venv-activate [PATH|--help]

Activate a Python virtual environment.

Arguments:
  PATH          Path to virtualenv directory or activate script
                If omitted, tries current $VIRTUAL_ENV or .venv

Examples:
  venv-activate                    # Activate .venv in current directory
  venv-activate /path/to/myenv     # Activate specific environment
  venv-activate myenv/bin/activate # Activate using activate script path

Note: Automatically enables auto-activation and saves to history.
EOF
            ;;
        "venv-deactivate")
            cat << 'EOF'
Usage: venv-deactivate [--help]

Deactivate current virtual environment and disable auto-activation.
EOF
            ;;
        "venv-create")
            cat << 'EOF'
Usage: venv-create [PATH] [PACKAGES...] [--help]

Create a new Python virtual environment using UV in centralized storage.
A symlink will be created at PATH pointing to the actual environment.

Arguments:
  PATH          Path for symlink to virtualenv (default: .venv)
  PACKAGES      Additional packages to install

Storage:
  Virtual environments are stored in a centralized location to save space.
  The first time you run this, you'll be prompted to set the storage path.
  Configuration is saved in: ~/.config/.path_to_venv

Examples:
  venv-create                           # Create .venv symlink with basic packages
  venv-create myenv                     # Create myenv symlink with basic packages
  venv-create .venv numpy pandas        # Create .venv symlink with extra packages

Basic packages installed: pip, uv, jupyter
EOF
            ;;
        "venv-select")
            cat << 'EOF'
Usage: venv-select [--help]

Select and switch to a different virtual environment from centralized storage.
If you already have the correct venv linked, it will just activate it.
Use this to change which venv your current project uses.
EOF
            ;;
        "venv-auto")
            cat << 'EOF'
Usage: venv-auto [on|off|status|--help]

Control automatic virtual environment activation.

Arguments:
  on       Enable auto-activation  
  off      Disable auto-activation  
  status   Show current auto-activation status (default)

Environment Variables:
  VENV_AUTO_ACTIVATE      - on/off flag
  VENV_AUTO_ACTIVATE_PATH - path to activate script
EOF
            ;;
        "venv-list")
            cat << 'EOF'
Usage: venv-list [--help]

List all virtual environments in centralized storage with details.
Shows path and Python version if available.
EOF
            ;;
        "venv-detect")
            cat << 'EOF'
Usage: venv-detect [--help]

Detect and activate virtual environment in current directory.
Priority order:
  1. .venv symlink to centralized storage
  2. Matching venv in centralized storage (by directory name)
  3. UV projects (pyproject.toml or uv.lock)
  4. Local .venv, venv, env directories

Used internally by auto-activation system.
EOF
            ;;

        "venv-migrate-centralize")
            cat << 'EOF'
Usage: venv-migrate-centralize [VENV_PATH] [--help]

Migrate an existing local virtual environment to centralized storage.
Replaces the local venv directory with a symlink to the centralized location.

Arguments:
  VENV_PATH     Path to local venv directory (default: .venv)

This command will:
  1. Verify the path is a real directory (not already a symlink)
  2. Move the venv to centralized storage with current directory name
  3. Create a symlink at the original location
  4. Preserve all installed packages and configurations

Examples:
  venv-migrate-centralize                          # Migrate .venv to centralized storage
  venv-migrate-centralize .venv                    # Same as above
  venv-migrate-centralize myenv                    # Migrate custom venv directory
EOF
            ;;
        "venv-help")
            cat << 'EOF'
Virtual Environment Management Commands:

Core Commands:
  venv-activate [PATH]         Activate virtual environment
  venv-deactivate              Deactivate current environment
  venv-create [PATH] [PKG]     Create new UV virtual environment
  venv-select                  Select and switch venv from centralized storage
  venv-migrate-centralize      Migrate local venv to centralized storage

Management:
  venv-auto [on|off|status]    Control auto-activation
  venv-list                    List environments from centralized storage
  venv-detect                  Auto-detect environment in current dir

Help:
  venv-help                    Show this help
  [command] --help             Show help for specific command

Examples:
  venv-activate                # Activate .venv
  venv-create myproject numpy pandas    # Create environment with packages
  venv-select                  # Switch to different venv
  venv-auto on                 # Enable auto-activation
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

    # Update VS Code settings if present without triggering jq parse errors
    local python_path
    python_path=$(command -v python)
    if [[ -n "$python_path" ]]; then
        _venv_update_vscode_python_path "$python_path"
    fi
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

# Create new virtual environment in centralized storage with symlink
venv-create() {
    if [[ "$1" == "--help" ]]; then
        _venv_show_help "venv-create"
        return 0
    fi

    if ! command -v uv >/dev/null 2>&1; then
        echo "❌ UV not found. Please install UV first."
        return 1
    fi

    # Get global storage path (will prompt if not configured)
    local storage_path
    storage_path=$(_venv_get_storage_path) || return 1

    local -a uv_args=()
    local venv_path=""

    while (( $# > 0 )); do
        case "$1" in
            --help)
                _venv_show_help "venv-create"
                return 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                uv_args+=("$1")
                shift
                ;;
            *)
                venv_path="$1"
                shift
                break
                ;;
        esac
    done

    if [[ -z "$venv_path" ]]; then
        venv_path=".venv"
    fi

    local -a extra_packages=("$@")

    # Generate venv name from current directory name
    local venv_name="${PWD:t}"
    local actual_venv_path="$storage_path/$venv_name"

    # Check if symlink already exists
    if [[ -e "$venv_path" ]] || [[ -L "$venv_path" ]]; then
        if [[ -L "$venv_path" ]]; then
            local link_target="$(readlink "$venv_path")"
            echo "⚠️  Symlink already exists: $venv_path -> $link_target"
        else
            echo "⚠️  Path already exists: $venv_path"
        fi
        printf "Remove and recreate? [y/N] "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "$venv_path" || {
                echo "❌ Failed to remove $venv_path"
                return 1
            }
        else
            echo "❌ Aborted"
            return 1
        fi
    fi

    # Create directory in storage location
    echo "🔨 Creating virtual environment in: $actual_venv_path"
    mkdir -p "$(dirname "$actual_venv_path")" || {
        echo "❌ Failed to create storage directory"
        return 1
    }

    if (( ${#uv_args[@]} )); then
        uv venv "${uv_args[@]}" "$actual_venv_path" || return 1
    else
        uv venv "$actual_venv_path" || return 1
    fi

    # Create symlink
    echo "🔗 Creating symlink: $venv_path -> $actual_venv_path"
    ln -s "$actual_venv_path" "$venv_path" || {
        echo "❌ Failed to create symlink"
        return 1
    }

    local venv_root="${venv_path:A}"
    local activate_script="$venv_root/bin/activate"

    if [[ ! -f "$activate_script" ]]; then
        echo "❌ Activate script not found at $activate_script"
        return 1
    fi

    echo "📦 Installing basic packages..."
    if ! source "$activate_script"; then
        echo "❌ Failed to source activate script: $activate_script"
        return 1
    fi

    hash -r 2>/dev/null || true

    # Install basic packages
    if (( ${#extra_packages[@]} )); then
        uv pip install pip uv jupyter "${extra_packages[@]}" || return 1
    else
        uv pip install pip uv jupyter || return 1
    fi

    echo "✅ Virtual environment created and activated!"
    echo "   Storage: $actual_venv_path"
    echo "   Symlink: $venv_path"

    # Assert tools are from venv
    local -a tools=(pip jupyter)
    source "$activate_script"
    local venv_bin="$venv_root/bin"
    for cmd in "${tools[@]}"; do
        local cmd_path=$(command -v "$cmd" 2>/dev/null)
        local expected="$venv_bin/$cmd"
        if [[ -z "$cmd_path" ]]; then
            echo "❌ $cmd not found after installation"
            return 1
        fi
        cmd_path="${cmd_path:A}"
        expected="${expected:A}"
        if [[ "$cmd_path" != "$expected" ]]; then
            echo "❌ $cmd not from venv: $cmd_path"
            echo "   Expected: $expected"
            return 1
        fi
        echo "✅ $cmd: $cmd_path"
    done

    # Enable auto-activation and update history
    set_env VENV_AUTO_ACTIVATE on
    set_env VENV_AUTO_ACTIVATE_PATH "$activate_script"
    export VENV_AUTO_ACTIVATE="on"
    export VENV_AUTO_ACTIVATE_PATH="$activate_script"
}

# Select and reuse existing virtual environment from centralized storage
venv-select() {
    if [[ "$1" == "--help" ]]; then
        _venv_show_help "venv-select"
        return 0
    fi

    # Get global storage path
    local storage_path
    storage_path=$(_venv_get_storage_path) || return 1

    if [[ ! -d "$storage_path" ]]; then
        echo "❌ Storage path does not exist: $storage_path"
        return 1
    fi

    # Find all venv directories in storage
    local -a venv_dirs=()
    for dir in "$storage_path"/*(/N); do
        if [[ -f "$dir/bin/activate" ]]; then
            venv_dirs+=("${dir:t}")
        fi
    done

    if (( ${#venv_dirs[@]} == 0 )); then
        echo "❌ No virtual environments found in: $storage_path"
        echo "ℹ️  Create one first with: venv-create"
        return 1
    fi

    # Select venv using fzf
    local selected_venv=""
    if command -v fzf >/dev/null 2>&1; then
        selected_venv=$(printf "%s\n" "${venv_dirs[@]}" | fzf --prompt="🐍 venv> " --height=40% --reverse --header="Select venv to link to .venv")
    else
        echo "Available virtual environments:"
        local i=1
        for venv in "${venv_dirs[@]}"; do
            echo "  $i) $venv"
            ((i++))
        done
        printf "Select number [1]: "
        read -r selection
        selection=${selection:-1}
        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection > 0 && selection <= ${#venv_dirs[@]} )); then
            selected_venv="${venv_dirs[$selection]}"
        else
            echo "❌ Invalid selection"
            return 1
        fi
    fi

    if [[ -z "$selected_venv" ]]; then
        echo "❌ No environment selected"
        return 1
    fi

    local actual_venv_path="$storage_path/$selected_venv"
    local venv_path=".venv"

    # Check if .venv already exists and points to the selected venv
    if [[ -L "$venv_path" ]]; then
        local current_target="$(readlink "$venv_path")"
        if [[ "$current_target" == "$actual_venv_path" ]]; then
            echo "✅ Already linked to: $selected_venv"
            echo "   Symlink: $venv_path -> $actual_venv_path"
            # Just activate it
            local activate_script="$actual_venv_path/bin/activate"
            if [[ -f "$activate_script" ]]; then
                venv-activate "$activate_script"
            fi
            return 0
        fi
    fi

    # Check if .venv already exists (but points to different venv)
    if [[ -e "$venv_path" ]] || [[ -L "$venv_path" ]]; then
        if [[ -L "$venv_path" ]]; then
            local link_target="$(readlink "$venv_path")"
            echo "⚠️  Currently linked to different venv: $venv_path -> $link_target"
        else
            echo "⚠️  Path already exists: $venv_path"
        fi
        printf "Switch to '$selected_venv'? [y/N] "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "$venv_path" || {
                echo "❌ Failed to remove $venv_path"
                return 1
            }
        else
            echo "❌ Aborted"
            return 1
        fi
    fi

    # Create symlink
    echo "🔗 Creating symlink: $venv_path -> $actual_venv_path"
    ln -s "$actual_venv_path" "$venv_path" || {
        echo "❌ Failed to create symlink"
        return 1
    }

    echo "✅ Linked venv: $selected_venv"
    echo "   Storage: $actual_venv_path"
    echo "   Symlink: $venv_path"

    # Activate the venv
    local activate_script="$actual_venv_path/bin/activate"
    if [[ -f "$activate_script" ]]; then
        venv-activate "$activate_script"
    else
        echo "⚠️  Warning: activate script not found, symlink created but not activated"
    fi
}

# Migrate existing local venv to centralized storage
venv-migrate-centralize() {
    if [[ "$1" == "--help" ]]; then
        _venv_show_help "venv-migrate-centralize"
        return 0
    fi

    local venv_path="${1:-.venv}"

    # Check if path exists
    if [[ ! -e "$venv_path" ]]; then
        echo "❌ Path does not exist: $venv_path"
        return 1
    fi

    # Check if it's already a symlink
    if [[ -L "$venv_path" ]]; then
        local link_target="$(readlink "$venv_path")"
        echo "ℹ️  Already a symlink: $venv_path -> $link_target"
        echo "No migration needed."
        return 0
    fi

    # Check if it's a directory
    if [[ ! -d "$venv_path" ]]; then
        echo "❌ Not a directory: $venv_path"
        return 1
    fi

    # Verify it's a valid venv
    if [[ ! -f "$venv_path/bin/activate" ]]; then
        echo "❌ Not a valid virtual environment (missing bin/activate): $venv_path"
        return 1
    fi

    # Get global storage path
    local storage_path
    storage_path=$(_venv_get_storage_path) || return 1

    # Generate venv name from current directory
    local venv_name="${PWD:t}"
    local target_path="$storage_path/$venv_name"

    # Check if target already exists
    if [[ -e "$target_path" ]]; then
        echo "⚠️  Target already exists: $target_path"
        printf "Overwrite? [y/N] "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "🗑️  Removing existing target..."
            rm -rf "$target_path" || {
                echo "❌ Failed to remove existing target"
                return 1
            }
        else
            echo "❌ Aborted"
            return 1
        fi
    fi

    # Get absolute path before moving
    local venv_abs_path="${venv_path:A}"

    echo "📦 Migrating virtual environment..."
    echo "   From: $venv_abs_path"
    echo "   To:   $target_path"

    # Move the directory to centralized storage
    mkdir -p "$(dirname "$target_path")" || {
        echo "❌ Failed to create storage directory"
        return 1
    }

    mv "$venv_abs_path" "$target_path" || {
        echo "❌ Failed to move virtual environment"
        return 1
    }

    # Create symlink at original location
    echo "🔗 Creating symlink: $venv_path -> $target_path"
    ln -s "$target_path" "$venv_path" || {
        echo "❌ Failed to create symlink"
        echo "⚠️  Your venv has been moved to: $target_path"
        echo "You can manually create the symlink with:"
        echo "  ln -s '$target_path' '$venv_path'"
        return 1
    }

    echo "✅ Migration complete!"
    echo "   Storage: $target_path"
    echo "   Symlink: $venv_path"
    echo ""
    echo "ℹ️  Your virtual environment works exactly as before."
    echo "All tools and scripts will continue to function normally."
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

    # Get global storage path
    local storage_path
    storage_path=$(_venv_get_storage_path) || return 1

    if [[ ! -d "$storage_path" ]]; then
        echo "❌ Storage path does not exist: $storage_path"
        return 1
    fi

    # Find all venv directories in storage
    local -a venv_dirs=()
    for dir in "$storage_path"/*(/N); do
        if [[ -f "$dir/bin/activate" ]]; then
            venv_dirs+=("${dir:t}")
        fi
    done

    if (( ${#venv_dirs[@]} == 0 )); then
        echo "❌ No virtual environments found in: $storage_path"
        echo "ℹ️  Create one first with: venv-create"
        return 1
    fi

    echo "🐍 Virtual Environments in Centralized Storage:"
    echo "=============================================="
    
    local count=1
    for venv_name in "${venv_dirs[@]}"; do
        local venv_path="$storage_path/$venv_name"
        local python_version=""
        
        # Try to get Python version
        local python_exec="$venv_path/bin/python"
        if [[ -f "$python_exec" ]]; then
            python_version=$("$python_exec" --version 2>/dev/null | cut -d' ' -f2)
        fi
        
        printf "%2d. %s\n" "$count" "$venv_name"
        printf "    📁 %s\n" "$venv_path"
        [[ -n "$python_version" ]] && printf "    🐍 Python %s\n" "$python_version"
        echo
        ((count++))
    done
}

# Auto-detect environment in current directory
venv-detect() {
    if [[ "$1" == "--help" ]]; then
        _venv_show_help "venv-detect"
        return 0
    fi

    # Check if .venv exists and is a symlink to centralized storage (highest priority)
    if [[ -L ".venv" ]]; then
        local target="$(readlink ".venv")"
        if [[ -f "$target/bin/activate" ]]; then
            echo "🔍 Detected centralized venv symlink: .venv"
            venv-activate ".venv"
            return 0
        fi
    fi

    # Check centralized storage for venv matching current directory name
    local storage_path
    if storage_path=$(_venv_get_storage_path 2>/dev/null); then
        local dir_name="${PWD:t}"
        local central_venv="$storage_path/$dir_name"
        if [[ -f "$central_venv/bin/activate" ]]; then
            echo "🔍 Found matching venv in centralized storage: $dir_name"
            echo "💡 Tip: Run 'venv-select' to link it to this directory"
            return 1
        fi
    fi

    # Check for UV projects
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

    # Check for local virtualenv directories (legacy support)
    local venv_dirs=(".venv" "venv" "env" ".env")
    for dir in "${venv_dirs[@]}"; do
        if [[ -f "$dir/bin/activate" ]]; then
            echo "🔍 Detected local virtualenv: $dir"
            echo "💡 Tip: Run 'venv-migrate-centralize' to move it to centralized storage"
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
# Legacy compatibility (will be removed)
# ==============================================================================

# Legacy compatibility (will be removed)
alias atv='venv-activate'
alias atv_select='venv-select' 
alias auto_atv_disable='venv-deactivate && venv-auto off'