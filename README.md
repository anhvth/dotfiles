# Installation
```bash
git clone https://github.com/anhvth/dotfiles ~/dotfiles --single-branch && cd ~/dotfiles && ./install.sh
```


# Alias only
```bash
 wget https://raw.githubusercontent.com/anhvth/dotfiles/master/zsh/alias.sh -O ~/.alias.h && \
 echo "source ~/.alias.h">> ~/.bashrc && \
 git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
 ~/.fzf/install
```
