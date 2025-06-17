### VENV - Optimized version
atv() {
    # Accept either a venv directory or an activate script path
    path_activate=$1

    if [[ -d "$path_activate" && -f "$path_activate/bin/activate" ]]; then
        realpath_activate=$(realpath "$path_activate" 2>/dev/null)
        activate_script="$realpath_activate/bin/activate"
    elif [[ -f "$path_activate" ]]; then
        activate_script=$(realpath "$path_activate" 2>/dev/null)
        realpath_activate=$(dirname "$(dirname "$activate_script")")
    else
        echo "Invalid virtual environment path: $path_activate"
        return 1
    fi

    set_env VIRTUAL_ENV "$realpath_activate"
    source "$activate_script" 2>/dev/null || {
        echo "Failed to activate virtual environment at $activate_script"
        return 1
    }
    return 0
}
