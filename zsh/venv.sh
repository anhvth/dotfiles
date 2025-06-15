### VENV - Optimized version
auto_source() {
    # Cache the result to avoid repeated filesystem calls
    local cache_file="/tmp/.venv_cache_$$"
    
    # Skip if already in a virtual environment
    [[ -n "$VIRTUAL_ENV" ]] && return 0
    
    local current_dir="$(pwd)"
    local search_dir="$current_dir"
    local levels=0
    local max_levels=3
    
    # Search for .venv in current directory and up to 3 parents
    while [[ "$search_dir" != "/" && $levels -le $max_levels ]]; do
        if [[ -d "$search_dir/.venv" && -f "$search_dir/.venv/bin/activate" ]]; then
            source "$search_dir/.venv/bin/activate"
            return 0
        fi
        search_dir="$(dirname "$search_dir")"
        ((levels++))
    done
    
    return 1
}

create_venv() {
    local prompt_name="$1"
    if [[ -n "$prompt_name" ]]; then
        python3 -m venv .venv --prompt "$prompt_name"
    else
        python3 -m venv .venv
    fi
    source .venv/bin/activate && pip install poetry uv
}
