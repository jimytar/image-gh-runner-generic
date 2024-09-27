# Base image
FROM ghcr.io/actions/actions-runner:latest
# Update the package list and install required packages
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    rclone \
    tree \
    jq \
    unzip \
    rsync \
    ca-certificates \
    gnupg \
    lsb-release \
    && sudo rm -rf /var/lib/apt/lists/*

# Install asdf and configure the environment
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1 \
    && echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc \
    && echo ". $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc

ENV ASDF_DIR="/home/runner/.asdf"
ENV PATH="$ASDF_DIR/bin:$ASDF_DIR/shims:$PATH"

# Install node 20.17.0
RUN asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git && \
    asdf install nodejs 20.17.0 && \
    asdf global nodejs 20.17.0
