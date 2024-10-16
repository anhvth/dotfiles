export COLOR_RESET="\[\033[0m\]"
export COLOR_RED="\[\033[0;31m\]"
export COLOR_GREEN="\[\033[0;32m\]"
export COLOR_YELLOW="\[\033[0;33m\]"
export COLOR_BLUE="\[\033[0;34m\]"
export COLOR_MAGENTA="\[\033[0;35m\]"
export COLOR_CYAN="\[\033[0;36m\]"
export COLOR_WHITE="\[\033[0;37m\]"

# Customize the prompt
export PS1="${COLOR_CYAN}\u@\h${COLOR_RESET}:${COLOR_GREEN}\w${COLOR_RESET}\$ "

#!/bin/bash

# Editor
alias vi='nvim'

# FZF
alias fzc='fzf | xargs -r code'

# Docker aliases
alias dki='docker images'
alias dk='docker kill'

# Git aliases
alias gg='git status'

# TensorBoard alias
alias tb='tensorboard --logdir '

# Tmux aliases
alias ta='tmux a -t '
alias tk='tmux kill-session -t'

# Python and Jupyter aliases
alias i='ipython'
alias iav='ipython --profile av'
alias ju='jupyter lab --allow-root --ip 0.0.0.0 --port '
alias nb-clean='jupyter nbconvert --ClearOutputPreprocessor.enabled=True --inplace'

# Utility aliases
alias checksize='du -h ./ | sort -rh'
alias gpus='watch -n0.1 nvidia-smi'
alias what-is-my-ip='wget -qO- https://ipecho.net/plain ; echo'
alias kill_processes='awk "{print \$2}" | xargs kill'

# Custom tools aliases
alias autoreload='$HOME/dotfiles/custom-tools/autoreload-toggle'
alias ov='fetch_and_open_video'
alias code-debug='$HOME/dotfiles/bin/code-debug'

# LS aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Image conversion alias
alias convert_png2jpg='find ./ -name "*.png" | parallel "convert -quality 92 -sampling-factor 2x2,1x1,1x1 {.}.png {.}.jpg && rm {}"'

# SSH alias
alias run-autossh='autossh -M 20000 -o ServerAliveInterval=5 -f -N'

# Dotfiles alias
alias update-dotfiles='cwd=$(pwd) && cd ~/dotfiles && git pull && cd $cwd'

alias lsh="pytools-lsh.py"
alias mpython="pytools-mpython.py"
alias ipython_config="pytools-ipython_config.py"
alias cat_projects="pytools-cat_projects.py"
alias hf-down="pytools-hf-down.py"
alias kill_process_grep="pytools-kill_process_grep.py"
alias print-ipv4="pytools-print-ipv4.py"
alias deit="docker exec -it"

# rs-git-sync function
rs-git-sync(){
    local x="rsync -avzhe ssh --progress --filter=':- .gitignore' \"$1\" \"$2\" --delete"
    watch $x
}

# absp function
absp() {
    local file_or_folder="$1"
    local current_dir=$(pwd)

    # If no argument is provided, use fzf to select a file/folder
    if [ -z "$file_or_folder" ]; then
        file_or_folder=$(fzf)
    fi

    # Remove leading ./ or / if present
    file_or_folder=${file_or_folder#"./"}
    file_or_folder=${file_or_folder#"/"}

    # If the file_or_folder is not an absolute path, prepend the current directory
    if [[ "$file_or_folder" != /* ]]; then
        file_or_folder="$current_dir/$file_or_folder"
    fi

    # Remove any double slashes
    file_or_folder=$(echo "$file_or_folder" | sed 's|//|/|g')

    echo "$cname:$file_or_folder"
}

# c function
c() {
    if [ -d "$1" ]; then
        cd "$1"
    elif [ -f "$1" ]; then
        cd "$(dirname "$1")"
    else
        echo -e "\e[31m$1 is not a valid file or directory\e[0m"
        return 1
    fi
    echo -e "\e[32mcd to $(pwd)\e[0m"
    ls
}

# p function
p(){
    CUDA_VISIBLE_DEVICES=$1 python
}

# j function
j(){
    CUDA_VISIBLE_DEVICES=$1 jupyter lab
}

# docker-run function
docker-run(){
    HISTORY_FILE="${HOME}/docker-history/${PWD//\//_}"

    if [ ! -f "$HISTORY_FILE" ]; then
        mkdir -p "${HOME}/docker-history"
        touch "$HISTORY_FILE"
    fi

    if [ -n "$1" ]; then
        CONTAINER_NAME=$1
    else
        CONTAINER_NAME=$DOCKER_ACTIVE_CONTAINER
    fi

    if docker ps -a | grep "$CONTAINER_NAME" ; then
        echo "Restarting $CONTAINER_NAME"
        docker kill "$CONTAINER_NAME"
        docker rm "$CONTAINER_NAME"
    else
        echo "Starting $CONTAINER_NAME"
    fi

    docker run --name "$CONTAINER_NAME" -it -p "$2":8888 \
        -v "$(pwd)":/docker-container/ \
        -v "$HISTORY_FILE":/root/.bash_history \
        --rm \
        "$DOCKER_ACTIVE_IMAGE" /bin/bash
}

# docker-attach function
docker-attach(){
    echo "Which container do you want to attach?"
    docker ps -a
    read -r container_name
    echo "Attaching to $container_name"
    docker attach "$container_name"
}

# docker-commit function
docker-commit(){
    docker commit "$DOCKER_ACTIVE_CONTAINER" "$DOCKER_ACTIVE_IMAGE"
    echo "Would you like to push $DOCKER_ACTIVE_IMAGE image to the cloud (y/n)?"
    read -r answer

    if echo "$answer" | grep -iq "^y"; then
        echo "Pushing $DOCKER_ACTIVE_IMAGE"
        docker push "$DOCKER_ACTIVE_IMAGE"
    fi
}

# docker-kill function
docker-kill(){
    docker kill $(docker ps -qa)
    docker rm $(docker ps -qa)
}

# atv function
atv(){
    conda deactivate
    local name="$1"
    conda activate "$name"
    export env_name="$name"
    echo "$env_name" > ~/.last_env.txt
    echo "Activated: $name"
}

# tm function
tm() {
    if [[ -n "$TMUX" ]]; then
        change="switch-client"
    else
        change="attach-session"
    fi

    if [ "$1" ]; then
        tmux "$change" -t "$1" 2>/dev/null || (tmux new-session -d -s "$1" && tmux "$change" -t "$1")
        return
    fi

    session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) && tmux "$change" -t "$session" || echo "No sessions found."
}

# get_remote_file function
get_remote_file(){
    rm -f ~/.tmp_allfiles.txt
    ssh "$1" -t "cd \"$2\" && ls **/*.*" >> ~/.tmp_allfiles1.txt
    echo " " >> ~/.tmp_allfiles1.txt
    vi -c "%s/\s\+/\r/g | wq" ~/.tmp_allfiles1.txt
    vi -c "%s#//#/#g | wq" ~/.tmp_allfiles1.txt

    prefix="scp://$1/$2"
    echo "$prefix"
    awk -v prefix="$prefix/" '{print prefix $0}' ~/.tmp_allfiles1.txt >> ~/.tmp_allfiles.txt
    sort ~/.tmp_allfiles.txt | uniq > ~/.tmp_allfiles_sorted.txt
    mv ~/.tmp_allfiles_sorted.txt ~/.tmp_allfiles.txt
    cat ~/.tmp_allfiles.txt
}

# fd function - Find directory projects
fd() {
    local dir
    dir=$(find "${1:-.}" -path '*/\.*' -prune -o -type d -print 2>/dev/null | fzf +m) &&
    cd "$dir"
}

# fkill function
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

    if [ -n "$pid" ]; then
        echo "$pid" | xargs kill -${1:-9}
    fi
}

# download-google function
download-google(){
    echo "Filename: $1"
    echo "FileID: $2"
    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=$2' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1/p')&id=$2" -O "$1" && rm -rf /tmp/cookies.txt
}

# start_docker function
start_docker(){
    cd ~/gitprojects/docker
    echo "CID: $1"
    ./start_docker.sh "$1"
}

# speak-ssh function
speak-ssh(){
    tmux kill-session -t ssh
    /etc/init.d/ssh start
    tssh speak
}

# fh function
fh() {
    eval "$(history | fzf +s --tac | sed -r 's/ *[0-9]*\*? *//; s/\\/\\\\/g')"
}

# tssh function
tssh(){
    local s="
    while true
    do
        echo \"Reconnecting '$1' ssh\"
        sleep 0.1
        ssh $@
    done"
    echo "$s"

    tmux kill-session -t "ssh_$1" 2>/dev/null
    tmux new-session -s "ssh_$1" -d "$s"
}

# fif function
fif() {
    local s=""
    local i=0
    for a in "$@"; do
        if [ "$i" -gt 0 ]; then
            s+=" "
        fi
        i=$((i + 1))
        s+="$a"
    done

    _file=$(grep --line-buffered --color=never -r "$s" * | fzf)
    export _file
    file=$(python -c 'import os; print(os.environ.get("_file", "").split(":")[0])')
    echo "$file"
}

# fiv function
fiv(){
    vi "$(fif "$@")"
}

# fic function
fic(){
    code "$(fif "$@")"
}

# rs-current-dir function
rs-current-dir(){
    local s="rs $1:$(pwd) $(pwd)"
    echo "$s"
}

# kill-all-python-except-jupyter function
kill-all-python-except-jupyter(){
    ps aux | grep -i python | grep -wv jupyter | grep -wv vscode | grep "$USER" | awk '{print $2}' | xargs -r kill -9
}

# kill-all-python-jupyter function
kill-all-python-jupyter(){
    ps aux | grep -i python | grep -wv vscode | awk '{print $2}' | xargs -r kill -9
}

# use-ssh function
use-ssh(){
    local root=$(pwd)
    cd "$HOME/.ssh" || return
    rm -f config
    cp "config_$1" config
    cd "$root" || return
}

# Export PATH
export PATH="$PATH:$HOME/miniconda3/bin"

# rss function
rss(){
    local hostname=$(grep "^Host " ~/.ssh/config | fzf | awk '{print $2}')
    local filename=$(ls | fzf)
    rs "$filename" "$hostname:/"
}

# rsab function
rsab(){
    rs "$1" ~/.cache/sync
    rs ~/.cache/sync "$2"
}

# wget-rs function
wget-rs(){
    local tmp
    tmp=$(mktemp)
    echo "Download $1 into $tmp"
    wget "$1" -O "$tmp"
    rs "$tmp" "$2"
}

# convert2mp4 function
convert2mp4(){
    ffmpeg -i "$1" -c:v vp9 -c:a libvorbis "$2"
}

# ju-convert function
ju-convert(){
    echo "Convert $1 to python"
    jupyter nbconvert "$1" --to python
}

# pyf function
pyf(){
    echo "Sort imports and format $1"
    isort "$1" && black "$1" && vi -c wq "$1"
}

# cu function
cu(){
    export CUDA_VISIBLE_DEVICES="$1"
}

# catssh function
catssh(){
    if [ "$#" -lt 3 ]; then
        echo "Usage: catssh <file> <machine> <target_file>"
        return 1
    fi

    local FILE="$1"
    local MACHINE="$2"
    local TARGET_FILE="$3"
    cat "$FILE" | ssh "$MACHINE" "cat > \"$TARGET_FILE\""
}

# cuda-ls function
cuda-ls () {
    nvidia-smi --query-gpu=index,name,memory.free --format=csv,noheader | sort -t ',' -k3 -nr
}

# start_cmd_in_tmux function
start_cmd_in_tmux() {
    local cmd="no_proxy=\"localhost,127.0.0.1,::1\" $1"
    echo "Starting command: $cmd"
    cmd="$cmd; sleep 1234"
    local tmux_name="vllm_$2"
    if ! tmux has-session -t "$tmux_name" 2>/dev/null; then
        tmux new-session -d -s "$tmux_name" "$cmd"
    else
        echo "Session $tmux_name already exists."
    fi
}

# set-conda-env function
set-conda-env () {
    local file="$HOME/.bashrc"
    local prefix="atv"
    local new_env=""

    new_env=$(conda env list | awk '/^#|^\s*$/ {next} {print $1}' | fzf --prompt "Select conda environment: ")

    if [ -z "$new_env" ]; then
        echo "No environment selected."
        return
    fi

    local new_line="atv $new_env"

    if [ -f "$file" ]; then
        sed -i.bak "/^${prefix}/d" "$file"
        echo "$new_line" >> "$file"
        echo "Deleted line starting with 'atv' and added '$new_line' to $file."
    else
        echo "File $file does not exist."
    fi

    atv "$new_env"
}

# forward_ports function
forward_ports() {
    local port="$1"

    if [ -z "$port" ]; then
        echo "Port number is required."
        return 1
    fi

    ssh kube -L "${port}:localhost:${port}" &
    local SSH_PID=$!

    sleep 2

    kubectl port-forward -n kubeflow-anhvth5 pod/anhvth-0 "${port}:${port}" &
    local KUBECTL_PID=$!

    trap "kill $SSH_PID $KUBECTL_PID" SIGINT SIGTERM

    wait "$KUBECTL_PID"
    wait "$SSH_PID"
}

# fetch_and_open_video function
fetch_and_open_video() {
    local video_path="$1"
    local destination_path="/tmp/video.mp4"
    local quicktime_bin="/Applications/QuickTime Player.app"

    if [ -z "$video_path" ]; then
        echo "Usage: fetch_and_open_video <video_path>"
        return 1
    fi

    echo "Checking if QuickTime Player is running..."
    if pgrep -x "QuickTime Player" > /dev/null; then
        echo "QuickTime Player is running. Closing it first..."
        osascript -e 'tell application "QuickTime Player" to quit'
        sleep 0.1
    fi

    echo "Transferring video..."
    rsync -avzhe ssh --progress "$video_path" "$destination_path"

    if [ $? -ne 0 ]; then
        echo "Failed to transfer video."
        return 1
    fi

    echo "Opening video with QuickTime Player..."
    open "$destination_path"
}

# generate_pylint_report function
generate_pylint_report() {
    rm -f report.md
    > report.md

    while IFS= read -r -d '' file; do
        echo "Running pylint on $file" >> report.md
        pylint --errors-only "$file" >> report.md
        echo -e "\n" >> report.md
    done < <(find . -name "*.py" -print0)

    echo "Error report generated in report.md"
}
export PATH=$HOME/.fzf/bin/:$PATH