#!/bin/bash
set -e

# Dart SDK 설치
echo "Installing Dart SDK..."

apt-get update
apt-get install -y apt-transport-https

# Google signing key 추가
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg

# Dart apt repository 추가
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | tee /etc/apt/sources.list.d/dart_stable.list

# Dart SDK 설치
apt-get update
apt-get install -y dart

# 정리
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Dart SDK installed successfully."
echo "Dart version: $(dart --version)"