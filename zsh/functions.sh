rs-git-sync(){
    x="rsync -avzhe ssh --progress --filter=':- .gitignore' $1 $2 --delete"
    watch $x
}

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


c() {
    cd $1;
    ls;
}
p(){
    CUDA_VISIBLE_DEVICES=$1 python
}

j(){
    CUDA_VISIBLE_DEVICES=$1 jupyter lab
}
docker-run(){
	HISTORY_FILE=${HOME}'/docker-history/'${PWD}
#	HISTORY_FILE=$(pwd)/$DOCKER_ACTIVE_CONTAINER
	if [ ! -f HISTORY_FILE ]; then
		mkdir -p ${HOME}/'docker-history'
		touch $HISTORY_FILE
	fi	
	if [ -n "$1" ]; then
		CONTAINER_NAME=$1
	else
		CONTAINER_NAME=$DOCKER_ACTIVE_CONTAINER
	fi	

	if docker ps -a | grep $CONTAINER_NAME	;then
		echo "Restart " $CONTAINER_NAME	
		docker kill $CONTAINER_NAME	
		docker rm $CONTAINER_NAME	
	else
		echo "Start " $CONTAINER_NAME	
	fi
	docker run --name $CONTAINER_NAME -it -p $2:8888 \
		-v `pwd`:/docker-container/   \
		-v $HISTORY_FILE:/root/.zsh_history \
		--rm \
		$DOCKER_ACTIVE_IMAGE /bin/zsh
}

docker-attatch(){
	echo "Which container do you want to attach"
	docker ps -a
	read container_name	
	echo "Attatch" $container_name
	docker attach $container_name
}

docker-commit(){
	docker commit $DOCKER_ACTIVE_CONTAINER $DOCKER_ACTIVE_IMAGE
	echo "Would you like to push "$DOCKER_ACTIVE_IMAGE " image to the cloud (y/n)"
	read answer

	if echo $answer | grep -iq "^y"; then
		echo "Push " $DOCKER_ACTIVE_IMAGE
		docker push $DOCKER_ACTIVE_IMAGE
	fi
}

docker-kill(){
	docker kill $(docker ps -qa)
	docker rm $(docker ps -qa)
}


atv(){
	conda deactivate
    name=$1
	conda activate $name
    export env_name=$name
    echo $env_name > ~/.last_env.txt
    echo "Activated:"$name
}

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
    isort $1 && black $1 && vi -c wq $1
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




# Add this function to your .bashrc, .zshrc, or another appropriate shell configuration file

function fetch_and_open_video() {
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
        sleep 0.1  # Give some time for QuickTime Player to quit
    fi

    echo "Transferring video..."
    rsync -avzhe ssh --progress "$video_path" "$destination_path"

    if [ $? -ne 0 ]; then
        echo "Failed to transfer video."
        return 1
    fi

    echo "Opening video with QuickTime Player..."
    open $destination_path
}


