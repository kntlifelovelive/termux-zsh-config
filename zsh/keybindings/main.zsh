# ~/.config/zsh/keybindings/main.zsh
# Core keybindings and Vi mode — Termux.

# ============================================
# Vi mode setup
# ============================================
bindkey -v
export KEYTIMEOUT=20

# jk to exit insert mode (fast escape)
bindkey -M viins 'jk' vi-cmd-mode

# ============================================
# Autosuggestions (if plugin provides the widget)
# ============================================
if (( $+widgets[autosuggest-accept] )); then
    bindkey -M viins '^ ' autosuggest-accept
fi

# ============================================
# Cursor shape (block for normal, beam for insert)
# ============================================
function zle-keymap-select {
    if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
        echo -ne '\e[2 q'   # Normal mode: block cursor
    else
        echo -ne '\e[6 q'   # Insert mode: beam cursor
    fi
}
zle -N zle-keymap-select

_fix_cursor() { echo -ne '\e[6 q' }
precmd_functions+=(_fix_cursor)
