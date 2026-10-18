# ~/.config/zsh/.zshrc
# Minimal, modular Zsh configuration for Termux.
# Loaded after .zshenv for interactive shells.

# 1. Core settings (must be first)
source "$ZDOTDIR/config/exports.zsh"
source "$ZDOTDIR/config/options.zsh"

# 2. General modules (order-independent).
#    Plugin modules (autosuggestions, system-clipboard, zoxide, fzf,
#    syntax-highlighting) are sourced explicitly below in the required order
#    so they are not picked up by this glob.
for mod in "$ZDOTDIR/modules/"*.zsh(N); do
    case "$mod:t" in
        autosuggestions.zsh|syntax-highlighting.zsh|system-clipboard.zsh|zoxide.zsh|fzf.zsh)
            continue ;;
    esac
    [[ -f "$mod" ]] && source "$mod"
done

# 3. Aliases (after PATH is set)
source "$ZDOTDIR/config/aliases.zsh"

# 4. Keybindings (defines custom ZLE widgets)
for kb in "$ZDOTDIR/keybindings/"*.zsh(N); do
    [[ -f "$kb" ]] && source "$kb"
done

# 5. Functions
for func in "$ZDOTDIR/functions/"*.zsh(N); do
    [[ -f "$func" ]] && source "$func"
done

# 6. Theme (prompt)
source "$ZDOTDIR/themes/prompt.zsh"

# 7. Plugins — loaded in order.
#    zsh-syntax-highlighting MUST be sourced last, after all other plugins
#    and custom ZLE widgets, so it can wrap them correctly.
source "$ZDOTDIR/modules/autosuggestions.zsh"
source "$ZDOTDIR/modules/system-clipboard.zsh"
source "$ZDOTDIR/modules/zoxide.zsh"
source "$ZDOTDIR/modules/fzf.zsh"
source "$ZDOTDIR/modules/syntax-highlighting.zsh"
