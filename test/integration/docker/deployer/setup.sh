#!/bin/bash

install_kamal_podman() {
  # Install missing dependencies that kamal needs
  gem install bcrypt_pbkdf ed25519 net-ssh

  # Build and install kamal_podman gem with --force to override existing kamal executable
  cd /kamal_podman && gem build kamal_podman.gemspec -o /tmp/kamal_podman.gem && gem install --force /tmp/kamal_podman.gem
}

# Push images to local registry to avoid Docker Hub rate limits
push_image_to_registry() {
  local image=$1
  local tag=$2
  local registry_tag="registry:5000/$image:$tag"

  # Only push if not already in registry
  if ! podman pull --tls-verify=false "$registry_tag" > /dev/null 2>&1; then
    echo "Caching $image:$tag to local registry..."
    podman pull "docker.io/$image:$tag"
    podman tag "docker.io/$image:$tag" "$registry_tag"
    podman push --tls-verify=false "$registry_tag"
  else
    echo "$image:$tag already in local registry"
  fi
}

# Wait for SSH keys to be available in shared volume
wait_for_ssh_keys() {
  timeout=30
  while [ $timeout -gt 0 ]; do
    if [ -f /shared/ssh/id_rsa ]; then
      echo "SSH keys found in shared volume"
      break
    fi
    sleep 1
    timeout=$((timeout - 1))
  done

  if [ ! -f /shared/ssh/id_rsa ]; then
    echo "SSH keys not found in shared volume after waiting"
    exit 1
  fi
}

# Test SSH connectivity
test_ssh_connectivity() {
  echo "Testing SSH connectivity to vm1..."
  ssh-keyscan -H vm1 >> /root/.ssh/known_hosts 2>/dev/null || true

  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@vm1 'echo SSH_OK' 2>/dev/null; then
    echo "SSH connection to vm1 successful"
  else
    echo "SSH connection to vm1 failed"
  fi
}

# Run setup steps
install_kamal_podman
wait_for_ssh_keys

# Configure SSH to skip host key verification (containers get new keys each run)
printf 'Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n' > /root/.ssh/config
chmod 600 /root/.ssh/config
rm -f /root/.ssh/known_hosts

test_ssh_connectivity

# Login to local registry
echo "Logging into local registry..."
podman login registry:5000 --username testuser --password testpass --tls-verify=false

# Login to registry from vm1 too (so it can pull images during deploy)
ssh -o StrictHostKeyChecking=no root@vm1 'podman login registry:5000 --username testuser --password testpass --tls-verify=false'

# Pre-cache images to local registry
push_image_to_registry nginx latest
push_image_to_registry basecamp/kamal-proxy v0.9.2

# Test that kamal command works
echo "Testing kamal command..."
if kamal --version > /dev/null 2>&1; then
  echo "kamal command is working"
else
  echo "ERROR: kamal command is not working"
  kamal --version 2>&1 || true
fi

echo "Setup completed successfully"
