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
for style in Regular Bold Italic Bold%20Italic; do
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