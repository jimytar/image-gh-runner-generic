FROM debian:12.7-slim

ENV DEBIAN_FRONTEND=noninteractive

ARG USER=runner
ARG RUNNER_VERSION=2.319.1
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.6.1
ARG NODE=20.17.0
ARG TERRAFORM=1.9.6

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

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh \
    && sh get-docker.sh \
    && rm -rf /var/lib/apt/lists/*


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
RUN asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git \
    && asdf install nodejs ${NODE} \
    && asdf global nodejs ${NODE}

# Install terraform
RUN asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git \
    && asdf install terraform ${TERRAFORM} \
    && asdf global terraform ${TERRAFORM}
