rs-git-sync() {
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
    if [ -d "$1" ]; then
        cd "$1"
    elif [ -f "$1" ]; then
        cd "$(dirname "$1")"
    else
        echo "\e[31m$1 is not a valid file or directory\e[0m" # Red text for errors
        return 1
    fi
    echo "\e[32mcd to $(pwd)\e[0m" # Green text for success
    ls
}

# p() {
#     CUDA_VISIBLE_DEVICES=$1 python
# }

# j() {
#     CUDA_VISIBLE_DEVICES=$1 jupyter lab
# }
docker-run() {
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

    if docker ps -a | grep $CONTAINER_NAME; then
        echo "Restart " $CONTAINER_NAME
        docker kill $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    else
        echo "Start " $CONTAINER_NAME
    fi
    docker run --name $CONTAINER_NAME -it -p $2:8888 \
        -v $(pwd):/docker-container/ \
        -v $HISTORY_FILE:/root/.zsh_history \
        --rm \
        $DOCKER_ACTIVE_IMAGE /bin/zsh
}

docker-attatch() {
    echo "Which container do you want to attach"
    docker ps -a
    read container_name
    echo "Attatch" $container_name
    docker attach $container_name
}

docker-commit() {
    docker commit $DOCKER_ACTIVE_CONTAINER $DOCKER_ACTIVE_IMAGE
    echo "Would you like to push "$DOCKER_ACTIVE_IMAGE " image to the cloud (y/n)"
    read answer

    if echo $answer | grep -iq "^y"; then
        echo "Push " $DOCKER_ACTIVE_IMAGE
        docker push $DOCKER_ACTIVE_IMAGE
    fi
}

docker-kill() {
    docker kill $(docker ps -qa)
    docker rm $(docker ps -qa)
}

tm() {
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
    if [ $1 ]; then
        tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1")
        return
    fi
    session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) && tmux $change -t "$session" || echo "No sessions found."
}
get_remote_file() {
    rm ~/.tmp_allfiles.txt
    ssh $1 -t "cd "$2" && ls **/*.*" >>~/.tmp_allfiles1.txt
    echo " " >>~/.tmp_allfiles1.txt
    vi -c "%s/\s\+/\r/g | wq" ~/.tmp_allfiles1.txt
    vi -c "%s/
//g | wq" ~/.tmp_allfiles1.txt
    prefix="scp://$1/$2"
    echo $prefix
    awk -v prefix="$prefix""/" '{print prefix $0}' ~/.tmp_allfiles1.txt >>~/.tmp_allfiles.txt
    cat ~/.tmp_allfiles.txt
    sort .tmp_allfiles.txt | uniq >>.tmp_allfiles.txt
}

# Find directory projects
fd() {
    local dir
    dir=$(find ${1:-.} -path '*/\.*' -prune \
        -o -type d -print 2>/dev/null | fzf +m) &&
        cd "$dir"
}

fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

    if [ "x$pid" != "x" ]; then
        echo $pid | xargs kill -${1:-9}
    fi
}



# start_docker() {
#     cd ~/gitprojects/docker
#     echo "CID:" $1
#     ./start_docker.sh $1
# }
# speak-ssh() {
#     mux kill-session -t ssh
#     /etc/init.d/ssh start
#     tssh speak
# }

fh() {
    # This function uses fzf to select a command from the history and executes it.
    eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -r 's/ *[0-9]*\*? *//' | sed -r 's/\\/\\\\/g')
}
tssh() {
    s='
    while [ 1 ]
    do
        echo "Reconnecti "'$1'" ssh"
        sleep 0.1
        ssh '$@'
    done'
    echo $s

    tmux kill-session -t "ssh_"'$1'
    tmux new -s "ssh_"$1 -d $s
}

fif() {
    s=""
    i=0
    for a in "$@"; do
        if [ $i -gt 0 ]; then
            # echo $i
            s+=" "
        fi
        i+=1
        s+=$a
    done

    _file=$(grep --line-buffered --color=never -I -r "$s" * | fzf)
    export _file=$_file
    file=$(python -c 'import os; print(os.environ.get("_file", "").split(":")[0])')
    echo $file
}

fiv() {
    vi $(fif $@)
}
fic() {
    code $(fif $@)
}

rs-current-dir() {
    s="rs $1:$(pwd) $(pwd)"
    echo $s
}

kill-all-python-except-jupyter() {
    ps aux | grep -i python | grep -wv jupyter | grep -wv vscode | grep $USER | awk '{print $2}' | xargs -r kill -9
}

kill-all-python-jupyter() {
    ps aux | grep -i python | grep -wv vscode | awk '{print $2}' | xargs -r kill -9
}

# AG The Silver Searcher

use-ssh() {
    root=$(pwd)
    cd $HOME/.ssh
    rm config
    cp config_$1 config
    cd $root
}

ju-convert() {
    echo "Convert "$1"To python"
    jupyter nbconvert $1 --to python
}

pyf() {
    echo "Sort import and format "$1
    isort $1 && black $1 && vi -c wq $1
}

cu() {
    export CUDA_VISIBLE_DEVICES=$1
}

cuda-ls() {
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

generate_pylint_report() {
    # Remove the existing report file if it exists
    rm -f report.md
    # Create a new report file
    >report.md

    # Find all Python files and run pylint with --errors-only
    for file in $(find . -name "*.py"); do
        echo "Running pylint on $file" >>report.md
        pylint --errors-only "$file" >>report.md
        echo -e "\n" >>report.md
    done

    echo "Error report generated in report.md"
}

rp() {
    if [ -z "$1" ]; then
        realpath "$(fzf)"
    else
        realpath "$1"
    fi
}

update_dotfiles() {
    # Update the dotfiles repository
    cd ~/dotfiles && git pull
    echo "Successfully updated dotfiles repository."
    source ~/.zshrc
}

# ZSH Autosuggestions toggle functions

autosuggestions_toggle() {
    local target="$HOME/.zshrc"
    local line="source \$HOME/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    # if the line is not in target create one
    if ! grep -q "$line" "$target"; then
        echo "Line not found in $target, adding it now."
        echo "$line" >>"$target"
        return
    fi
    if grep -q "^[^#]*$line" "$target"; then
        # Line is uncommented, comment it
        sed -i "s|^\($line\)|#\1|" "$target"
    else
        # Line is commented, uncomment it
        sed -i "s|^#\($line\)|\1|" "$target"
    fi
}

init_copilot_instruction() {
    local initfile="$HOME/dotfiles/.github/copilot-instructions.md"
    local targetdir=".github"
    local targetfile="$targetdir/copilot-instructions.md"
    echo "Copying $initfile to $targetfile"

    # Check if the source file exists
    if [ ! -f "$initfile" ]; then
        echo "Source file $initfile does not exist."
        return 1
    fi

    # Ensure the target directory exists
    mkdir -p "$targetdir"

    cp "$initfile" "$targetfile"
}

test_proxy() {
    output=$(curl -x 127.0.0.1:$1 https://www.google.com -I)
    if echo "$output" | grep -q "200"; then
        echo "Proxy is working"
    else
        echo "Proxy is not working"
    fi
}

keep_ssh() {
    export AUTOSSH_GATETIME=0
    export AUTOSSH_PORT=0
    export AUTOSSH_PIDFILE=/tmp/autossh.pid

    autossh -f -M 0 \
        -NT \
        -o "ServerAliveInterval=30" \
        -o "ServerAliveCountMax=3" \
        -o "ExitOnForwardFailure=yes" \
        $1
}



#------------------------------------------
# Functions
#------------------------------------------
# Environment variable management
set_env() {
	local varname=$1
	local value=$2

	if [ -z "$varname" ] || [ -z "$value" ]; then
		echo "Usage: set_env <varname> <value>"
		return 1
	fi

	# Remove existing entry for the variable
	if grep -q "^${varname}=" ~/.env; then
		sed -i.bak "/^${varname}=/d" ~/.env
	fi

	# Add the new value
	echo "${varname}=${value}" >> ~/.env
	echo "Set ${varname}=${value} in ~/.env"
}

unset_env() {
	local varname=$1

	if [ -z "$varname" ]; then
		echo "Usage: unset_env <varname>"
		return 1
	fi

	# Remove the entry for the variable
	if grep -q "^${varname}=" ~/.env; then
		sed -i.bak "/^${varname}=/d" ~/.env
		echo "Unset ${varname} from ~/.env"
	else
		echo "${varname} not found in ~/.env"
	fi
}

# Alias management
set_alias() {
	local aliasname=$1
	local command=$2

	if [ -z "$aliasname" ] || [ -z "$command" ]; then
		echo "Usage: set_alias <aliasname> <command>"
		return 1
	fi

	local alias_file="$HOME/dotfiles/zsh/alias.sh"
	
	# Remove existing alias if it exists
	if grep -q "^alias ${aliasname}=" "$alias_file"; then
		sed -i.bak "/^alias ${aliasname}=/d" "$alias_file"
	fi

	# Add the new alias
	echo "alias ${aliasname}=\"${command}\"" >> "$alias_file"
	
	# Source the alias file to make it immediately available
	source "$alias_file"
	
	echo "Set alias ${aliasname}=\"${command}\" in $alias_file"
}

timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

# Helper functions for managing performance
zsh_reload() {
    echo "🔄 Reloading zsh configuration..."
    source ~/.zshrc
    echo "✅ Done!"
}

zsh_fast() {
    echo "🚀 Switching to fast mode..."
    export ZSH_FAST_MODE=1
    exec zsh
}

zsh_full() {
    echo "🐌 Switching to full mode..."
    unset ZSH_FAST_MODE
    exec zsh
}

zsh_bench() {
    echo "📊 Running zsh startup benchmark..."
    $HOME/dotfiles/zsh/benchmark.sh
}

zsh_enable_suggestions() {
    echo "💡 Enabling autosuggestions..."
    if [[ ! -f ~/.zsh_suggestions_enabled ]]; then
        touch ~/.zsh_suggestions_enabled
        source $HOME/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
        echo "✅ Autosuggestions enabled!"
    else
        echo "ℹ️  Autosuggestions already enabled"
    fi
}

zsh_disable_suggestions() {
    echo "🚫 Disabling autosuggestions..."
    rm -f ~/.zsh_suggestions_enabled
    echo "✅ Autosuggestions disabled! Restart zsh to take effect."
}



my-autossh() {
    hostname="$1"
    force_restart=true
    # check if restart is forced
    if [ "$force_restart" = true ]; then
        echo "Force restart is enabled. Stopping any existing autossh connections."
        pkill -f "autossh.*$hostname"
    fi

    if [ -z "$hostname" ]; then
        echo "Usage: connect_to_host <hostname>"
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
