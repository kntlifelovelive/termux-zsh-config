# ~/.config/zsh/functions/prompt.zsh
# Compact, dark-terminal-friendly prompt for Termux.
# Display label is configurable via BUBU_PROMPT_LABEL (default "bubu").
# Git integration is optional via BUBU_PROMPT_GIT=1 (off by default for speed).

# Configurable display label (override before sourcing, e.g. in exports.zsh).
BUBU_PROMPT_LABEL="${BUBU_PROMPT_LABEL:-bubu}"

# Enable short git branch in prompt (0 = off by default to stay lightweight).
BUBU_PROMPT_GIT="${BUBU_PROMPT_GIT:-0}"

function set_bubu_prompt() {
    local exit_code=$?
    local symbol="%F{magenta}❯%f"
    local git_part=""

    # Symbol color reflects the last command's exit status.
    if [[ $exit_code -ne 0 ]]; then
        symbol="%F{red}❯%f"
    fi

    # Optional, short git branch (guarded: git must exist and cwd is a repo).
    if [[ $BUBU_PROMPT_GIT -eq 1 ]] && (( $+commands[git] )); then
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            local branch dirty=""
            branch="$(git branch --show-current 2>/dev/null)"
            if [[ -n "$branch" ]]; then
                # Keep long branch names short and unobtrusive.
                if [[ ${#branch} -gt 18 ]]; then
                    branch="${branch:0:15}..."
                fi
                if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
                    dirty="%F{red}●%f"
                fi
                git_part=" %F{blue}(${branch})${dirty}%f"
            fi
        fi
    fi

    # Two clean lines: box + label + cwd, then arrow.
    # %~ is native Zsh: cwd with $HOME shortened to ~.
    PROMPT="%F{magenta}┌─(%F{green}${BUBU_PROMPT_LABEL}%f%F{magenta})-[%F{cyan}%~%f%F{magenta}]${git_part}
%F{magenta}└─${symbol} %f"
}
