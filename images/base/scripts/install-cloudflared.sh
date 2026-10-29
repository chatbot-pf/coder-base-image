#!/bin/bash
set -e

echo "Installing cloudflared..."

# Cloudflare GPG key 설치
mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL -o /usr/share/keyrings/cloudflare-public-v2.gpg https://pkg.cloudflare.com/cloudflare-public-v2.gpg

# cloudflared apt repository 추가
echo "deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main" > /etc/apt/sources.list.d/cloudflared.list

# cloudflared 설치
apt-get update
apt-get install -y cloudflared
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "cloudflared installed successfully: $(cloudflared --version)"
