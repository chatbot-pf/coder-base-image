FROM codercom/enterprise-base:ubuntu

ENV TZ="Asia/Seoul"

# Root로 시스템 패키지 설치
USER root
RUN apt-get update && \
    apt-get install -y \
    zip \
    zsh \
    screen \
    lsof \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI 설치
RUN (type -p wget >/dev/null || (apt update && apt-get install wget -y)) \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh -y \
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
COPY --chown=root:root install-fonts.sh /tmp/install-fonts.sh
RUN chmod +x /tmp/install-fonts.sh && /tmp/install-fonts.sh
RUN rm /tmp/install-fonts.sh

# root 개발 도구 설치를 위한 스크립트
COPY --chown=root:root install-root-sdk.sh /tmp/install-root-sdk.sh
RUN chmod +x /tmp/install-root-sdk.sh && \
    /usr/bin/zsh /tmp/install-root-sdk.sh && \
    rm /tmp/install-root-sdk.sh

# coder 사용자로 전환
USER coder
WORKDIR /home/coder

COPY .zshenv /home/coder/.zshenv

# 개발 도구 설치를 위한 스크립트
COPY --chown=coder:coder install-sdk.sh /tmp/install-sdk.sh
RUN chmod +x /tmp/install-sdk.sh && \
    /usr/bin/zsh /tmp/install-sdk.sh && \
    rm /tmp/install-sdk.sh

# 기본 쉘 설정
ENV SHELL=/usr/bin/zsh
SHELL ["/usr/bin/zsh", "-c"]
