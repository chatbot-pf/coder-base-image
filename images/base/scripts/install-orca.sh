# Orca headless server 설치
# 참고: https://github.com/amondnet/orca/blob/main/docs/reference/headless-linux-server.md
# 실행(xvfb 기동, --pairing-address 등)은 Coder 템플릿의 startup script에서 담당

echo "Installing Orca headless server dependencies..."
apt-get update
apt-get install -y xvfb libnss3 libatk-bridge2.0-0 libgtk-3-0 libgbm1 libxss1
apt-get install -y libasound2t64 || apt-get install -y libasound2

echo "Downloading Orca AppImage..."
mkdir -p /opt/orca
curl -fsSL https://github.com/stablyai/orca/releases/latest/download/orca-linux.AppImage \
  -o /opt/orca/orca-linux.AppImage
chmod +x /opt/orca/orca-linux.AppImage

# 컨테이너에는 FUSE(/dev/fuse)가 없으므로 빌드 시점에 AppImage를 미리 추출
echo "Extracting Orca AppImage..."
cd /opt/orca
./orca-linux.AppImage --appimage-extract > /dev/null
rm orca-linux.AppImage
chmod -R a+rX /opt/orca/squashfs-root

# Chromium setuid sandbox 활성화 (비 root 사용자 실행용)
chown root:root /opt/orca/squashfs-root/chrome-sandbox
chmod 4755 /opt/orca/squashfs-root/chrome-sandbox

# coder 사용자용 실행 wrapper
# (데스크톱 CLI `orca`와 이름 충돌을 피하기 위해 orca-server 사용)
cat > /usr/local/bin/orca-server <<'EOF'
#!/bin/bash
export LIBGL_ALWAYS_SOFTWARE=1
# 추출된 AppImage를 직접 실행하므로 APPDIR을 명시 (AppRun 자동 감지는 인자가 있으면 실패)
export APPDIR=/opt/orca/squashfs-root
# 컨테이너 기본 seccomp 프로필이 sandbox의 namespace 생성을 차단함
# sandbox가 필요하면 ELECTRON_DISABLE_SANDBOX를 비우고 실행 (privileged 환경)
export ELECTRON_DISABLE_SANDBOX="${ELECTRON_DISABLE_SANDBOX-1}"
exec /opt/orca/squashfs-root/AppRun "$@"
EOF
chmod +x /usr/local/bin/orca-server

apt-get clean
rm -rf /var/lib/apt/lists/*
echo "Orca headless server installed successfully."
