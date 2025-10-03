#!/usr/bin/env zsh

echo "🍺 Installing Homebrew..."

# Homebrew 설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Homebrew 환경 변수 설정
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc

# 현재 세션에서 Homebrew 활성화
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

echo "✅ Homebrew installation completed!"