# ~/.config/zsh/themes/prompt.zsh
# Main prompt configuration — Termux.

# Load the prompt function (idempotent re-definition is safe).
source "$ZDOTDIR/functions/prompt.zsh"

# Register the prompt as a precmd hook (exactly once).
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_bubu_prompt
