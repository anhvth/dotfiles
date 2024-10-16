# Installation
```bash
git clone https://github.com/anhvth/dotfiles ~/dotfiles --single-branch && cd ~/dotfiles && ./setup.sh

```


# Alias only
```bash
wget https://raw.githubusercontent.com/anhvth/dotfiles/master/bash/bashrc.sh -O ~/.alias.h

echo "source ~/.alias.h" >> ~/.bashrc


rm -rf ~/.fzf

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

~/.fzf/install

```
tmux
```bash
wget https://raw.githubusercontent.com/anhvth/dotfiles/main/tmux/tmux.conf -O ~/.tmux.conf
```