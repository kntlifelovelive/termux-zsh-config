# Termux Zsh Config

Lightweight modular Zsh configuration for **native Android Termux only**.
Copy-based install — no frameworks, no plugin managers, no symlinks, no sudo.

## Purpose

A dedicated Zsh configuration repository for Termux. It adapts a modular
Zsh design (aliases, functions, key bindings, completion, prompt) to the
Termux environment and deploys real file copies to:

- `$HOME/.zshenv`
- `$HOME/.config/zsh/`

It does not depend on the reference repository at install time.

## Requirements

- Native Android Termux
- A normal (non-root) user
- `zsh` (installed by the installer if missing)

## Installation

```bash
git clone https://github.com/kntlifelovelive/termux-zsh-config.git
cd termux-zsh-config
./install
```

The installer:

1. Verifies it is running in native Termux (stops safely otherwise).
2. Installs only missing required packages (`zsh`) via `pkg install`.
3. Never runs `pkg upgrade`.
4. Backs up any existing `$HOME/.zshenv` and `$HOME/.config/zsh/` to a
   timestamped `$HOME/.config/zsh-backup-<stamp>/`.
5. Copies (never symlinks) the configuration into place.
6. Validates the installed files with `zsh -n` and runs a startup test.
7. Prints success or failure messages and explains how to restore.

## Packages

**Required (installed automatically if missing):**

- `zsh` — the shell itself

**Optional (install manually, never installed automatically):**

```bash
pkg install git curl fzf zoxide eza bat ripgrep fd-find micro vim procps
```

Each optional feature is guarded, so the configuration starts fine even when
none of the optional tools are installed.

Correct Termux package names are used (e.g. `rg` for ripgrep, `fd-find` for fd).

## Installed folder structure

```
$HOME/.zshenv
$HOME/.config/zsh/
├── .zshrc
├── config/
│   ├── exports.zsh      # PATH and editor
│   ├── aliases.zsh      # pkg/system/git/eza aliases (guarded)
│   └── options.zsh      # history and completion options
├── functions/
│   ├── hooks.zsh        # command timing (preexec/precmd)
│   ├── prompt.zsh       # prompt function
│   └── utils.zsh        # print_banner
├── keybindings/
│   ├── main.zsh         # vi mode, cursor, autosuggest accept
│   └── spf.zsh          # superfile integration (guarded)
├── modules/
│   ├── fzf.zsh          # fzf init + widgets (guarded)
│   ├── zoxide.zsh       # zoxide init (guarded)
│   └── profiler.zsh     # zsh/zprof (optional)
└── themes/
    └── prompt.zsh       # sources the prompt function
```

## Backup and restore

Before replacing any existing configuration, the installer creates a
timestamped backup at:

```
$HOME/.config/zsh-backup-<YYYYMMDD-HHMMSS>/
```

To restore a previous configuration:

```bash
cp -a "$HOME/.config/zsh-backup-<stamp>/.zshenv" "$HOME/.zshenv"
cp -a "$HOME/.config/zsh-backup-<stamp>/zsh" "$HOME/.config/zsh"
```

Then start a new zsh session.

## Update procedure

Re-run the installer in the cloned repository:

```bash
cd termux-zsh-config
git pull
./install
```

Your current configuration is backed up and replaced; nothing is appended twice.

## Uninstallation

Remove the deployed files and restore your backup (if you have one):

```bash
rm -f "$HOME/.zshenv"
rm -rf "$HOME/.config/zsh"
# optional: restore from backup
cp -a "$HOME/.config/zsh-backup-<stamp>/.zshenv" "$HOME/.zshenv"
cp -a "$HOME/.config/zsh-backup-<stamp>/zsh" "$HOME/.config/zsh"
```

To remove optional packages you installed:

```bash
pkg uninstall fzf zoxide eza bat ripgrep fd-find micro vim procps
```

## Known limitations

- Native Termux only. Does not run on desktop Linux (Arch, Debian, Ubuntu).
- `zsh` must be installed; the installer handles this automatically.
- Optional features (fzf, zoxide, eza, ...) silently degrade when their
  command is missing — they never break startup.
- The installer does not change your default shell. Run `chsh -s zsh`
  manually if you want zsh as your login shell.
- Heavy desktop features from the reference repo (Oh My Zsh, plugin managers,
  animated banners, `command-not-found` package lookup) are intentionally
  omitted for Termux startup performance and reliability.
