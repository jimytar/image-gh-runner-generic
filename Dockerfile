FROM debian:12.7-slim

ENV DEBIAN_FRONTEND=noninteractive

ARG USER=runner
ARG RUNNER_VERSION=2.319.1
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.6.1
ARG DOCKER_VERSION=27.3.1

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
    && rm -rf /var/lib/apt/lists/*

# Set up GitHub runner user
RUN adduser --disabled-password --gecos "" --uid 1001 ${USER} \
    && groupadd docker --gid 123 \
    && usermod -aG sudo ${USER} \
    && usermod -aG docker ${USER} \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

WORKDIR /home/${USER}

# Install Docker
RUN curl -fLo docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
    && tar zxvf docker.tgz \
    && rm -rf docker.tgz \
    && install -o root -g root -m 755 docker/* /usr/bin/ \
    && rm -rf docker

# Install GitHub Actions runner and container hooks
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

# Install node 20.17.0
RUN asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git \
    && asdf install nodejs 20.17.0 \
    && asdf global nodejs 20.17.0
