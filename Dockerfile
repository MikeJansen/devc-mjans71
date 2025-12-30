# Base image from devcontainer specification
FROM mcr.microsoft.com/devcontainers/base:noble

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Define user parameters
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG GO_VERSION=1.21.5
ARG NVM_VERSION=0.39.7
ARG NODE_VERSION=lts/*
ARG JQ_VERSION=1.7
ARG YQ_VERSION=v4.40.4

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
    software-properties-common \
    fzf 

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
    su - $USERNAME -c 'sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' && \
    usermod -s /bin/zsh $USERNAME || true

# ============================================================================
# ROOT USER SETUP
# ============================================================================

# Install Azure CLI with Bicep support
RUN (curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash) && \
    az bicep install

# Install GitHub CLI
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh

# Install Go and golangci-lint
RUN ARCH=$(dpkg --print-architecture) && \
    wget -O /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz && \
    # Install golangci-lint
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin

ENV PATH="/usr/local/go/bin:${PATH}"

# Install kubectl, helm, and minikube
RUN ARCH=$(dpkg --print-architecture) && \
    # Install kubectl
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl && \
    # Install helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    # Install minikube
    curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${ARCH}" && \
    install minikube-linux-${ARCH} /usr/local/bin/minikube && \
    rm minikube-linux-${ARCH}

# Install Docker/Moby engine, Docker Compose v2, Docker Buildx
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create cache directory and set up symlink structure for Azure CLI persistence
RUN mkdir -p /dc/azure && \
    chown -R $USERNAME:$USERNAME /dc/azure && \
    chmod 700 /dc/azure && \
    ln -sf /dc/azure /home/$USERNAME/.azure && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.azure && \
    chmod 700 /home/$USERNAME/.azure

# Create cache directory and set up symlink structure for GitHub CLI persistence
RUN mkdir -p /dc/github-cli && \
    chown -R $USERNAME:$USERNAME /dc/github-cli && \
    chmod 700 /dc/github-cli && \
    ln -sf /dc/github-cli /home/$USERNAME/.config/gh && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/gh && \
    chmod 700 /home/$USERNAME/.config/gh

# Install Azure Developer CLI (azd)
RUN curl -fsSL https://aka.ms/install-azd.sh | bash -s -- --version stable -a $(dpkg --print-architecture)

# Install jq and yq utilities
RUN ARCH=$(dpkg --print-architecture) && \
    # Install jq
    curl -sL "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${ARCH}" -o /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq && \
    # Install yq
    curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}" -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# Install uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh


# Install python
RUN apt-get install -y python3.12 python3.12-venv && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# k9s
RUN curl -s https://api.github.com/repos/derailed/k9s/releases/latest | \
    jq -r '.assets[] | select(.name | contains("k9s_linux_arm64.deb")) | .browser_download_url' | \
    xargs curl -LO && \
    dpkg -i k9s_linux_arm64.deb && \
    rm k9s_linux_arm64.deb

###############################################################################
# USER-SPECIFIC SETUP
###############################################################################
USER $USERNAME

RUN rm ~/.zshrc

# Install NVM, Node.js
RUN curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
    nvm install ${NODE_VERSION} && \
    nvm use ${NODE_VERSION} && \
    nvm alias default ${NODE_VERSION} && \
    echo "NVM_DIR=\"$HOME/.nvm\"" >> "$HOME/.zshrc" && \
    echo "[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\" # This loads nvm" >> "$HOME/.zshrc" && \
    echo "[ -s \"$NVM_DIR/bash_completion\" ] && \. \"$NVM_DIR/bash_completion\" # This loads nvm bash_completion" >> "$HOME/.zshrc" && \
    npm install -g pnpm

# Install GitHub Copilot VS Code extension CLI
RUN export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
    npm install -g @github/copilot

# Install Antidote Zsh plugin manager
RUN git clone --depth=1 https://github.com/mattmc3/antidote ~/.antidote
COPY .zsh_plugins.txt /home/$USERNAME/.zsh_plugins.txt
RUN zsh -c 'source ~/.antidote/antidote.zsh && antidote bundle < ~/.zsh_plugins.txt > ~/.zsh_plugins.zsh'
COPY .zshrc /home/$USERNAME/.zshrc.antidote
RUN cat /home/$USERNAME/.zshrc.antidote >> /home/$USERNAME/.zshrc && rm /home/$USERNAME/.zshrc.antidote
COPY .p10k.zsh /home/$USERNAME/.p10k.zsh
RUN mkdir -p "${HOME}/.local/state/shell"

# Homebrew
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.zshrc 

# pulumi
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && \
    brew tap pulumi/tap && \
    brew install pulumi/tap/pulumi && \
    brew install pulumi/tap/esc

# pre-commit
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && \
    brew install pre-commit

# ZSH customizations
RUN echo "setopt HIST_IGNORE_SPACE" >> /home/$USERNAME/.zshrc

USER root

# Clean up
RUN apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Set the default user
USER $USERNAME

# Set default shell to zsh
ENV SHELL=/bin/zsh

WORKDIR /workspace
