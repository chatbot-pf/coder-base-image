skip_global_compinit=1

# 비대화형 셸에서 mise 사용 (shims 방식 — mise 공식 권장)
# .zshenv는 중첩된 zsh마다 다시 읽히므로 PATH 중복을 제거한다.
typeset -gU path PATH
[ -d "$HOME/.local/share/mise/shims" ] && export PATH="$HOME/.local/share/mise/shims:$PATH"
