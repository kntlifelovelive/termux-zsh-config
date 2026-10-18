# ~/.config/zsh/modules/fzf.zsh
# fzf integration — Termux.
# Every feature is guarded on its command existing, so missing tools never
# break startup.

# Initialize fzf for Zsh.
if (( $+commands[fzf] )); then
    eval "$(fzf --zsh 2>/dev/null)" || true
    export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---bind 'j:down,k:up,ctrl-d:page-down,ctrl-u:page-up'}"

    # Choose a file lister: fd if available, otherwise find.
    if (( $+commands[fd] )); then
        _fzf_list_files() { fd --hidden --exclude .git --type f "$@" 2>/dev/null; }
    else
        _fzf_list_files() { find . -type f 2>/dev/null; }
    fi

    # --- Smart file opener (Ctrl+T) ---
    fzf-file-widget() {
        local selected_path
        selected_path=$(_fzf_list_files | fzf \
            --layout=reverse --height=85% \
            --header="  File Search | [Enter] Open" \
            --header-first \
            --prompt="  || Search > " 2>/dev/null)
        if [[ -n "$selected_path" ]]; then
            if [[ -d "$selected_path" ]]; then
                cd "$selected_path"
            else
                if (( $+commands[micro] )); then
                    micro "$selected_path"
                elif (( $+commands[vim] )); then
                    vim "$selected_path"
                elif (( $+commands[vi] )); then
                    vi "$selected_path"
                fi
            fi
        fi
        zle reset-prompt
    }

    # --- Folder search (Ctrl+F) ---
    fzf-cd-widget() {
        local dest
        if (( $+commands[fd] )); then
            dest=$(fd --type=d --hidden --exclude .git 2>/dev/null | fzf \
                --layout=reverse --height=85% \
                --header="  Folder Search | [Enter] Change Directory" \
                --header-first \
                --prompt="    Search > " 2>/dev/null)
        else
            dest=$(find . -type d 2>/dev/null | fzf \
                --layout=reverse --height=85% \
                --header="  Folder Search | [Enter] Change Directory" \
                --header-first \
                --prompt="    Search > " 2>/dev/null)
        fi
        [[ -n "$dest" ]] && cd "$dest"
        zle reset-prompt
    }

    zle -N fzf-file-widget
    bindkey '^t' fzf-file-widget
    bindkey -M viins '^t' fzf-file-widget
    bindkey -M vicmd '^t' fzf-file-widget

    zle -N fzf-cd-widget
    bindkey '^f' fzf-cd-widget
    bindkey -M viins '^f' fzf-cd-widget
    bindkey -M vicmd '^f' fzf-cd-widget
fi
