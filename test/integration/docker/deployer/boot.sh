#!/bin/bash
set -e

echo "Starting deployer boot process..."

# Wait for shared volume to be ready
while [ ! -d /shared ]; do
  echo "Waiting for shared volume..."
  sleep 1
done

echo "Shared volume is ready"

# Wait for SSH keys to be available
while [ ! -f /shared/ssh/id_rsa ]; do
  echo "Waiting for SSH keys..."
  sleep 1
done

echo "SSH keys are available"

# kamal_podman gem will be installed globally via setup.sh
# No need for bundle install here

# Keep container running
echo "Deployer ready!"
sleep infinity
