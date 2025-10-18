# images/

이 디렉토리는 Coder 워크스페이스를 위한 Docker 이미지들을 포함합니다.

## 디렉토리 구조

```
images/
└── base/                    # 기본 베이스 이미지
    ├── Dockerfile           # Docker 이미지 빌드 정의
    ├── install.sh           # 메인 설치 스크립트 (Zimfw + zshrc 설정)
    ├── .zshenv             # Zsh 환경 변수 설정
    ├── .zimrc              # Zimfw 모듈 설정
    └── scripts/            # 설치 스크립트 모음
        ├── install-fonts.sh       # 시스템 폰트 설치 (Root)
        ├── install-root-sdk.sh    # Root 레벨 도구 (Qodana, AWS CLI)
        ├── install-docker.sh      # Docker Engine 설치 (Root)
        ├── install-sdk.sh         # 사용자 개발 도구 (fnm, SDKMAN, etc.)
        ├── install-ohmyposh.sh    # Oh My Posh 프롬프트
        ├── install-brew.sh        # Homebrew 패키지 매니저
        └── install-graphite.sh    # Graphite CLI (스택 PR)
```

## base/ 이미지

### 개요

`codercom/enterprise-base:ubuntu`를 기반으로 한 종합 개발 환경 이미지입니다.

### 주요 구성 요소

**쉘 및 프롬프트:**
- Zsh (기본 쉘)
- Zimfw (Zsh 플러그인 관리자)
- Oh My Posh (프롬프트 테마)

**개발 도구:**
- Node.js (fnm으로 관리, LTS + v22)
- SDKMAN (Java/JVM 도구)
- Bun, Deno
- Claude Code CLI
- FVM (Flutter Version Manager)

**클라우드 & DevOps:**
- AWS CLI
- Google Cloud CLI
- GitHub CLI
- Docker (coder 사용자가 docker 그룹에 포함)

**기타:**
- Homebrew 패키지 매니저
- Graphite CLI (스택 PR 관리)
- 커스텀 Nerd Fonts (MesloLGS NF, JetBrainsMono, D2Coding)
- Qodana CLI

### 빌드 프로세스

이미지는 2단계 빌드 프로세스를 따릅니다:

#### Phase 1: Root 사용자 설정

1. **시스템 패키지 설치**
   - Ubuntu 미러를 Kakao로 변경 (한국 지역 최적화)
   - 필수 패키지: `zip`, `zsh`, `screen`, `lsof`, `amazon-ecr-credential-helper`

2. **CLI 도구 설치**
   - GitHub CLI (apt repository)
   - Google Cloud CLI (apt repository)

3. **시스템 설정**
   - coder 사용자의 기본 쉘을 zsh로 변경
   - 시스템 폰트 설치 (Nerd Fonts)

4. **Root 레벨 도구**
   - Qodana CLI
   - AWS CLI

5. **Docker 설치**
   - Docker Engine 설치
   - coder 사용자를 docker 그룹에 추가

#### Phase 2: Coder 사용자 설정

1. **개발 SDK 설치** (`install-sdk.sh`)
   - Zimfw
   - fnm (Fast Node Manager)
   - Node.js (LTS + v22)
   - SDKMAN
   - Bun
   - Deno
   - Claude Code CLI
   - FVM

2. **프롬프트 설정** (`install-ohmyposh.sh`)
   - Oh My Posh 공식 설치 스크립트 사용
   - `~/.local/bin`에 설치 (Homebrew 불필요)

3. **패키지 매니저** (`install-brew.sh`)
   - Homebrew 설치 (`/home/linuxbrew/.linuxbrew/`)

4. **추가 도구** (`install-graphite.sh`)
   - Graphite CLI (Homebrew 통해 설치)

### 핵심 파일

#### Dockerfile

Docker 이미지의 빌드 정의 파일:
- 베이스 이미지: `codercom/enterprise-base:ubuntu`
- 타임존: `Asia/Seoul`
- 2단계 빌드: Root → Coder 사용자
- 레이어 최적화: 스크립트 복사 → 실행 → 삭제

#### install.sh

Zimfw 초기화 및 zshrc 설정을 관리하는 메인 스크립트:

**주요 기능:**
- `add_to_zshrc()`: 마커 기반 블록 추가
- `update_zshrc_block()`: 기존 블록 업데이트 또는 새로 추가
- `add_header_block()`: Coder 설정 헤더 블록 추가
- Zimfw 모듈 설치
- Oh My Posh 초기화 설정

**마커 시스템:**
```bash
# BEGIN <marker>
<content>
# END <marker>
```

이 패턴으로 .zshrc 파일을 블록 단위로 관리하여 중복 방지 및 업데이트 용이성 확보

#### .zshenv

Zsh 환경 변수 파일:
- `skip_global_compinit=1` 설정으로 글로벌 compinit 스킵
- 쉘 시작 속도 최적화

#### .zimrc

Zimfw 모듈 설정:
- `git` - Git 관련 기능
- `input` - 입력 개선
- `completion` - 자동완성
- `syntax-highlighting` - 문법 강조
- `autosuggestions` - 명령어 자동 제안
- `vim-mode` - Vim 키바인딩

### scripts/ 디렉토리

모든 설치 스크립트는 다음 패턴을 따릅니다:

1. **복사**: `COPY --chown=<user> scripts/<script>.sh /tmp/<script>.sh`
2. **실행**: `chmod +x /tmp/<script>.sh && /<shell> /tmp/<script>.sh`
3. **삭제**: `rm /tmp/<script>.sh`

이 패턴으로 이미지 크기 최소화

#### install-fonts.sh (Root)

시스템 폰트 설치:
- MesloLGS NF (Nerd Font)
- JetBrainsMono Nerd Font
- D2Coding (한국어 폰트)

설치 위치: `/usr/share/fonts/truetype/`

#### install-root-sdk.sh (Root)

Root 레벨 개발 도구:
- Qodana CLI (JetBrains 코드 분석)
- AWS CLI v2

#### install-docker.sh (Root)

Docker Engine 설치:
- 공식 Docker apt repository 사용
- Docker CE, CLI, containerd 설치
- coder 사용자는 Dockerfile에서 별도로 docker 그룹 추가

#### install-sdk.sh (Coder User)

사용자 개발 도구 설치:
- **Zimfw**: Zsh 플러그인 매니저
- **fnm**: Fast Node Manager (nvm 대체)
  - Node.js LTS
  - Node.js v22
  - `alias nvm="fnm"` 호환성 설정
- **SDKMAN**: Java/JVM 도구 매니저
- **Bun**: JavaScript 런타임
- **Deno**: JavaScript/TypeScript 런타임
- **Claude Code CLI**: Claude AI CLI 도구
- **FVM**: Flutter Version Manager

#### install-ohmyposh.sh (Coder User)

Oh My Posh 설치:
- 공식 설치 스크립트 사용 (Homebrew 불필요)
- 설치 위치: `~/.local/bin`
- bash로 실행 (공식 스크립트 요구사항)

#### install-brew.sh (Coder User)

Homebrew 패키지 매니저:
- 설치 위치: `/home/linuxbrew/.linuxbrew/`
- 공식 설치 스크립트 사용

#### install-graphite.sh (Coder User)

Graphite CLI 설치:
- Homebrew를 통해 설치
- 스택 PR 관리 도구
- **중요**: Homebrew가 먼저 설치되어야 함

## 중요 사항

### 실행 순서

스크립트 실행 순서가 중요합니다:

**Root Phase:**
1. 시스템 패키지
2. GitHub CLI
3. Google Cloud CLI
4. 폰트 (`install-fonts.sh`)
5. Root SDK (`install-root-sdk.sh`)
6. Docker (`install-docker.sh`)

**Coder User Phase:**
1. SDK (`install-sdk.sh`) - fnm, SDKMAN, Bun, Deno, Claude Code, FVM
2. Oh My Posh (`install-ohmyposh.sh`)
3. Homebrew (`install-brew.sh`)
4. Graphite (`install-graphite.sh`) - Homebrew 필요

### 사용자 컨텍스트

- **Root 스크립트**: 시스템 레벨 도구, 폰트, Docker
- **Coder 스크립트**: 개발 도구, 사용자 설정

### Node.js 관리

- **fnm 사용** (nvm 아님)
- `nvm` 명령은 `fnm` alias로 제공
- LTS 및 v22 버전 자동 설치

### Docker

- Docker 데몬은 Coder 워크스페이스에서 별도로 시작 필요
- coder 사용자는 docker 그룹 멤버 (sudo 불필요)

### 이미지 크기 최적화

- 스크립트는 `/tmp/`로 복사 후 실행 즉시 삭제
- apt 캐시 정리: `apt-get clean && rm -rf /var/lib/apt/lists/*`
- 레이어 최소화: 관련 명령 체이닝

## 빌드 방법

```bash
# 로컬 빌드
cd images/base
docker build -t coder-base:latest .

# 또는 루트에서
docker build -f images/base/Dockerfile -t coder-base:latest .
```

## CI/CD

GitHub Actions가 자동으로 빌드 및 배포:
- 트리거: push to main, PR, daily schedule, semver tags
- 레지스트리: ghcr.io
- 빌드 캐싱: Docker Buildx
- 이미지 서명: cosign

## 향후 확장

`images/` 디렉토리는 여러 이미지 변형을 포함할 수 있도록 구조화:

```
images/
├── base/           # 현재 베이스 이미지
├── java/           # Java 특화 이미지 (향후)
├── python/         # Python 특화 이미지 (향후)
└── CLAUDE.md       # 이 문서
```

각 이미지는 독립적인 Dockerfile 및 scripts/ 디렉토리를 가질 수 있습니다.