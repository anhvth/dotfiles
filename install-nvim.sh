sudo rm /usr/bin/nvim
cd /home/ubuntu/dotfiles/bin 
./nvim.appimage --appimage-extract
sudo ln -s $(pwd)/squashfs-root/AppRun $HOME/dotfiles/tools/bin/nvim
echo  $(pwd)/squashfs-root/AppRun $HOME/dotfiles/tools/bin/nvim
cd ~/dotfiles
