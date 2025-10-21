#!/usr/bin/env bash

echo "🎨 Installing Oh My Posh..."

# Oh My Posh 설치 (공식 설치 스크립트 사용)
curl -s https://ohmyposh.dev/install.sh | bash -s

# PATH 업데이트
export PATH="$HOME/.local/bin:$PATH"

# Oh My Posh 설치 확인
if command -v oh-my-posh &> /dev/null; then
    echo "✅ Oh My Posh installation completed!"
    oh-my-posh --version
else
    echo "❌ Oh My Posh installation failed!"
    exit 1
fi

# Oh My Posh 초기화를 .zshrc에 추가
echo '' >> ~/.zshrc
echo '# Oh My Posh initialization' >> ~/.zshrc
echo 'eval "$(oh-my-posh init zsh)"' >> ~/.zshrc

echo "✅ Oh My Posh configuration added to .zshrc"