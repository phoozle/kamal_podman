#!/bin/sh
set -e
echo "Setting up shared resources..."

# Create SSH directory and keys if they don't exist
if [ ! -f /shared/ssh/id_rsa ]; then
  echo "Creating SSH keys..."
  mkdir -p /shared/ssh
  ssh-keygen -t rsa -f /shared/ssh/id_rsa -N ""
  ssh-keygen -t rsa -f /shared/ssh/kamal_test -N ""
  chmod 700 /shared/ssh
  chmod 600 /shared/ssh/*
  echo "SSH keys created"
fi

# Create certs if they don't exist
if [ ! -f /shared/certs/domain.crt ]; then
  echo "Creating certificates..."
  mkdir -p /shared/certs
  openssl req -x509 -newkey rsa:4096 -keyout /shared/certs/domain.key -out /shared/certs/domain.crt -days 365 -nodes -subj "/C=US/ST=Test/L=Test/O=Test/CN=registry"
  chmod 644 /shared/certs/domain.crt
  chmod 600 /shared/certs/domain.key
  echo "Certificates created"
fi

echo "Shared resources setup complete"
sleep infinity
