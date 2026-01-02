# Base image from devcontainer specification
FROM mcr.microsoft.com/devcontainers/base:noble

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Define user parameters
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Update package lists and upgrade existing packages
RUN apt-get update && apt-get upgrade -y

# Install common dependencies
RUN apt-get install -y \
    apt-transport-https \
    ca-certificates \
    openssl \
    curl \
    gnupg \
    lsb-release \
    sudo \
    zsh \
    git \
    vim \
    nano \
    wget \
    unzip \
    software-properties-common

# ============================================================================
# USER AND GROUP SETUP
# ============================================================================
# Create or update the non-root user and set up sudo
RUN if id "$USERNAME" >/dev/null 2>&1; then \
        usermod -u $USER_UID -g $USER_GID $USERNAME; \
    else \
        groupadd --gid $USER_GID $USERNAME && \
        useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME; \
    fi && \
    # Set up sudo for the user
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    # Install Oh My Zsh for the non-root user and set zsh as default shell
    usermod -s /bin/zsh $USERNAME || true

# ============================================================================
# ROOT USER SETUP
# ============================================================================

# Need to figure out minimal docker-in-docker setup later
# # Install Docker/Moby engine
# RUN mkdir -p /etc/apt/keyrings && \
#     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
#     echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
#     tee /etc/apt/sources.list.d/docker.list > /dev/null && \
#     apt-get update && \
#     apt-get install -y docker-ce containerd.io

COPY mkcachedir.sh /tmp/mkcachedir.sh
RUN chmod 500 /tmp/mkcachedir.sh
RUN /tmp/mkcachedir.sh azure $USERNAME /home/$USERNAME/.azure
RUN /tmp/mkcachedir.sh github-cli $USERNAME /home/$USERNAME/.config/gh
RUN /tmp/mkcachedir.sh pulumi $USERNAME /home/$USERNAME/.pulumi
RUN rm /tmp/mkcachedir.sh

###############################################################################
# USER-SPECIFIC SETUP
###############################################################################
USER $USERNAME

RUN rm ~/.zshrc

SHELL ["/bin/zsh", "-c"]

# Install Antidote Zsh plugin manager
RUN git clone --depth=1 https://github.com/mattmc3/antidote ~/.antidote
COPY .zsh_plugins.txt /home/$USERNAME/.zsh_plugins.txt
RUN source ~/.antidote/antidote.zsh && antidote bundle < ~/.zsh_plugins.txt > ~/.zsh_plugins.zsh
COPY .zshrc /home/$USERNAME/.zshrc.antidote
RUN cat ~/.zshrc.antidote >> /home/$USERNAME/.zshrc && rm ~/.zshrc.antidote
COPY .p10k.zsh /home/$USERNAME/.p10k.zsh
RUN mkdir -p ~/.local/state/shell

# Homebrew
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'source <(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.zshrc 

COPY mise.toml /home/$USERNAME/.config/mise/config.toml

# mise
RUN source <(/home/linuxbrew/.linuxbrew/bin/brew shellenv) && \
    brew install mise && \
    echo 'export PATH="$HOME/.local/share/mise/shims:$PATH"' >> ~/.zshrc && \
    echo 'source <(mise activate zsh)' >> ~/.zshrc
RUN source <(/home/linuxbrew/.linuxbrew/bin/brew shellenv) && \
    source <(mise activate zsh) && \
    mise install

# ZSH customizations
RUN echo "setopt HIST_IGNORE_SPACE" >> ~/.zshrc

USER root

# Clean up
RUN apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Set the default user
USER $USERNAME

WORKDIR /workspace
