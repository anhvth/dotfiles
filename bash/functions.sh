#!/bin/bash

# Bash Functions Configuration
# Port of zsh/functions.sh to bash-compatible format

# Absolute path function
absp() {
    local file_or_folder="$1"
    local current_dir="$(pwd)"

    # If no argument is provided, use fzf to select a file/folder
    if [ -z "$file_or_folder" ]; then
        file_or_folder="$(fzf)"
    fi

    # Remove leading ./ or / if present
    file_or_folder="${file_or_folder#./}"
    file_or_folder="${file_or_folder#/}"

    # If the file_or_folder is not an absolute path, prepend the current directory
    if [[ "$file_or_folder" != /* ]]; then
        file_or_folder="$current_dir/$file_or_folder"
    fi

    # Remove any double slashes
    file_or_folder="$(echo "$file_or_folder" | sed 's|//|/|g')"

    echo "$cname:$file_or_folder"
}

# Smart cd function
c() {
    if [ -d "$1" ]; then
        cd "$1" || return 1
    elif [ -f "$1" ]; then
        cd "$(dirname "$1")" || return 1
    else
        echo -e "\e[31m$1 is not a valid file or directory\e[0m" # Red text for errors
        return 1
    fi
    echo -e "\e[32mcd to $(pwd)\e[0m" # Green text for success
    ls
}

# Docker run function
docker-run() {
    local HISTORY_FILE="${HOME}/docker-history/${PWD}"
    if [ ! -f "$HISTORY_FILE" ]; then
        mkdir -p "${HOME}/docker-history"
        touch "$HISTORY_FILE"
    fi
    
    local CONTAINER_NAME="${1:-$DOCKER_ACTIVE_CONTAINER}"
    
    if docker ps -a | grep -q "$CONTAINER_NAME"; then
        echo "Restart $CONTAINER_NAME"
        docker kill "$CONTAINER_NAME"
        docker rm "$CONTAINER_NAME"
    else
        echo "Start $CONTAINER_NAME"
    fi
    
    docker run --name "$CONTAINER_NAME" -it -p "$2:8888" \
        -v "$(pwd):/docker-container/" \
        -v "$HISTORY_FILE:/root/.bash_history" \
        --rm \
        "$DOCKER_ACTIVE_IMAGE" /bin/bash
}

# Docker attach function
docker-attatch() {
    echo "Which container do you want to attach"
    docker ps -a
    read -r container_name
    echo "Attach $container_name"
    docker attach "$container_name"
}

# Docker commit function
docker-commit() {
    docker commit "$DOCKER_ACTIVE_CONTAINER" "$DOCKER_ACTIVE_IMAGE"
    echo "Would you like to push $DOCKER_ACTIVE_IMAGE image to the cloud (y/n)"
    read -r answer

    if [[ "$answer" =~ ^[Yy] ]]; then
        echo "Push $DOCKER_ACTIVE_IMAGE"
        docker push "$DOCKER_ACTIVE_IMAGE"
    fi
}

# Docker kill all function
docker-kill() {
    docker kill "$(docker ps -qa)"
    docker rm "$(docker ps -qa)"
}

# Tmux session manager
tm() {
    local change
    if [ -n "$TMUX" ]; then
        change="switch-client"
    else
        change="attach-session"
    fi
    
    if [ "$1" ]; then
        tmux "$change" -t "$1" 2>/dev/null || (tmux new-session -d -s "$1" && tmux "$change" -t "$1")
        return
    fi
    
    local session
    session="$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0)"
    if [ -n "$session" ]; then
        tmux "$change" -t "$session"
    else
        echo "No sessions found."
    fi
}

# Get remote file function
get_remote_file() {
    rm -f ~/.tmp_allfiles.txt
    ssh "$1" -t "cd \"$2\" && ls **/*.*" >> ~/.tmp_allfiles1.txt
    echo " " >> ~/.tmp_allfiles1.txt
    vi -c "%s/\s\+/\r/g | wq" ~/.tmp_allfiles1.txt
    vi -c "%s///g | wq" ~/.tmp_allfiles1.txt
    local prefix="scp://$1/$2"
    echo "$prefix"
    awk -v prefix="$prefix/" '{print prefix $0}' ~/.tmp_allfiles1.txt >> ~/.tmp_allfiles.txt
    cat ~/.tmp_allfiles.txt
    sort ~/.tmp_allfiles.txt | uniq >> ~/.tmp_allfiles.txt
}

# Find directory projects
fd() {
    local dir
    dir="$(find "${1:-.}" -path '*/\.*' -prune \
        -o -type d -print 2>/dev/null | fzf +m)"
    if [ -n "$dir" ]; then
        cd "$dir" || return 1
    fi
}

# Kill process with fzf
fkill() {
    local pid
    pid="$(ps -ef | sed 1d | fzf -m | awk '{print $2}')"

    if [ -n "$pid" ]; then
        echo "$pid" | xargs kill -"${1:-9}"
    fi
}

# History search with fzf
fh() {
    local cmd
    cmd="$(history | fzf +s --tac | sed -r 's/ *[0-9]*\*? *//' | sed -r 's/\\/\\\\/g')"
    if [ -n "$cmd" ]; then
        eval "$cmd"
    fi
}

# FZF history that inserts selection into the current command line
fzf_history_insert() {
    if ! command -v fzf >/dev/null 2>&1; then
        return 1
    fi
    local query="$READLINE_LINE"
    local selected
    # Use bash history, strip numbers/marks
    selected=$(HISTTIMEFORMAT= history | sed -r 's/^ *[0-9]+\*? *//' | \
        fzf --tac +s --query "$query" --ansi)
    if [ -n "$selected" ]; then
        READLINE_LINE="$selected"
        READLINE_POINT=${#READLINE_LINE}
    fi
}

# Persistent SSH with tmux
tssh() {
    local s="
    while [ 1 ]
    do
        echo \"Reconnecting '$1' ssh\"
        sleep 0.1
        ssh $*
    done"
    echo "$s"

    tmux kill-session -t "ssh_$1" 2>/dev/null
    tmux new -s "ssh_$1" -d "$s"
}

# Find in files
fif() {
    local search_term=""
    local i=0
    for arg in "$@"; do
        if [ $i -gt 0 ]; then
            search_term+=" "
        fi
        search_term+="$arg"
        ((i++))
    done

    local _file
    _file="$(grep --line-buffered --color=never -I -r "$search_term" . | fzf)"
    export _file="$_file"
    local file
    file="$(python3 -c "import os; print(os.environ.get('_file', '').split(':')[0])" 2>/dev/null || echo "${_file%%:*}")"
    echo "$file"
}

# Find in files and open with vim
fiv() {
    local file
    file="$(fif "$@")"
    if [ -n "$file" ]; then
        vi "$file"
    fi
}

# Find in files and open with code
fic() {
    local file
    file="$(fif "$@")"
    if [ -n "$file" ]; then
        code "$file"
    fi
}

# Rsync current directory
rs-current-dir() {
    local cmd="rs $1:$(pwd) $(pwd)"
    echo "$cmd"
}

# Kill Python processes
kill-all-python-except-jupyter() {
    ps aux | grep -i python | grep -wv jupyter | grep -wv vscode | grep "$USER" | awk '{print $2}' | xargs -r kill -9
}

kill-all-python-jupyter() {
    ps aux | grep -i python | grep -wv vscode | awk '{print $2}' | xargs -r kill -9
}

# SSH config switcher
use-ssh() {
    local root="$(pwd)"
    cd "$HOME/.ssh" || return 1
    rm -f config
    cp "config_$1" config
    cd "$root" || return 1
}

# Jupyter notebook converter
ju-convert() {
    echo "Convert $1 to python"
    jupyter nbconvert "$1" --to python
}

# Python formatter
pyf() {
    echo "Sort import and format $1"
    isort "$1" && black "$1" && vi -c wq "$1"
}

# CUDA device selector
cu() {
    export CUDA_VISIBLE_DEVICES="$1"
}

# CUDA device lister
cuda-ls() {
    nvidia-smi --query-gpu=index,gpu_name,memory.free --format=csv,noheader | sort -t ',' -k3 -n -r
}

# Start command in tmux
start_cmd_in_tmux() {
    local cmd="no_proxy=\"localhost,127.0.0.1,::1\" $1"
    echo "Starting command: $cmd"
    # add sleep to cmd to avoid exit after failure
    cmd="$cmd; sleep 1234"
    local tmux_name="vllm_$2"
    
    if ! tmux has-session -t "$tmux_name" 2>/dev/null; then
        tmux new-session -d -s "$tmux_name" "$cmd"
    else
        echo "Session $tmux_name already exists."
    fi
}

# Generate pylint report
generate_pylint_report() {
    # Remove the existing report file if it exists
    rm -f report.md
    # Create a new report file
    > report.md

    # Find all Python files and run pylint with --errors-only
    while IFS= read -r -d '' file; do
        echo "Running pylint on $file" >> report.md
        pylint --errors-only "$file" >> report.md
        echo -e "\n" >> report.md
    done < <(find . -name "*.py" -print0)

    echo "Error report generated in report.md"
}

# Real path function
rp() {
    if [ -z "$1" ]; then
        realpath "$(fzf)"
    else
        realpath "$1"
    fi
}

# Environment variable management
set_env() {
    local varname="$1"
    local value="$2"

    if [ -z "$varname" ] || [ -z "$value" ]; then
        echo "Usage: set_env <varname> <value>"
        return 1
    fi

    # Remove existing entry for the variable
    if grep -q "^${varname}=" ~/.env 2>/dev/null; then
        sed -i.bak "/^${varname}=/d" ~/.env
    fi

    # Add the new value
    echo "${varname}=${value}" >> ~/.env
    echo "Set ${varname}=${value} in ~/.env"
}

unset_env() {
    local varname="$1"

    if [ -z "$varname" ]; then
        echo "Usage: unset_env <varname>"
        return 1
    fi

    # Remove the entry for the variable
    if grep -q "^${varname}=" ~/.env 2>/dev/null; then
        sed -i.bak "/^${varname}=/d" ~/.env
        echo "Unset ${varname} from ~/.env"
    else
        echo "${varname} not found in ~/.env"
    fi
}

# Virtualenv auto-activation toggles
ve_auto_chdir() {
    local mode="$1"
    if [ -z "$mode" ]; then
        local eff="${VENV_AUTO_CHDIR:-on}"
        echo "VENV_AUTO_CHDIR=${eff} (default on). Usage: ve_auto_chdir on|off"
        return 0
    fi
    case "${mode,,}" in
        on|1|true|yes)
            set_env VENV_AUTO_CHDIR on
            echo "Enabled cd-based auto-activation (VENV_AUTO_CHDIR=on)."
            ;;
        off|0|false|no)
            set_env VENV_AUTO_CHDIR off
            echo "Disabled cd-based auto-activation (VENV_AUTO_CHDIR=off)."
            ;;
        *)
            echo "Usage: ve_auto_chdir on|off"; return 1;;
    esac
}

ve_auto_login() {
    local mode="$1"
    if [ -z "$mode" ]; then
        local eff="${VENV_AUTO_ACTIVATE:-off}"
        echo "VENV_AUTO_ACTIVATE=${eff} (default off). Usage: ve_auto_login on|off"
        return 0
    fi
    case "${mode,,}" in
        on|1|true|yes)
            set_env VENV_AUTO_ACTIVATE on
            echo "Enabled login-time auto-activation (VENV_AUTO_ACTIVATE=on)."
            ;;
        off|0|false|no)
            unset_env VENV_AUTO_ACTIVATE
            echo "Disabled login-time auto-activation (unset VENV_AUTO_ACTIVATE)."
            ;;
        *)
            echo "Usage: ve_auto_login on|off"; return 1;;
    esac
}

# Alias management
set_alias() {
    local aliasname="$1"
    local command="$2"

    if [ -z "$aliasname" ] || [ -z "$command" ]; then
        echo "Usage: set_alias <aliasname> <command>"
        return 1
    fi

    local alias_file="$HOME/dotfiles/bash/aliases.sh"
    
    # Remove existing alias if it exists
    if grep -q "^alias ${aliasname}=" "$alias_file" 2>/dev/null; then
        sed -i.bak "/^alias ${aliasname}=/d" "$alias_file"
    fi

    # Add the new alias
    echo "alias ${aliasname}=\"${command}\"" >> "$alias_file"
    
    # Source the alias file to make it immediately available
    source "$alias_file"
    
    echo "Set alias ${aliasname}=\"${command}\" in $alias_file"
}

# Bash performance functions
timebash() {
    local shell="${1:-$SHELL}"
    local i
    for i in $(seq 1 10); do
        /usr/bin/time "$shell" -i -c exit
    done
}

# AutoSSH functions
my-autossh() {
    local hostname="$1"
    local force_restart=true
    
    # check if restart is forced
    if [ "$force_restart" = true ]; then
        pkill -f "autossh.*$hostname"
    fi

    if [ -z "$hostname" ]; then
        echo "Usage: my-autossh <hostname>"
        return 1
    fi

    # Check if autossh tunnel is already running
    if pgrep -f "autossh.*$hostname" > /dev/null; then
        echo "autossh connection to $hostname is already running."
    else
        echo "Starting autossh connection to $hostname..."
        autossh -f -M 0 -N "$hostname"

        if [ $? -eq 0 ]; then
            echo "autossh connection to $hostname started successfully."
        else
            echo "Failed to start autossh connection to $hostname."
        fi
    fi
}

setup-autossh() {
    local allhost
    allhost="$(grep -E 'Host\s+' ~/.ssh/config | awk '{print $2}' | grep -- '-port$' | sort -u)"
    for host in $allhost; do
        my-autossh "$host"
    done
}

# Project tree structure generator
tree_project() {
    local project_type="$1"
    local depth=4
    local output_file="project-structure.instructions.md"
    local include_ext="py|js|jsx|ts|tsx|java|go|rb|rs|cpp|c|h|cs|php|sh|pl|lua|swift|kt|m|scala"
    local ignore_dirs='node_modules|dist|build|.next|.cache|__pycache__|.venv|env|venv|.mypy_cache|.pytest_cache|.idea|.vscode|.DS_Store|.tox|.eggs|.ipynb_checkpoints'

    # Adjust ignored directories or extensions based on project type
    case "$project_type" in
        python)
            include_ext="py"
            ignore_dirs+="|.mypy_cache|.pytest_cache"
            ;;
        js|javascript|node)
            include_ext="js|jsx|ts|tsx"
            ignore_dirs+="|coverage"
            ;;
    esac

    # Find and print only code files, then format as a tree
    find . -type d \( $(echo "$ignore_dirs" | sed 's/|/ -o -name /g' | sed 's/^/-name /') \) -prune -false -o \
        -type f -regextype posix-extended -regex ".*\.($include_ext)$" | \
        sed 's|^\./||' | awk -F/ '
        {
            for(i=1;i<NF;i++){
                printf("%*s%s/\n",i*2-2,"",$(i))
            }
            print sprintf("%*s%s", (NF-1)*2, "", $NF)
        }' | uniq > "$output_file"

    echo "Project code structure saved to $output_file"
}

# Test proxy function
test_proxy() {
    local output
    output="$(curl -x "127.0.0.1:$1" https://www.google.com -I 2>/dev/null)"
    if echo "$output" | grep -q "200"; then
        echo "Proxy is working"
    else
        echo "Proxy is not working"
    fi
}

# Keep SSH connection alive
keep_ssh() {
    export AUTOSSH_GATETIME=0
    export AUTOSSH_PORT=0
    export AUTOSSH_PIDFILE=/tmp/autossh.pid

    autossh -f -M 0 \
        -NT \
        -o "ServerAliveInterval=30" \
        -o "ServerAliveCountMax=3" \
        -o "ExitOnForwardFailure=yes" \
        "$1"
}

