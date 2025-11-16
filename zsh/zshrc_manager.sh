time_out () { perl -e 'alarm shift; exec @ARGV' "$@"; }
source $HOME/dotfiles/zsh/zshrc.sh
export PATH=$PATH:~/dotfiles/bin

# Lazy conda loading to avoid startup overhead
conda() {
    unset -f conda
    source "/mnt/disk1/anhvth8/miniconda3/etc/profile.d/conda.sh"
    conda "$@"
}

# Optional: lazy activate function
cact() {
    source "/mnt/disk1/anhvth8/miniconda3/etc/profile.d/conda.sh"
    conda activate "$@"
}

