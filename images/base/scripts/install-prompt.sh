#!/bin/zsh
set -e

# Zimfw 모듈 구성과 Powerlevel10k(Catppuccin) 프롬프트 설정
# install-sdk.sh가 Zimfw를 설치하고 기본 ~/.zshrc를 만든 뒤에 실행한다.

ZIM_HOME=${HOME}/.zim

echo "🎨 Configuring Zimfw modules and Powerlevel10k prompt..."

# Zimfw 설치 스크립트는 기존 .zimrc 앞에 기본 템플릿을 덧붙이므로,
# 설치가 끝난 뒤에 저장소의 .zimrc로 덮어쓰고 모듈을 설치한다.
cp /tmp/.zimrc ~/.zimrc
cp /tmp/.p10k.zsh ~/.p10k.zsh
source ${ZIM_HOME}/zimfw.zsh install -q

# Powerlevel10k instant prompt와 테마 선택은 .zshrc 맨 앞에 둔다.
# instant prompt 블록보다 위에서는 표준 입출력에 접근하는 코드를 두지 않는다.
# ~/.zshrc(Zimfw 초기화 포함)는 install-sdk.sh가 만든다. 없으면 테마가 로드되지 않는
# .zshrc가 만들어지므로 빌드를 멈춘다.
[[ -f ~/.zshrc ]] || { echo "❌ ~/.zshrc not found; install-sdk.sh (Zimfw) must run first" >&2; exit 1; }
{
    cat <<'EOF'
# Powerlevel10k instant prompt. 초기화가 끝나기 전에 캐시된 프롬프트를 먼저 그린다.
# 이 블록보다 위에서는 표준 입출력에 접근하는 코드를 두지 않는다.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Catppuccin p10k 테마 선택. tolkonepiu/catppuccin-powerlevel10k-themes 플러그인이
# 모듈 로드 시 이 값을 읽어 자동으로 apply_catppuccin을 호출한다.
zstyle ':catppuccin:p10k' 'theme' 'lean'
zstyle ':catppuccin:p10k' 'flavour' 'mocha'

EOF
    cat ~/.zshrc
} > ~/.zshrc.tmp
mv ~/.zshrc.tmp ~/.zshrc

cat >> ~/.zshrc <<'EOF'

# ~/.p10k.zsh는 Catppuccin 테마 위에 얹는 추가 커스터마이징 override용
[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh

#
# Orca: 워크스페이스별 HISTFILE 로딩
#
# Orca는 워크스페이스마다 별도 history 파일을 두고, 사용자 .zshrc가 끝난 뒤
# 첫 프롬프트에서 HISTFILE을 그 파일로 바꾼다. zsh는 HISTFILE을 바꿔도 새 파일의
# 기존 내용을 다시 읽지 않으므로, 이전 세션에 남긴 명령이 위/아래 화살표·substring
# search(메모리 history를 검색)에 안 잡힌다. Orca가 HISTFILE을 바꾼 직후 그 파일을
# 한 번 fc -R로 읽어들여 과거 history를 복원한다.
if [[ -n $ORCA_WORKSPACE_ID ]]; then
  # .zshrc를 다시 source해도 이미 로드한 파일을 다시 읽지 않도록 기존 값을 유지한다.
  typeset -g _orca_loaded_histfile="${_orca_loaded_histfile-}"
  autoload -Uz add-zsh-hook
  _orca_load_histfile() {
    [[ "$HISTFILE" == "$_orca_loaded_histfile" ]] && return
    # 아직 파일이 없으면 다음 프롬프트에서 다시 시도한다. 이 세션이 쓴 명령을
    # 다시 읽게 되어도 Zimfw environment 모듈의 HIST_IGNORE_ALL_DUPS가 중복을 없앤다.
    [[ -r "$HISTFILE" ]] || return 0
    _orca_loaded_histfile=$HISTFILE
    fc -R "$HISTFILE" 2>/dev/null
  }
  add-zsh-hook precmd _orca_load_histfile
fi
EOF

echo "✅ Powerlevel10k prompt configuration completed!"
