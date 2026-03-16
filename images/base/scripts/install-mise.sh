#!/bin/bash
set -e

echo "Installing mise..."

# mise GPG key 설치
install -dm 755 /etc/apt/keyrings
curl -fsSL https://mise.jdx.dev/gpg-key.pub | tee /etc/apt/keyrings/mise-archive-keyring.asc > /dev/null

# mise apt repository 추가
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list

# mise 설치
apt-get update
apt-get install -y mise
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "mise installed successfully."
