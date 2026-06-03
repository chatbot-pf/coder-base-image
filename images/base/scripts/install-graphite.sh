#!/usr/bin/env bash

echo "📊 Installing Graphite CLI..."

# mise 환경 로드 (node/npm은 mise가 관리)
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# Graphite CLI 설치 (npm 사용)
npm install -g @withgraphite/graphite-cli@stable

# 새 실행파일(gt)에 대한 shim 재생성
mise reshim

# Graphite CLI 설치 확인
if command -v gt &> /dev/null; then
    echo "✅ Graphite CLI installation completed!"
    gt --version
else
    echo "❌ Graphite CLI installation failed!"
    exit 1
fi