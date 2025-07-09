FROM ubuntu:22.04

# Set environment to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update and install essential packages
RUN apt-get update && \
    apt-get install -y \
    openssh-server \
    curl \
    git \
    sudo \
    systemd \
    systemd-sysv \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Podman
RUN apt-get update && \
    apt-get install -y podman && \
    rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Create root SSH directory and link authorized_keys from shared volume
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    ln -s /shared/ssh/id_rsa.pub /root/.ssh/authorized_keys

# Configure Podman
RUN mkdir -p /etc/containers && \
    echo 'unqualified-search-registries = ["docker.io"]' > /etc/containers/registries.conf

# Create a simple health check script
RUN echo '#!/bin/bash\necho "VM is healthy"' > /health_check.sh && \
    chmod +x /health_check.sh

# Configure systemd
RUN systemctl enable ssh

# Add health check that ensures SSH is running
HEALTHCHECK --interval=1s CMD pgrep sshd

# Expose SSH port
EXPOSE 22

# Use systemd as init system
CMD ["/lib/systemd/systemd"]
