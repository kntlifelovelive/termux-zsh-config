# ~/.config/zsh/functions/prompt.zsh
# Prompt function definition (Termux).
# Registered as a precmd hook by themes/prompt.zsh.

function set_bubu_prompt() {
    local exit_code=$?
    local git_branch=""
    local prompt_symbol=">"
    local venv_name=""

    # Detect active Python virtual environment.
    if [[ -n "$VIRTUAL_ENV" ]]; then
        venv_name="(%F{green}\uf499 $(basename "$VIRTUAL_ENV")%f) "
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        venv_name="(%F{green}\uf499 $CONDA_DEFAULT_ENV%f) "
    fi

    # Git branch & dirty check (skip entirely when git is not installed).
    if (( $+commands[git] )) && git rev-parse --git-dir >/dev/null 2>&1; then
        local branch_name
        branch_name=$(git branch --show-current 2>/dev/null)
        git_branch=" %F{cyan}\uf428%f %F{blue}${branch_name}%f"

        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            git_branch=" %F{red}\uf428%f %F{blue}${branch_name}%f"
        fi
    fi

    # Command error check (arrow color reflects exit status only).
    if [[ $exit_code -ne 0 ]]; then
        prompt_symbol="%F{red}>%f"
    fi

    # User color.
    if [[ $EUID -eq 0 ]]; then
        user_color="%F{red}"
    else
        user_color="%F{220}%B"
    fi

    PROMPT="%F{magenta}\u2502(${venv_name}${user_color}%n%f%F{magenta})-[%F{cyan}~%f%F{magenta}]${git_branch}
%F{magenta}\u2514${prompt_symbol} %f"
}
