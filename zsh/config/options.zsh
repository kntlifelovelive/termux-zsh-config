# ~/.config/zsh/config/options.zsh
# History and shell options — Termux.

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="${ZDOTDIR:-$HOME/.config/zsh}/.zhistory"

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Misc
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
