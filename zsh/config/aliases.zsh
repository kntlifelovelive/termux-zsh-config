# ~/.config/zsh/config/aliases.zsh
# All aliases organized by category — Termux-only.
# Every alias is guarded on its command existing, so missing tools never
# break startup.

# ============================================
# System / package (Termux pkg)
# ============================================
(( $+commands[pkg] )) && alias update='pkg update'
(( $+commands[pkg] )) && alias install='pkg install'
(( $+commands[pkg] )) && alias uninstall='pkg uninstall'
(( $+commands[pkg] )) && alias search='pkg search'
(( $+commands[pkg] )) && alias list-installed='pkg list-installed'

# No sudo, no desktop shutdown/reboot on Termux.

# ============================================
# Generic (guarded)
# ============================================
(( $+commands[grep] )) && alias grep='grep --color=auto'
(( $+commands[ls] )) && alias ls='ls --color=auto'
(( $+commands[clear] )) && alias c='clear'

# Editor shortcuts
(( $+commands[micro] )) && alias n='micro'
(( $+commands[vim] )) && alias n='vim'
(( $+commands[vi] )) && alias n='vi'

# ============================================
# EZA (modern ls replacement — optional)
# ============================================
if (( $+commands[eza] )); then
    alias e='eza --icons'
    alias ea='eza -a --icons'
    alias el='eza -lh --icons --group-directories-first'
    alias elt='eza -lh --total-size --icons --group-directories-first'
    alias eltt='eza -lh --total-size --tree --icons --group-directories-first'
    alias ela='eza -alh --icons --group-directories-first'
fi

# ============================================
# Git (optional)
# ============================================
if (( $+commands[git] )); then
    alias g='git'
    alias gs='git status'
    alias gl='git pull'
    alias gp='git push'
fi
