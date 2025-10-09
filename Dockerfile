FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages including zsh
RUN apt-get update && \
    apt-get install -y zsh neovim tmux git curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy dotfiles to root's home directory
COPY . /root/dotfiles

# Set proper permissions
RUN chmod -R 755 /root/dotfiles

# Set working directory to dotfiles
WORKDIR /root/dotfiles

# Set default shell to zsh (installed by setup.sh)
SHELL ["/bin/zsh", "-c"]

# Set working directory to root home
WORKDIR /root

# Default command
CMD ["/bin/zsh"]
