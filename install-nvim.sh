sudo rm /usr/bin/nvim
cd /home/ubuntu/dotfiles/bin 
./nvim.appimage --appimage-extract
sudo ln -s $(pwd)/squashfs-root/AppRun /usr/bin/nvim 
echo  $(pwd)/squashfs-root/AppRun /usr/bin/nvim 
cd ~/dotfiles
