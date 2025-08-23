#!/bin/bash

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
