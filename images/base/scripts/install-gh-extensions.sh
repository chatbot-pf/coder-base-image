#!/usr/bin/env bash
set -e

echo "🧩 Installing GitHub CLI extensions..."

# gh는 root 단계의 apt 설치에 의존한다 — 없으면 원인을 바로 알리고 중단한다
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found; the root-phase GitHub CLI install must run first" >&2
    exit 1
fi

# 공개 저장소의 확장은 인증 없이 설치되지만, 비인증 API는 IP당 시간당 60회로 제한된다.
# CI는 BuildKit secret(gh_token)으로 토큰을 넘겨 공유 러너 IP의 rate limit을 피한다.
if [ -s /run/secrets/gh_token ]; then
    GH_TOKEN="$(cat /run/secrets/gh_token)"
    export GH_TOKEN
fi

# gh-stack: GitHub 네이티브 stacked PR / gh-actions-lock: Actions 의존성 lock·검증
gh extension install github/gh-stack || { echo "❌ Failed to install github/gh-stack" >&2; exit 1; }
gh extension install github/gh-actions-lock || { echo "❌ Failed to install github/gh-actions-lock" >&2; exit 1; }

# 설치 확인 (`gh extension list`는 인증이 필요하므로 각 확장을 직접 실행한다)
if gh stack --version &> /dev/null && gh actions-lock --help &> /dev/null; then
    echo "✅ GitHub CLI extensions installation completed!"
    gh stack --version
else
    echo "❌ GitHub CLI extensions verification failed!" >&2
    exit 1
fi
