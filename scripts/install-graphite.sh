#!/usr/bin/env zsh

echo "📊 Installing Graphite CLI..."

# Homebrew 환경 변수 로드
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Graphite CLI 설치
brew install withgraphite/tap/graphite

# Graphite CLI 설치 확인
if command -v gt &> /dev/null; then
    echo "✅ Graphite CLI installation completed!"
    gt --version
else
    echo "❌ Graphite CLI installation failed!"
    exit 1
fi