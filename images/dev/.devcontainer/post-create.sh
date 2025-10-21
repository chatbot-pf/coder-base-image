#!/usr/bin/env zsh

# Dev Container 생성 후 실행되는 스크립트
# 추가 설정이나 환경 초기화를 여기에 작성

echo "🚀 Post-create setup starting..."

# Zsh 설정 리로드
source ~/.zshrc

# Git 설정 확인 (없으면 기본값 설정)
if ! git config --global user.name > /dev/null 2>&1; then
    echo "⚠️  Git user.name is not set. Please configure it:"
    echo "   git config --global user.name \"Your Name\""
fi

if ! git config --global user.email > /dev/null 2>&1; then
    echo "⚠️  Git user.email is not set. Please configure it:"
    echo "   git config --global user.email \"your.email@example.com\""
fi

# Docker 소켓 권한 확인
if [ -S /var/run/docker.sock ]; then
    echo "✅ Docker socket is available"
else
    echo "⚠️  Docker socket not found. Docker commands may not work."
fi

# 설치된 도구 버전 정보 출력
echo ""
echo "📦 Installed Tools:"
echo "  - Node.js: $(node --version 2>/dev/null || echo 'Not available')"
echo "  - fnm: $(fnm --version 2>/dev/null || echo 'Not available')"
echo "  - Bun: $(bun --version 2>/dev/null || echo 'Not available')"
echo "  - Deno: $(deno --version 2>/dev/null | head -n1 || echo 'Not available')"
echo "  - Docker: $(docker --version 2>/dev/null || echo 'Not available')"
echo "  - Graphite: $(gt --version 2>/dev/null || echo 'Not available')"
echo "  - Oh My Posh: $(oh-my-posh --version 2>/dev/null || echo 'Not available')"
echo "  - GitHub CLI: $(gh --version 2>/dev/null | head -n1 || echo 'Not available')"
echo ""

echo "✅ Post-create setup completed!"
echo ""
echo "💡 Tips:"
echo "  - SDKMAN is available. Use 'sdk list' to see available tools"
echo "  - fnm is aliased as 'nvm' for compatibility"
echo "  - Use 'gt' for Graphite CLI commands"
echo "  - Docker is ready (if socket is mounted)"
echo ""