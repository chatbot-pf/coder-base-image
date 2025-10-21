FROM ubuntu:22.04

ENV TZ="Asia/Seoul"
ENV DEBIAN_FRONTEND=noninteractive

# Root로 시스템 패키지 설치
USER root

# Ubuntu 미러를 Kakao로 변경 (신형식 및 구형식 모두 지원)
RUN if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
        sed -i 's|http://archive.ubuntu.com|http://mirror.kakao.com|g' /etc/apt/sources.list.d/ubuntu.sources && \
        sed -i 's|http://security.ubuntu.com|http://mirror.kakao.com|g' /etc/apt/sources.list.d/ubuntu.sources && \
        sed -i 's|https://archive.ubuntu.com|http://mirror.kakao.com|g' /etc/apt/sources.list.d/ubuntu.sources && \
        sed -i 's|https://security.ubuntu.com|http://mirror.kakao.com|g' /etc/apt/sources.list.d/ubuntu.sources; \
    fi && \
    if [ -f /etc/apt/sources.list ]; then \
        sed -i 's|http://archive.ubuntu.com|http://mirror.kakao.com|g' /etc/apt/sources.list && \
        sed -i 's|http://security.ubuntu.com|http://mirror.kakao.com|g' /etc/apt/sources.list; \
    fi

# 기본 시스템 패키지 설치
RUN apt-get update && \
    apt-get install -y \
    zip \
    zsh \
    screen \
    lsof \
    wget \
    curl \
    unzip \
    fontconfig \
    git \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# coder 사용자 생성 (UID/GID 1000으로 생성하여 호스트와 권한 충돌 방지)
RUN groupadd --gid 1000 coder \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder \
    && chmod 0440 /etc/sudoers.d/coder

# coder 사용자의 기본 쉘 변경
RUN chsh -s /usr/bin/zsh coder

# 폰트 설치 스크립트
COPY --chown=root:root scripts/install-fonts.sh /tmp/install-fonts.sh
RUN chmod +x /tmp/install-fonts.sh && /tmp/install-fonts.sh && rm /tmp/install-fonts.sh

# Docker 설치
COPY --chown=root:root scripts/install-docker.sh /tmp/install-docker.sh
RUN chmod +x /tmp/install-docker.sh && \
    /tmp/install-docker.sh && \
    rm /tmp/install-docker.sh

# coder 사용자를 docker 그룹에 추가
RUN usermod -aG docker coder

# coder 사용자로 전환
USER coder
WORKDIR /home/coder

# .zshenv 복사
COPY --chown=coder:coder .zshenv /home/coder/.zshenv

# 기본 쉘 설정
ENV SHELL=/usr/bin/zsh
SHELL ["/usr/bin/zsh", "-c"]

# Dev Container Features가 나머지 도구들을 설치합니다:
# - Zimfw (Zsh framework)
# - fnm (Node.js version manager)
# - Oh My Posh (prompt theme)
# - Homebrew (package manager)
# - Graphite CLI (stacked PRs)
# - Dev Tools (Bun, Deno, SDKMAN, Claude Code, FVM)

# Dev Container를 위한 영구 실행 명령
CMD ["/usr/bin/zsh"]