#!/bin/zsh

# 마커를 사용하여 블록 단위로 관리
add_to_zshrc() {
    local marker="$1"
    local content="$2"
    local zshrc="$HOME/.zshrc"

    # .zshrc 파일이 없으면 생성
    [ ! -f "$zshrc" ] && touch "$zshrc"

    # 마커가 이미 있는지 확인
    if ! grep -q "# BEGIN $marker" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# BEGIN $marker" >> "$zshrc"
        echo "$content" >> "$zshrc"
        echo "# END $marker" >> "$zshrc"
        echo "✅ Added $marker configuration to .zshrc"
    else
        echo "ℹ️  $marker configuration already exists in .zshrc"
    fi
}

# 기존 블록을 업데이트하거나 새로 추가
update_zshrc_block() {
    local marker="$1"
    local content="$2"
    local zshrc="$HOME/.zshrc"

    # .zshrc 파일이 없으면 생성
    [ ! -f "$zshrc" ] && touch "$zshrc"

    # 기존 블록 제거
    if grep -q "# BEGIN $marker" "$zshrc" 2>/dev/null; then
        # 임시 파일에 마커 블록을 제외한 내용 저장
        sed "/# BEGIN $marker/,/# END $marker/d" "$zshrc" > "$zshrc.tmp"
        mv "$zshrc.tmp" "$zshrc"
        echo "🔄 Updating $marker configuration..."
    else
        echo "➕ Adding $marker configuration..."
    fi

    # 새 블록 추가
    cat >> "$zshrc" << EOF

# BEGIN $marker
$content
# END $marker
EOF
}

add_header_block() {
    local zshrc="$HOME/.zshrc"
    local header_marker="# === CODER CONFIG START ==="
    local footer_marker="# === CODER CONFIG END ==="

    # .zshrc가 없으면 생성
    [ ! -f "$zshrc" ] && touch "$zshrc"

    # 이미 헤더가 있는지 확인
    if grep -q "$header_marker" "$zshrc" 2>/dev/null; then
        echo "Header block already exists"
        return 0
    fi

    # 새 헤더 블록 생성
    local header_content="$header_marker
# Managed by Coder Dotfiles
# Generated: $(date +%Y-%m-%d\ %H:%M:%S)
# DO NOT EDIT THIS BLOCK MANUALLY

source ${ZIM_HOME}/modules/zsh-defer/zsh-defer.plugin.zsh

$footer_marker

"

    # 임시 파일에 헤더 + 기존 내용
    {
        echo "$header_content"
        cat "$zshrc"
    } > "$zshrc.tmp"

    mv "$zshrc.tmp" "$zshrc"
    echo "Header block added to .zshrc"
}

# Install Zimfw
# export ZIM_HOME=${HOME}/.zim
# curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
# source "${ZIM_HOME}/init.zsh"

# Copy .zimrc to home directory
cp .zimrc ~/

# Install Zim modules
zimfw install

add_header_block
