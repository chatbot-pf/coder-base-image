# Orca Headless Server in Coder Workspaces

베이스 이미지에는 Orca headless server가 설치되어 있습니다 (`orca-server` wrapper).
실행과 클라이언트 접속 주소(`--pairing-address`)는 Coder 템플릿이 담당합니다.

- 설치 내용: [images/CLAUDE.md](../images/CLAUDE.md)의 `install-orca.sh` 섹션 참고
- 원본 가이드: [headless-linux-server.md](https://github.com/amondnet/orca/blob/main/docs/reference/headless-linux-server.md)

## 동작 방식

- `orca-server serve`는 포그라운드 프로세스로 실행되며 pairing URL을 출력합니다.
- `--pairing-address`는 **Orca 클라이언트(노트북/모바일)가 도달할 수 있는 주소**여야 합니다.
- Coder wildcard access URL이 설정된 배포에서는 서브도메인 앱 주소를 사용합니다:
  `{app-slug}--{agent-name}--{workspace-name}--{username}.{wildcard-domain}`

## 템플릿 예제

```hcl
variable "wildcard_domain" {
  description = "Coder wildcard access domain (예: coder.example.com — '*.' 제외)"
  type        = string
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  # coder_app(slug=orca, subdomain=true)의 외부 호스트명
  orca_host = "orca--main--${lower(data.coder_workspace.me.name)}--${lower(data.coder_workspace_owner.me.name)}.${var.wildcard_domain}"
}

resource "coder_agent" "main" {
  # ... 기존 설정 ...

  startup_script = <<-EOT
    # Orca headless server (Xvfb는 orca가 자동 기동)
    nohup orca-server serve \
      --port 6768 \
      --pairing-address "wss://${local.orca_host}" \
      > /tmp/orca-server.log 2>&1 &
  EOT
}

resource "coder_app" "orca" {
  agent_id     = coder_agent.main.id
  slug         = "orca"
  display_name = "Orca Server"
  url          = "http://localhost:6768"
  subdomain    = true
  share        = "authenticated"
}
```

- `local.orca_host`의 `main`은 agent 이름입니다. 템플릿의 agent 이름에 맞춰 수정하세요.
- pairing URL은 `/tmp/orca-server.log`에서 확인합니다:
  ```bash
  grep -m1 "pairing" /tmp/orca-server.log
  ```

## share 옵션 선택

| 값 | 접속 가능 대상 | 비고 |
|---|---|---|
| `authenticated` | Coder 로그인 세션이 있는 브라우저 | 외부 Orca 클라이언트(데스크톱/모바일 앱)는 Coder 세션이 없어 차단될 수 있음 |
| `public` | 누구나 (URL 노출 시) | Orca pairing 토큰이 자체 인증 역할을 하지만, 포트가 인터넷에 공개됨 |

Orca 데스크톱/모바일 앱에서 직접 페어링하려면 `public`이 필요할 수 있습니다.
`authenticated`로 먼저 시도하고, 클라이언트가 연결하지 못하면 `public`으로 전환하되
워크스페이스를 신뢰 경계 밖에 두지 않도록 주의하세요.

## 대안: coder port-forward

서브도메인 앱 없이 개인 용도로만 쓸 경우:

```bash
# 클라이언트 머신에서
coder port-forward <workspace> --tcp 6768:6768
```

이때 startup script는 `--pairing-address 127.0.0.1`로 실행합니다.

## 트러블슈팅

- **sandbox 크래시 (`Failed to move to new namespace`)**: 컨테이너 seccomp 제약.
  `orca-server`가 기본으로 `ELECTRON_DISABLE_SANDBOX=1`을 설정하므로 wrapper를 우회하지 말 것.
  privileged 환경에서 sandbox를 켜려면 `ELECTRON_DISABLE_SANDBOX= orca-server serve ...`.
- **dbus 에러 로그**: headless 컨테이너에서 무해한 노이즈.
- **클라이언트 연결 실패**: `--pairing-address`가 클라이언트에서 도달 가능한지,
  `coder_app`의 `share` 설정이 클라이언트 인증 방식과 맞는지 확인.
