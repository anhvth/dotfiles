# sudo apt-get update && install curl
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#nvim + PlugInstall
nvim +'PlugInstall --sync' +qa

