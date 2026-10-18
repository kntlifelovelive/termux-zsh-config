# ~/.zshenv
# Loaded FIRST for every zsh session — Termux-only configuration.
#
# This file is copied to $HOME/.zshenv by the installer. It sets ZDOTDIR so
# the rest of the modular configuration lives under $HOME/.config/zsh.

# Set ZDOTDIR (default $HOME/.config/zsh). Honors an existing ZDOTDIR.
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Basic environment
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
