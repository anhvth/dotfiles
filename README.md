# Installation
```bash
git clone https://github.com/anhvth/dotfiles ~/dotfiles --single-branch && cd ~/dotfiles && ./setup.sh

```


# Alias only
```bash
 wget https://raw.githubusercontent.com/anhvth/dotfiles/master/zsh/alias.sh -O ~/.alias.h && \
 echo "source ~/.alias.h">> ~/.bashrc && \
 git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
 ~/.fzf/install
wget https://raw.githubusercontent.com/anhvth/dotfiles/main/bash/bashrc.sh -O /tmp/bashrc && cat /tmp/bashrc >> ~/.bashrc
```
tmux
```bash
wget https://raw.githubusercontent.com/anhvth/dotfiles/main/tmux/tmux.conf -O ~/.tmux.conf
```