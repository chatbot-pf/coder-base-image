FROM codercom/enterprise-base:ubuntu

ENV TZ="Asia/Seoul"

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

RUN apt-get update && \
    apt-get install -y \
    zip \
    zsh \
    screen \
    lsof \
    tree \
    git-lfs \
    postgresql-client \
    cmake \
    amazon-ecr-credential-helper \
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

# Google Cloud CLI 설치
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg curl \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y google-cloud-cli \
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
COPY --chown=root:root scripts/install-fonts.sh /tmp/install-fonts.sh
RUN chmod +x /tmp/install-fonts.sh && /tmp/install-fonts.sh
RUN rm /tmp/install-fonts.sh

# root 개발 도구 설치를 위한 스크립트
COPY --chown=root:root scripts/install-root-sdk.sh /tmp/install-root-sdk.sh
RUN chmod +x /tmp/install-root-sdk.sh && \
    /usr/bin/zsh /tmp/install-root-sdk.sh && \
    rm /tmp/install-root-sdk.sh

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

COPY .zshenv /home/coder/.zshenv

# 개발 도구 설치를 위한 스크립트
COPY --chown=coder:coder scripts/install-sdk.sh /tmp/install-sdk.sh
RUN chmod +x /tmp/install-sdk.sh && \
    /usr/bin/zsh /tmp/install-sdk.sh && \
    rm /tmp/install-sdk.sh

# Oh My Posh 설치
COPY --chown=coder:coder scripts/install-ohmyposh.sh /tmp/install-ohmyposh.sh
RUN chmod +x /tmp/install-ohmyposh.sh && \
    /bin/bash /tmp/install-ohmyposh.sh && \
    rm /tmp/install-ohmyposh.sh

# Graphite CLI 설치 (npm 사용)
COPY --chown=coder:coder scripts/install-graphite.sh /tmp/install-graphite.sh
RUN chmod +x /tmp/install-graphite.sh && \
    /bin/bash /tmp/install-graphite.sh && \
    rm /tmp/install-graphite.sh

# Homebrew 설치
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 기본 쉘 설정
ENV SHELL=/usr/bin/zsh
SHELL ["/usr/bin/zsh", "-c"]
