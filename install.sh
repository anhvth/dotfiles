#/bin/bash/
if [ -x "$(command -v brew)" ]; then
    install_command="brew install " 
    os="mac"
elif [ -x "$(command -v )" ]; then
    install_command=" sudo apt-get install -y "
    os="-ubuntu"
     apt-get update
	 add-apt-repository ppa:neovim-ppa/stable
	 dpkg -i ripgrep_11.0.2_amd64.deb
else
    os="ubuntu"
    apt-get update
    install_command="sudo apt-get install -y "
	dpkg -i ./bin/ripgrep_11.0.2_amd64.deb
fi
echo "use install command:"$install_command

prompt_install() {
	cmd=$install_command" "$1" "
	echo "Installing with cmd: "$cmd
    eval $cmd
}

check_for_software() {
	echo "Checking to see if $1 is installed"
	if ! [ -x "$(command -v $1)" ]; then
		prompt_install $1
	else
		echo "$1 is installed."
	fi
}

echo "We're going to do the following:"
echo "1. Check to make sure you have zsh, vim, and tmux installed"
echo "2. We'll help you install them if you don't"
echo "3. We're going to check to see if your default shell is zsh"
echo "4. We'll try to change it if it's not" 

check_for_software curl
check_for_software zsh
check_for_software neovim
check_for_software tmux
# check_default_shell

printf "source '$HOME/dotfiles/zsh/zshrc_manager.sh'" > ~/.zshrc
if [ -d "~/.config/nvim/" ]; then
	rm -r ~/.config/nvim/
fi
mkdir -p ~/.config/nvim/
printf "so $HOME/dotfiles/vim/nvimrc.vim" > ~/.config/nvim/init.vim
printf "source-file $HOME/dotfiles/tmux/tmux.conf" > ~/.tmux.conf

curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# Install ripget

if [ $os == "mac" ] 
then
    brew install ripgrep
else 
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.2/ripgrep_11.0.2_amd64.deb
    if [ $os == "ubuntu" ] 
    then
        apt-get install ripgrep_11.0.2_amd64.deb -y
    else
         apt-get install ripgrep_11.0.2_amd64.deb -y
    fi
fi



git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 
 ~/.fzf/install
check_for_software silversearcher-ag
sh $HOME/dotfiles/vim/install.sh
chsh -s /bin/zsh

git config --global user.email "anhvth.226@gmail.com"
git config --global user.name "anh vo"   
git config --global core.editor "vim"
