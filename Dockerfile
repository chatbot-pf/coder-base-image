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

# Root로 시스템 폰트 설치
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    fontconfig \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 폰트 설치 스크립트
COPY --chown=root:root <<'SCRIPT' /tmp/install-fonts.sh
#!/bin/bash
set -e

# 색상 출력
GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}[FONT]${NC} $1"; }

# 시스템 폰트 디렉토리
SYSTEM_FONT_DIR="/usr/share/fonts/truetype"

# 1. 프로그래밍 폰트들
log "Installing programming fonts..."

# JetBrains Mono
mkdir -p "$SYSTEM_FONT_DIR/jetbrains-mono"
wget -q --show-progress \
    https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip \
    -O /tmp/jetbrains.zip
unzip -q /tmp/jetbrains.zip -d /tmp/jetbrains
cp /tmp/jetbrains/fonts/ttf/*.ttf "$SYSTEM_FONT_DIR/jetbrains-mono/"
rm -rf /tmp/jetbrains*

# Cascadia Code
mkdir -p "$SYSTEM_FONT_DIR/cascadia-code"
wget -q --show-progress \
    https://github.com/microsoft/cascadia-code/releases/download/v2111.01/CascadiaCode-2111.01.zip \
    -O /tmp/cascadia.zip
unzip -q /tmp/cascadia.zip -d /tmp/cascadia
cp /tmp/cascadia/ttf/*.ttf "$SYSTEM_FONT_DIR/cascadia-code/"
rm -rf /tmp/cascadia*

# 2. Nerd Fonts (아이콘 포함 버전)
log "Installing Nerd Fonts..."

# FiraCode Nerd Font
mkdir -p "$SYSTEM_FONT_DIR/firacode-nerd"
wget -q --show-progress \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip \
    -O /tmp/firacode-nerd.zip
unzip -q /tmp/firacode-nerd.zip -d "$SYSTEM_FONT_DIR/firacode-nerd/"
rm /tmp/firacode-nerd.zip

# 3. 한글 폰트
log "Installing Korean fonts..."

# D2Coding
mkdir -p "$SYSTEM_FONT_DIR/d2coding"
wget -q --show-progress \
    https://github.com/naver/d2codingfont/releases/download/VER1.3.2/D2Coding-Ver1.3.2-20180524.zip \
    -O /tmp/d2coding.zip
unzip -q /tmp/d2coding.zip -d /tmp/
cp /tmp/D2Coding/*.ttf "$SYSTEM_FONT_DIR/d2coding/"
rm -rf /tmp/d2coding.zip /tmp/D2Coding

# 나눔고딕코딩
apt-get update && apt-get install -y fonts-nanum-coding && apt-get clean

# 4. Powerline/Powerlevel10k 폰트
log "Installing Powerline fonts..."

mkdir -p "$SYSTEM_FONT_DIR/meslo-powerline"
for style in Regular Bold Italic BoldItalic; do
    wget -q --show-progress \
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${style}.ttf" \
        -O "$SYSTEM_FONT_DIR/meslo-powerline/MesloLGS NF ${style}.ttf"
done

# 폰트 캐시 업데이트
log "Updating font cache..."
fc-cache -fv

# 설치된 폰트 확인
log "Installed fonts:"
fc-list : family | sort -u | head -20

log "Font installation completed!"
SCRIPT

RUN chmod +x /tmp/install-fonts.sh && /tmp/install-fonts.sh && rm /tmp/install-fonts.sh

# coder 사용자로 전환
USER coder
WORKDIR /home/coder

ADD .zshenv /home/coder/.zshenv

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

# BUN
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
SCRIPT


RUN chmod +x /tmp/install.sh && \
    /usr/bin/zsh /tmp/install.sh && \
    rm /tmp/install.sh

# 기본 쉘 설정
ENV SHELL=/usr/bin/zsh
SHELL ["/usr/bin/zsh", "-c"]
