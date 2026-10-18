# ~/.config/zsh/.zshrc
# Minimal, modular Zsh configuration for Termux.
# Loaded after .zshenv for interactive shells.

# 1. Core settings (must be first)
source "$ZDOTDIR/config/exports.zsh"
source "$ZDOTDIR/config/options.zsh"

# 2. Modules (tool-specific configs — each guards on its own command)
for mod in "$ZDOTDIR/modules/"*.zsh(N); do
    [[ -f "$mod" ]] && source "$mod"
done

# 3. Aliases (after PATH is set)
source "$ZDOTDIR/config/aliases.zsh"

# 4. Keybindings
for kb in "$ZDOTDIR/keybindings/"*.zsh(N); do
    [[ -f "$kb" ]] && source "$kb"
done

# 5. Functions
for func in "$ZDOTDIR/functions/"*.zsh(N); do
    [[ -f "$func" ]] && source "$func"
done

# 6. Theme (last)
source "$ZDOTDIR/themes/prompt.zsh"
