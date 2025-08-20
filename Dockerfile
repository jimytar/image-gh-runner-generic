FROM debian:12.7-slim

ENV DEBIAN_FRONTEND=noninteractive
ARG USER=runner
ARG RUNNER_VERSION=2.328.0
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.7.0
ARG DOCKER_VERSION=27.4.0
ARG DOCKER_COMPOSE_VERSION=2.31.0
ARG NODE=20.17.0
ARG TERRAFORM=1.9.8
ARG USER=runner
ARG KUBECTL=1.30.6
ARG HELM=3.16.2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    curl \
    wget \
    git \
    unzip \
    jq \
    rclone \
    tree \
    rsync \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    python3-full \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Set up GitHub runner user
RUN adduser --disabled-password --gecos "" --uid 1001 ${USER} \
    && groupadd docker --gid 123 \
    && usermod -aG sudo ${USER} \
    && usermod -aG docker ${USER} \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

WORKDIR /home/${USER}

# Install Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    . /etc/os-release && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    docker-ce-cli=5:"${DOCKER_VERSION}-1~${ID}.${VERSION_ID}~${VERSION_CODENAME}" \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin="${DOCKER_COMPOSE_VERSION}-1~${ID}.${VERSION_ID}~${VERSION_CODENAME}" && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub Actions runner and container hooks k8s
RUN curl -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm runner-container-hooks.zip

# Switch to the runner user
USER ${USER}

# Install asdf and configure the environment
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1 \
    && echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc \
    && echo ". $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc

ENV ASDF_DIR="/home/${USER}/.asdf"
ENV PATH="$ASDF_DIR/bin:$ASDF_DIR/shims:$PATH"

# Install node
RUN asdf plugin add nodejs \
    && asdf install nodejs ${NODE} \
    && asdf global nodejs ${NODE}

# Install terraform
RUN asdf plugin add terraform \
    && asdf install terraform ${TERRAFORM} \
    && asdf global terraform ${TERRAFORM}

# Install kubectl
RUN asdf plugin add kubectl \
    && asdf install kubectl ${KUBECTL} \
    && asdf global kubectl ${KUBECTL}

# Install Helm
RUN asdf plugin add helm \
    && asdf install helm ${HELM} \
    && asdf global helm ${HELM}
  