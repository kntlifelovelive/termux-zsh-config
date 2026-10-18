# ~/.config/zsh/modules/profiler.zsh
# Measure zsh startup time (optional).
# Uncomment the zprof call at the end of .zshrc to use.

zmodload zsh/zprof 2>/dev/null || true
