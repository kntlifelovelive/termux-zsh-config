# ~/.config/zsh/keybindings/spf.zsh
# SPF (super file manager) integration — Termux.
# Only active when the `spf` command is available.

if (( $+commands[spf] )); then
    function spf() {
        export SPF_LAST_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"

        command spf "$@"

        [ ! -f "$SPF_LAST_DIR" ] || {
            . "$SPF_LAST_DIR"
            rm -f -- "$SPF_LAST_DIR" > /dev/null 2>&1
        }
    }

    function spf_widget() {
        zle push-line
        BUFFER="spf"
        zle accept-line
    }

    zle -N spf_widget
    bindkey '^g' spf_widget
fi
