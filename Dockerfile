FROM codercom/enterprise-base:ubuntu

# Root로 시스템 패키지 설치
USER root
RUN apt-get update && \
    apt-get install -y \
    zip \
    zsh \
    screen \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
# coder 사용자의 기본 쉘 변경
RUN chsh -s /usr/bin/zsh coder

# coder 사용자로 전환
USER coder
WORKDIR /home/coder

ADD .zshenv /home/coder

# 개발 도구 설치를 위한 스크립트
COPY --chown=coder:coder <<'SCRIPT' /tmp/install.sh
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

# .zshrc 업데이트
cat >> ~/.zshrc << 'EOF'

# ZIM
export ZIM_HOME=${HOME}/.zim
[[ -s "${ZIM_HOME}/init.zsh" ]] && source "${ZIM_HOME}/init.zsh"
EOF

SCRIPT


RUN chmod +x /tmp/install.sh && \
    /usr/bin/zsh /tmp/install.sh && \
    rm /tmp/install.sh

# 기본 쉘 설정
ENV SHELL=/usr/bin/zsh
SHELL ["/usr/bin/zsh", "-c"]
