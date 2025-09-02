#!/bin/zsh
set -e

# Install Zimfw
ZIM_HOME=${HOME}/.zim
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh


# NVM 설치 및 설정
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Node.js 및 패키지 설치
nvm install --lts
nvm install 22
nvm alias default 22

# SDKMAN 설치
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# bun 설치
curl -fsSL https://bun.com/install | bash

# Claude Code 설치
echo "Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

# FVM 설치
curl -fsSL https://fvm.app/install.sh | bash

# PATH에 Claude Code 추가 (zshrc에 추가)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
