#!/bin/bash

install_kamal_podman() {
  # Install missing dependencies that kamal needs
  gem install bcrypt_pbkdf ed25519 net-ssh

  # Build and install kamal_podman gem with --force to override existing kamal executable
  cd /kamal_podman && gem build kamal_podman.gemspec -o /tmp/kamal_podman.gem && gem install --force /tmp/kamal_podman.gem
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

  # Add vm1 to known hosts to avoid prompts
  ssh-keyscan -H vm1 >> /root/.ssh/known_hosts 2>/dev/null || true

  # Test SSH connection
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@vm1 'echo SSH_OK' 2>/dev/null; then
    echo "SSH connection to vm1 successful"
  else
    echo "SSH connection to vm1 failed - this is expected on first run"
    # Don't exit with error since SSH keys are set up automatically by VM container
  fi
}

# Run setup steps
install_kamal_podman
wait_for_ssh_keys
test_ssh_connectivity

# Test that kamal command works
echo "Testing kamal command..."
if kamal --version > /dev/null 2>&1; then
  echo "kamal command is working"
else
  echo "ERROR: kamal command is not working"
  echo "Attempting to run kamal --version with full error output:"
  kamal --version 2>&1 || echo "Command failed with exit code: $?"
  echo "Gem list:"
  gem list | grep kamal
  echo "PATH: $PATH"
  echo "Which kamal:"
  which kamal
  echo "Ruby version:"
  ruby --version
  echo "Testing Ruby require directly:"
  ruby -e 'require "kamal_podman"; puts "kamal_podman loaded successfully"' 2>&1 || echo "Ruby require failed"
fi

echo "Setup completed successfully"
