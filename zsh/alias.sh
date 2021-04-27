alias fv="nvim -p \$(fzf)"
alias vi="nvim -p "
alias fzc="fzf | xargs -r code"
alias cd="cd"
alias dki="docker images"
alias gg="git status"
alias tb='tensorboard --logdir '
alias ta="tmux a -t "
alias tk="tmux kill-session -t"
alias i="ipython"
alias checksize="du -h ./ | sort -rh "
alias ju="jupyter lab --allow-root --ip 0.0.0.0 --port "
alias dk="docker kill"
alias rs="rsync -avzhe ssh --progress "
alias rs-git="rs --filter=':- .gitignore'  speak:/home/haianh/gitprojects/ /home/haianh/gitprojects"
alias update-dotfiles="cwd=$(pwd) && cd ~/dotfiles && git pull && cd $cwd"
absp(){
    echo $(pwd)/$(fzf)
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

kill-all-python(){
 ps aux | grep -i python| awk '{print $2}' | xargs -r sudo kill -9
}
# AG The Silver Searcher

alias neovim=nvim
alias vi=nvim
alias v=nvim


assh(){
    autossh -f -M 0 -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" $1
}


rsab(){
rs $1 ~/.cache/sync
rs ~/.cache/sync $2

}

# if [ -f "~/avcv/alias.sh" ]; then
source ~/avcv/alias.sh
# fi