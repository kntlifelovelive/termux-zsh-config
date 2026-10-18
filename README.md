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

## Installation

```bash
git clone https://github.com/kntlifelovelive/termux-zsh-config.git
cd termux-zsh-config
./install
```

The installer:

1. Verifies it is running in native Termux (stops safely otherwise).
2. Installs missing **required** packages via `pkg install`
   (`zsh`, `git`, `eza`, `fzf`, `zoxide`, `micro`).
3. Never runs `pkg upgrade`.
4. Backs up any existing `$HOME/.zshenv` and `$HOME/.config/zsh/` to a
   timestamped `$HOME/.config/zsh-backup-<stamp>/`.
5. Copies (never symlinks) the configuration into place.
6. Validates the installed files with `zsh -n` and runs a startup test.
7. Optionally sets Zsh as your default login shell (with your confirmation).
8. Prints success or failure messages and explains how to restore.

## Packages

**Required (installed automatically if missing):**

- `zsh` — the shell itself
- `git` — prompt git integration + git aliases
- `eza` — default `ls` replacement (aliases `e`, `ea`, `el`, …)
- `fzf` — default file/folder finder keybindings (Ctrl+T / Ctrl+F)
- `zoxide` — default smarter-`cd` (`z` integration)
- `micro` — default editor (aliased to `n`)

**Optional (install manually, never installed automatically):**

```bash
pkg install curl bat ripgrep fd-find vim procps
```

Each optional feature is guarded on its command existing, so the
configuration starts fine even when none of the optional tools are installed.

Correct Termux package names are used (e.g. `rg` for ripgrep,
`fd-find` for fd).

## Default login shell

After installing the configuration, the installer offers to set Zsh as your
default login shell:

```bash
chsh -s "$PREFIX/bin/zsh"
```

It will:

1. Confirm Zsh is installed and executable at `$PREFIX/bin/zsh`.
2. Detect your current login shell.
3. Check that Zsh is listed in your shells file
   (`$PREFIX/etc/shells` or `/etc/shells`).
4. Ask for confirmation before changing anything.
5. If you decline, finish the configuration install without changing the shell.
6. If the change fails, show exact recovery instructions.

If your shell is already Zsh, the step is skipped and reported.

To return to Bash (or another shell) later, run:

```bash
chsh -s "$PREFIX/bin/bash"
```

The shell change takes effect in **new** login sessions, not your current one.

## Prompt customization

The prompt is a compact two-line design:

```
┌─(bubu)-[~]
└─ ❯
```

It is lightweight, uses no Nerd Fonts, and never shows your Android system
username. Customize it by setting variables before the config loads (for
example in `$HOME/.config/zsh/config/exports.zsh` or `~/.zshrc`):

```bash
# Display label (default: bubu)
BUBU_PROMPT_LABEL="mytermux"

# Show a short git branch in the prompt (default: 0 = off)
BUBU_PROMPT_GIT=1
```

When `BUBU_PROMPT_GIT=1` and you are inside a git repository, a short branch
name appears unobtrusively (e.g. `(main)` or `(feat/...)`, truncated if long).
Git integration is off by default so every prompt stays fast.

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
- The installer offers to set Zsh as your default login shell (with your
  confirmation); it never changes it without asking.
- Heavy desktop features from the reference repo (Oh My Zsh, plugin managers,
  animated banners, `command-not-found` package lookup) are intentionally
  omitted for Termux startup performance and reliability.
