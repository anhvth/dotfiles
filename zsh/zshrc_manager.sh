time_out () { perl -e 'alarm shift; exec @ARGV' "$@"; }
source $HOME/dotfiles/zsh/mygroup.sh
source $HOME/dotfiles/zsh/zshrc.sh
export PATH=$PATH:~/dotfiles/bin

