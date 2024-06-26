rs-git-sync(){
    x="rsync -avzhe ssh --progress --filter=':- .gitignore' $1 $2 --delete"
    watch $x
}

absp(){
    echo $cname":"$(pwd)/$(fzf)
}

# docker exec $cmd at $containernaim
dke(){
    container_name=$1
    shift
    cmd="$@"
    docker exec -it $container_name $cmd
}
atv() {
  local name=$1
  conda deactivate
  conda activate "$name"
  export env_name="$name"
  echo "$env_name" > ~/.last_env.txt
  echo "Activated: $name"
}


# This function will attach to a tmux session or create one if it doesn't exist
tm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}
get_remote_file(){
    rm ~/.tmp_allfiles.txt
    ssh $1 -t "cd "$2" && ls **/*.*" >> ~/.tmp_allfiles1.txt
    echo " " >> ~/.tmp_allfiles1.txt
    vi -c "%s/\s\+/\r/g | wq" ~/.tmp_allfiles1.txt
    vi -c "%s/
//g | wq" ~/.tmp_allfiles1.txt
    prefix="scp://$1/$2"
    echo $prefix
    awk -v prefix="$prefix""/" '{print prefix $0}' ~/.tmp_allfiles1.txt >> ~/.tmp_allfiles.txt
    cat ~/.tmp_allfiles.txt
    sort .tmp_allfiles.txt | uniq  >> .tmp_allfiles.txt
}

# Find directory projects
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}




fkill() {
  if [ $# -eq 0 ]; then
    echo "Usage: fkill [-signal] - Search for and kill a process interactively"
    echo "Example: fkill -9 - Kill a process with signal 9 (default is 9 if not provided)"
    return 1
  fi

  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}



download-google(){
    echo "Filename:" $1
    echo "FileID:" $2
    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=$2' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$2" -O $1 && rm -rf /tmp/cookies.txt
}

start_docker(){
    cd ~/gitprojects/docker
    echo "CID:" $1
    ./start_docker.sh $1
}
speak-ssh(){
    mux kill-session -t ssh
    /etc/init.d/ssh start
    tssh speak 
}

fh() {
  eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -r 's/ *[0-9]*\*? *//' | sed -r 's/\\/\\\\/g')
}
tssh(){
    s='
    while [ 1 ]
    do
        echo "Reconnecti "'$1'" ssh"
        sleep 0.1
        ssh '$@'
    done' 
    echo $s

    tmux kill-session -t "ssh_"'$1'
    tmux new -s  "ssh_"$1 -d $s
}


fif() {
   s=""
   i=0
   for a in "$@"
   do
       if [ $i -gt 0 ]; then
           # echo $i
           s+=" "
       fi
       i+=1
       s+=$a
   done

    _file=$(grep --line-buffered --color=never -r "$s" * | fzf)
    export _file=$_file
    file=$(python -c 'import os; print(os.environ.get("_file", "").split(":")[0])')
    echo $file
}

fiv(){
    vi $(fif $@)
}
fic(){
    code $(fif $@)
}

rs-current-dir(){
    s="rs $1:$(pwd) $(pwd)"
    echo $s
}

kill-all-python-except-jupyter(){
    ps aux | grep -i python| grep -wv jupyter| grep -wv vscode | grep $USER|awk '{print $2}' | xargs -r kill -9
}

kill-all-python-jupyter(){
     ps aux | grep -i python |grep -wv vscode |awk '{print $2}'| xargs -r kill -9
}

# AG The Silver Searcher



use-ssh(){
    root=$(pwd)
    cd $HOME/.ssh
    rm config
    cp config_$1 config
    cd $root
}

export PATH=$PATH:$HOME/miniconda3/bin

rss(){
hostname=$(cat ~/.ssh/config | grep "Host "| fzf | awk {'print $2'})
filename=$(ls | fzf)
BUFFER="rs $filename $hostname:/"
zle accept-line

}

rsab(){
rs $1 ~/.cache/sync
rs ~/.cache/sync $2

}

wget-rs(){
    tmp=$(mktemp)
    echo "Download $1 in to $tmp"
    wget $1 -O $tmp
    rs $tmp $2
}



convert2mp4(){
    ffmpeg -i $1 -c:v vp9 -c:a libvorbis $2
}


convert2mp4(){
    ffmpeg -i $1 -c:v vp9 -c:a libvorbis $2
}

ju-convert(){
    echo "Convert "$1"To python"
    jupyter nbconvert $1 --to python
}


pyf(){
    echo "Sort import and format "$1
    isort $1 && vi -c YAPF $1 -c wq
}

cu(){
    export CUDA_VISIBLE_DEVICES=$1
}

catssh(){
    # zsh
    # Check if help
    num_of_args=$#
    if [ $num_of_args -lt 3 ]; then
        echo "catssh <file> <machine> <target_file>"
        return
    fi

    FILE=$1
    MACHINE=$2
    TARGET_FILE=$3
    cat $FILE | ssh $MACHINE "cat > $TARGET_FILE"
}


cuda-ls () {
        nvidia-smi --query-gpu=index,gpu_name,memory.free --format=csv,noheader | sort -t ',' -k3 -n -r
}



start_cmd_in_tmux() {
    cmd=no_proxy="localhost,127.0.0.1,::1 "$1
    echo "Starting command: $cmd"
    # add sleep to cmd to avoid exit after failure
    cmd="$cmd; sleep 1234"
    tmux_name="vllm_$2"
    if ! tmux has-session -t "$tmux_name" 2>/dev/null; then
        tmux new-session -d -s "$tmux_name" "$cmd"
    else
        echo "Session $tmux_name already exists."
    fi
}

# Function to set environment in ~/.zshrc.sh
set-conda-env() {
    local file="$HOME/.zshrc"
    local prefix="atv"
    local new_line="atv $1"

    if [ -f "$file" ]; then
        # Delete line starting with "atv"
        sed -i.bak "/^${prefix}/d" "$file"
        # Add the new line "atv $1"
        echo "$new_line" >> "$file"
        echo "Deleted line starting with 'atv' and added '$new_line' to $file."
    else
        echo "File $file does not exist."
    fi
    atv $1
}

function forward_ports() {
  
  local port=$1
  
  if [ -z "$port" ]; then
    echo "Port number is required."
    return 1
  fi

  ssh kube -L ${port}:localhost:${port} &
  SSH_PID=$!
  
  # Give SSH tunnel some time to establish
  sleep 2
  
  kubectl port-forward -n kubeflow-anhvth5 pod/anhvth-0 ${port}:${port} &
  KUBECTL_PID=$!
  
  # Wait for the user to terminate the function
  trap "kill $SSH_PID $KUBECTL_PID" SIGINT SIGTERM
  
  wait $KUBECTL_PID
  wait $SSH_PID
}