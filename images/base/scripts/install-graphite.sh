#!/usr/bin/env bash

echo "📊 Installing Graphite CLI..."

# fnm 환경 로드
export FNM_PATH="$HOME/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
eval "$(fnm env --use-on-cd)"

# Graphite CLI 설치 (npm 사용)
npm install -g @withgraphite/graphite-cli@stable

# Graphite CLI 설치 확인
if command -v gt &> /dev/null; then
    echo "✅ Graphite CLI installation completed!"
    gt --version
else
    echo "❌ Graphite CLI installation failed!"
    exit 1
fi