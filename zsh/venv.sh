### VENV
auto_source() {
    # Skip if already in a virtual environment
    # if [[ -n "$VIRTUAL_ENV" ]]; then
    #     echo $pwd
    #     return 0
    # fi
    
    local current_dir="$(pwd)"
    local search_dir="$current_dir"
    local levels=0
    local max_levels=3
    
    # Search for .venv in current directory and up to 3 parents
    while [[ "$search_dir" != "/" && $levels -le $max_levels ]]; do
        if [[ -d "$search_dir/.venv" && -f "$search_dir/.venv/bin/activate" ]]; then
            source "$search_dir/.venv/bin/activate"
            # echo "\033[32mActivated\033[0m virtual environment: $search_dir/.venv"
            return 0
        fi
        search_dir="$(dirname "$search_dir")"
        ((levels++))
    done
    
    echo "\033[33mNo .venv\033[0m found in current directory or up to 3 parent directories"
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
