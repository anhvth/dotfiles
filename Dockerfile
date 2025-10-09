FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install sudo and other basic dependencies
RUN apt-get update && \
    apt-get install -y sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a user named 'user' with password '1'
RUN useradd -m -s /bin/bash user && \
    echo "user:1" | chpasswd && \
    usermod -aG sudo user

# Copy dotfiles to the user's home directory
COPY --chown=user:user . /home/user/dotfiles

# Set proper permissions
RUN chmod -R 755 /home/user/dotfiles

# Switch to the created user
USER user
WORKDIR /home/user/dotfiles

# Set default shell to bash for compatibility
SHELL ["/bin/bash", "-c"]

# Run setup script (using setup_noninteractive.sh if available, otherwise setup.sh)
RUN if [ -f setup_noninteractive.sh ]; then \
        bash setup_noninteractive.sh -y || true; \
    elif [ -f setup.sh ]; then \
        bash setup.sh -y || true; \
    fi

# Set working directory to user home
WORKDIR /home/user

# Default command
CMD ["/bin/bash"]
