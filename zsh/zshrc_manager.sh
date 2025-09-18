time_out () { perl -e 'alarm shift; exec @ARGV' "$@"; }
source $HOME/dotfiles/zsh/zshrc.sh
export PATH=$PATH:~/dotfiles/bin
# Auto-activation handled by _venv_auto_startup in venv.sh