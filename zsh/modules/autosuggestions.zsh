# ~/.config/zsh/modules/autosuggestions.zsh
# zsh-autosuggestions — show previous-command suggestions as you type.
# Sourced BEFORE zsh-syntax-highlighting (see .zshrc load order).

_AUTOSUGGESTIONS="$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

if [[ -f "$_AUTOSUGGESTIONS" ]]; then
    source "$_AUTOSUGGESTIONS"

    # Accept the current suggestion with Ctrl+Space (insert mode only).
    if (( $+widgets[autosuggest-accept] )); then
        bindkey -M viins '^ ' autosuggest-accept
    fi

    # Keep suggestions subtle so they never compete with the typed command.
    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="${ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE:-fg=242}"
fi
