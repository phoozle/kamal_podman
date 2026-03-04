FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Update and install essential packages including systemd (needed for Quadlet)
RUN apt-get update && \
    apt-get install -y \
    systemd systemd-sysv \
    openssh-server \
    curl \
    ca-certificates \
    podman \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    printf '\nPermitRootLogin yes\nPubkeyAuthentication yes\nPasswordAuthentication no\n' >> /etc/ssh/sshd_config && \
    systemctl enable ssh

# Create root SSH directory and link authorized_keys from shared volume
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    ln -s /shared/ssh/id_rsa.pub /root/.ssh/authorized_keys

# Configure Podman for running inside Docker (cgroupfs manager, no events logger)
RUN mkdir -p /etc/containers && \
    printf 'unqualified-search-registries = ["docker.io"]\n\n[[registry]]\nlocation = "registry:5000"\ninsecure = true\n' > /etc/containers/registries.conf && \
    printf '[engine]\ncgroup_manager = "cgroupfs"\nevents_logger = "file"\n\n[containers]\npids_limit = 0\n' > /etc/containers/containers.conf

# Ensure quadlet directory exists for systemd integration
RUN mkdir -p /etc/containers/systemd

# Mask unnecessary systemd services to speed up boot
RUN systemctl mask \
    systemd-resolved.service \
    systemd-networkd.service \
    systemd-networkd-wait-online.service \
    systemd-timesyncd.service

HEALTHCHECK --interval=2s --start-period=5s CMD systemctl is-active ssh.service --quiet

EXPOSE 22

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
