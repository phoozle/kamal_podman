#!/bin/bash
set -e

while [ ! -f /root/.ssh/authorized_keys ]; do
  echo "Waiting for SSH keys"
  sleep 1
done

service ssh restart

exec sleep infinity
