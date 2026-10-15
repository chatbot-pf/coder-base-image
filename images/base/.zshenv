skip_global_compinit=1

# 비대화형 셸에서 mise 사용 (shims 방식 — mise 공식 권장)
[ -d "$HOME/.local/share/mise/shims" ] && export PATH="$HOME/.local/share/mise/shims:$PATH"
