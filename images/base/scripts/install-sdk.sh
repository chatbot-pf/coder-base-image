#!/bin/zsh
set -e

# Install Zimfw
ZIM_HOME=${HOME}/.zim
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh

# ─────────────────────────────────────────────────────────────
# mise: 런타임 글로벌 버전 관리
#   mise 바이너리는 install-mise.sh(root, apt)에서 이미 설치됨.
#   여기서는 coder 사용자의 글로벌 기본 버전을 선언적으로 고정한다.
#   (config: ~/.config/mise/config.toml)
# ─────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# 글로벌 기본 런타임 설치 (node 기본값 24, LTS 라인도 함께 유지)
mise use -g node@24 node@lts
mise use -g bun@latest
mise use -g deno@latest
mise use -g java@temurin-21

# Flutter는 SDK 크기(아티팩트 포함 ~2GB+)가 커서 이미지에 굽지 않는다.
# 필요 시 사용자가: mise use flutter@latest

# 빌드 단계(비대화형 셸)에서 도구를 즉시 사용하기 위해 shims를 PATH에 추가
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Global npm 패키지 설치 (mise가 관리하는 node 사용)
npm install -g firebase-tools cdk turbo vercel @google/gemini-cli

# Claude Code 설치
echo "Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

# npm 전역 실행파일 및 새 도구에 대한 shim 재생성
mise reshim

# ─────────────────────────────────────────────────────────────
# .zshrc 설정
# ─────────────────────────────────────────────────────────────
# mise 활성화 (대화형 셸용)
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc

# PATH에 Claude Code(~/.local/bin) 추가
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

# Dart pub global 패키지 PATH 추가
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.zshrc
