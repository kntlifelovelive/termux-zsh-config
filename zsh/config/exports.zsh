# ~/.config/zsh/config/exports.zsh
# PATH and environment variables — Termux.

# ============================================
# PATH additions
# ============================================
# Termux already sets $PREFIX (usually $PREFIX/bin). Keep user-local bins.
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PREFIX/bin:$PATH"

# ============================================
# Editor — prefer an available Termux editor
# ============================================
if (( $+commands[micro] )); then
    export EDITOR=micro
elif (( $+commands[vim] )); then
    export EDITOR=vim
elif (( $+commands[vi] )); then
    export EDITOR=vi
fi
export VISUAL="$EDITOR"

# LANG/LC_ALL are set once in .zshenv (loaded before this file) — not duplicated here.
