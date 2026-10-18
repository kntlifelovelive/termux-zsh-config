# ~/.config/zsh/modules/syntax-highlighting.zsh
# zsh-syntax-highlighting — highlight commands as they are typed.
#
# LOAD ORDER MATTERS: this module MUST be sourced LAST, after all other
# plugins and custom ZLE widgets, so it can wrap them correctly.
# .zshrc sources it explicitly as the final step.

_SYNTAX_HIGHLIGHTING="$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

if [[ -f "$_SYNTAX_HIGHLIGHTING" ]]; then
    source "$_SYNTAX_HIGHLIGHTING"
fi
