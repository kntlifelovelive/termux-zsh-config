# ~/.config/zsh/modules/zoxide.zsh
# Zoxide (smarter cd) configuration — Termux.
# Guarded: no-op when zoxide is not installed.

if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh 2>/dev/null)" || true
fi
