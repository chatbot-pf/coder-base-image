#!/bin/bash

set -e

echo "Installing Docker Engine for Ubuntu..."

# Uninstall conflicting packages
echo "Removing conflicting packages..."
apt-get update
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    apt-get remove -y $pkg || true
done

# Install required dependencies
echo "Installing dependencies..."
apt-get install -y ca-certificates curl

# Set up Docker's official GPG key
echo "Setting up Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index and install Docker
echo "Installing Docker packages..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Docker installation completed successfully!"
echo "Note: You may want to add the coder user to the docker group:"
echo "usermod -aG docker coder"