# ~/.config/zsh/modules/system-clipboard.zsh
# zsh-system-clipboard — system clipboard integration for Termux.
#
# Requires the termux-api package, which provides:
#   termux-clipboard-get   read from the Android clipboard
#   termux-clipboard-set   write to the Android clipboard
#
# If termux-api is not installed, this module is a no-op and startup is not
# affected. Install it with:  pkg install termux-api

_CLIPBOARD="$HOME/.zsh/plugins/zsh-system-clipboard/zsh-system-clipboard.zsh"

if [[ -f "$_CLIPBOARD" ]] \
    && (( $+commands[termux-clipboard-get] )) \
    && (( $+commands[termux-clipboard-set] )); then
    source "$_CLIPBOARD"
fi
