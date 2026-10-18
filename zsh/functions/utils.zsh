# ~/.config/zsh/functions/utils.zsh
# Small utilities — Termux.

# Print a lightweight startup banner (width-aware).
print_banner() {
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)
    if [[ $cols -ge 60 ]]; then
        printf '\e[1;36m🌺 Termux Zsh\e[0m\n'
    else
        printf '\e[0;36m🌺\e[0m\n'
    fi
}
