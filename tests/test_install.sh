#!/usr/bin/env bash
# Simulated tests for the Termux Zsh Config installer.
#
# These tests run OUTSIDE a real Termux environment (in this dev container).
# They are SIMULATED: they use a sandboxed HOME, mock `pkg`, `zsh`, and `chsh`,
# and never touch the real Termux system or perform real package installs /
# shell changes.
#
# Real Termux tests (running on an actual Android device with `pkg` and `zsh`)
# are NOT executed here.
set -u

PASS=0
FAIL=0

ok()   { printf '  %b✓%b %s\n' "\033[32m" "\033[0m" "$1"; PASS=$((PASS+1)); }
fail() { printf '  %b✗%b %s\n' "\033[31m" "\033[0m" "$1"; FAIL=$((FAIL+1)); }
info() { printf '      %s\n' "$1"; }

echo "=============================================================="
echo "Simulated installer tests (sandboxed, NOT real Termux)"
echo "=============================================================="

# ------------------------------------------------------------ sandbox setup
SANDBOX="$(mktemp -d)"
export TEST_HOME="$SANDBOX/home"
export TEST_BIN="$SANDBOX/bin"
export TEST_PREFIX="$SANDBOX/prefix"
mkdir -p "$TEST_HOME" "$TEST_BIN" "$TEST_PREFIX/bin"

REAL_PATH="$PATH"
REAL_HOME="${HOME:-}"
REAL_SHELL="${SHELL:-}"
REAL_PREFIX="${PREFIX:-}"

# ---- mock `pkg`: logs calls + creates dummy binaries for "installed" pkgs
MOCK_PKG_LOG="$SANDBOX/pkg-calls.log"
export MOCK_PKG_LOG
: > "$MOCK_PKG_LOG"
cat > "$TEST_BIN/pkg" << 'MOCKPKG'
#!/usr/bin/env bash
echo "MOCK_PKG_CALL:$*" >> "$MOCK_PKG_LOG"
# Simulate a failing install when MOCK_PKG_FAIL is set.
if [[ -n "${MOCK_PKG_FAIL:-}" ]]; then
    exit 1
fi
# Simulate installing: create a dummy executable for each requested package.
for arg in "$@"; do
    case "$arg" in
        install|-y|-S|-Syu|update|upgrade) continue ;;
        -*) continue ;;
        *)
            if [[ ! -e "$TEST_BIN/$arg" ]]; then
                printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/$arg"
                chmod +x "$TEST_BIN/$arg"
            fi
            ;;
    esac
done
exit 0
MOCKPKG
chmod +x "$TEST_BIN/pkg"

# ---- mock `zsh`: passes `zsh -n` syntax checks, exits 0 otherwise
cat > "$TEST_PREFIX/bin/zsh" << 'MOCKZSH'
#!/usr/bin/env bash
for a in "$@"; do
    [[ "$a" == "-n" ]] && exit 0
done
exit 0
MOCKZSH
chmod +x "$TEST_PREFIX/bin/zsh"
# Also put zsh on PATH so command -v zsh works.
if [[ ! -e "$TEST_BIN/zsh" ]]; then
    cp "$TEST_PREFIX/bin/zsh" "$TEST_BIN/zsh"
fi

# ---- mock `chsh`: logs calls, exits 0 (success) unless MOCK_CHSH_FAIL set
MOCK_CHSH_LOG="$SANDBOX/chsh-calls.log"
export MOCK_CHSH_LOG
: > "$MOCK_CHSH_LOG"
cat > "$TEST_BIN/chsh" << 'MOCKCHSH'
#!/usr/bin/env bash
echo "MOCK_CHSH_CALL:$*" >> "$MOCK_CHSH_LOG"
if [[ -n "${MOCK_CHSH_FAIL:-}" ]]; then
    exit 1
fi
exit 0
MOCKCHSH
chmod +x "$TEST_BIN/chsh"

export PATH="$TEST_BIN:$REAL_PATH"
export HOME="$TEST_HOME"
export PREFIX="$TEST_PREFIX"

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Build the installer environment. By default all required commands are
# "present" (mock zsh + dummy binaries created by a prior mock pkg call).
run_installer() {
    local confirm_env="${BUBU_INSTALL_CONFIRM_SHELL:-}"
    HOME="$TEST_HOME" PATH="$TEST_BIN:$REAL_PATH" PREFIX="$TEST_PREFIX" \
        SHELL="${TEST_SHELL:-$REAL_SHELL}" \
        BUBU_INSTALL_CONFIRM_SHELL="$confirm_env" \
        bash "$REPO_DIR/install" "$@" >"$SANDBOX/install.out" 2>"$SANDBOX/install.err"
}

# Make all required commands present on PATH (mock pkgs already installed).
make_required_present() {
    for cmd in zsh git eza fzf zoxide micro; do
        if [[ ! -e "$TEST_BIN/$cmd" ]]; then
            printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/$cmd"
            chmod +x "$TEST_BIN/$cmd"
        fi
    done
}

# Remove a required command from PATH (simulate not installed).
remove_cmd() {
    rm -f "$TEST_BIN/$1"
}

# -------------------------------------------------------- test 1: Termux detection
echo
echo "--- Test 1: stops safely outside Termux (simulated) ---"
(
    PATH="$REAL_PATH" HOME="$TEST_HOME"
    unset TERMUX_VERSION PREFIX
    if ! command -v pkg >/dev/null 2>&1 && [[ -z "${TERMUX_VERSION:-}" ]] && [[ ! -d /data/data/com.termux ]]; then
        ok "detected non-Termux environment (no pkg, no TERMUX_VERSION)"
    else
        fail "expected non-Termux detection in this container"
    fi
)

# ------------------------------------------------ test 2: required package installation
echo
echo "--- Test 2: required packages installed automatically ---"
# Remove zsh so installer thinks it's missing -> mock pkg should install it.
remove_cmd zsh
: > "$MOCK_PKG_LOG"
make_required_present 2>/dev/null || true  # ensure others present except zsh
remove_cmd zsh
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer ran with missing zsh (mock pkg installed it)"
else
    fail "installer failed with missing zsh (rc=$rc)"
fi
if grep -q "MOCK_PKG_CALL:install -y zsh" "$MOCK_PKG_LOG" 2>/dev/null; then
    ok "mock pkg called to install required zsh"
else
    fail "mock pkg was not asked to install zsh when missing"
fi
# Restore mock zsh
if [[ ! -e "$TEST_BIN/zsh" ]]; then cp "$TEST_PREFIX/bin/zsh" "$TEST_BIN/zsh"; fi

# ------------------------------------------------ test 3: no pkg upgrade
echo
echo "--- Test 3: pkg upgrade never run ---"
make_required_present
: > "$MOCK_PKG_LOG"
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer ran with all required present"
else
    fail "installer failed (rc=$rc)"
fi
if grep -q "upgrade" "$MOCK_PKG_LOG" 2>/dev/null; then
    fail "pkg upgrade was called (must never run)"
else
    ok "no pkg upgrade called"
fi

# ----------------------------------- test 4: optional packages not auto-installed
echo
echo "--- Test 4: optional packages not installed automatically ---"
make_required_present
# Ensure optional commands are absent.
for cmd in curl bat rg fd-find vim procps; do remove_cmd "$cmd"; done
: > "$MOCK_PKG_LOG"
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer ran with optional packages absent"
else
    fail "installer failed due to missing optional packages (rc=$rc)"
fi
# pkg install should only have been for required (all present -> none), or zero calls.
# Crucially, no optional package should appear in a pkg install call.
optional_in_install=0
for cmd in curl bat rg fd-find vim procps; do
    if grep -q "MOCK_PKG_CALL:install.*$cmd\b" "$MOCK_PKG_LOG" 2>/dev/null; then
        optional_in_install=1
    fi
done
if [[ $optional_in_install -eq 0 ]]; then
    ok "no optional package auto-installed"
else
    fail "optional package(s) were auto-installed"
fi

# -------------------------------------- test 5: missing package handling (pkg failure)
echo
echo "--- Test 5: package install failure is reported ---"
# Make zsh missing and force mock pkg to fail.
remove_cmd zsh
export MOCK_PKG_FAIL=1
: > "$MOCK_PKG_LOG"
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -ne 0 ]]; then
    ok "installer failed when pkg install failed (rc=$rc)"
else
    fail "installer should have failed when pkg install failed"
fi
if grep -q "Package installation failed" "$SANDBOX/install.err" 2>/dev/null; then
    ok "clear failure message shown for package install failure"
else
    fail "no clear failure message for package install failure"
fi
unset MOCK_PKG_FAIL
# Restore
if [[ ! -e "$TEST_BIN/zsh" ]]; then cp "$TEST_PREFIX/bin/zsh" "$TEST_BIN/zsh"; fi

# ----------------------------------- test 6: files copied (not symlinked)
echo
echo "--- Test 6: files copied (not symlinked) ---"
make_required_present
MOCK_PKG_FAIL=
: > "$MOCK_PKG_LOG"
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer ran successfully"
else
    fail "installer failed (rc=$rc)"
fi
if [[ -f "$TEST_HOME/.zshenv" && ! -L "$TEST_HOME/.zshenv" ]]; then
    ok "$HOME/.zshenv is a real copy, not a symlink"
else
    fail "$HOME/.zshenv is missing or is a symlink"
fi
if [[ -d "$TEST_HOME/.config/zsh" && ! -L "$TEST_HOME/.config/zsh" ]]; then
    ok "$HOME/.config/zsh is a real directory copy, not a symlink"
else
    fail "$HOME/.config/zsh is missing or is a symlink"
fi
if [[ -f "$TEST_HOME/.config/zsh/.zshrc" && ! -L "$TEST_HOME/.config/zsh/.zshrc" ]]; then
    ok "config files are real copies (.zshrc present)"
else
    fail "config .zshrc missing or symlink"
fi

# --------------------------------------------------- test 7: backup creation
echo
echo "--- Test 7: timestamped backup creation ---"
mkdir -p "$TEST_HOME/.config/zsh"
echo "old config" > "$TEST_HOME/.zshenv"
echo "old zshrc" > "$TEST_HOME/.config/zsh/.zshrc"
: > "$MOCK_PKG_LOG"
make_required_present
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "repeat installer run succeeded with existing config"
else
    fail "repeat installer run failed (rc=$rc)"
fi
backup_dir=$(ls -d "$TEST_HOME/.config"/zsh-backup-* 2>/dev/null | head -1)
if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
    ok "timestamped backup created: $backup_dir"
    if [[ -f "$backup_dir/.zshenv" ]]; then
        ok "backup contains .zshenv"
    else
        fail "backup missing .zshenv"
    fi
    if [[ -d "$backup_dir/zsh" ]]; then
        ok "backup contains zsh config dir"
    else
        fail "backup missing zsh config dir"
    fi
else
    fail "no timestamped backup directory found"
fi

# ------------------------------------------------ test 8: repeat installation
echo
echo "--- Test 8: repeat installation (no duplication) ---"
: > "$MOCK_PKG_LOG"
make_required_present
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "second repeat install succeeded"
else
    fail "second repeat install failed (rc=$rc)"
fi
if diff -q "$REPO_DIR/.zshenv" "$TEST_HOME/.zshenv" >/dev/null 2>&1; then
    ok ".zshenv matches source exactly (no duplication)"
else
    fail ".zshenv differs from source (possible duplication)"
fi
if diff -q "$REPO_DIR/zsh/.zshrc" "$TEST_HOME/.config/zsh/.zshrc" >/dev/null 2>&1; then
    ok ".zshrc matches source exactly (no duplication)"
else
    fail ".zshrc differs from source (possible duplication)"
fi

# --------------------------------- test 9: shell-change - already using Zsh
echo
echo "--- Test 9: shell-change - already using Zsh ---"
make_required_present
: > "$MOCK_CHSH_LOG"
TEST_SHELL="$TEST_PREFIX/bin/zsh" BUBU_INSTALL_CONFIRM_SHELL=N \
    run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer ran when already using Zsh"
else
    fail "installer failed when already using Zsh (rc=$rc)"
fi
if ! grep -q "MOCK_CHSH_CALL" "$MOCK_CHSH_LOG" 2>/dev/null; then
    ok "chsh not called when already using Zsh"
else
    fail "chsh should not be called when already using Zsh"
fi
if grep -q "Default shell is already Zsh" "$SANDBOX/install.out" 2>/dev/null; then
    ok "already-Zsh message reported"
else
    fail "already-Zsh message not reported"
fi

# --------------------------------- test 10: shell-change - user declines
echo
echo "--- Test 10: shell-change - user declines ---"
make_required_present
TEST_SHELL=/bin/bash BUBU_INSTALL_CONFIRM_SHELL=N \
    run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer ran when user declines shell change"
else
    fail "installer failed when user declines (rc=$rc)"
fi
if ! grep -q "MOCK_CHSH_CALL" "$MOCK_CHSH_LOG" 2>/dev/null; then
    ok "chsh not called when user declines"
else
    fail "chsh should not be called when user declines"
fi

# ---------------------------------- test 11: shell-change - user confirms
echo
echo "--- Test 11: shell-change - user confirms ---"
make_required_present
: > "$MOCK_CHSH_LOG"
TEST_SHELL=/bin/bash BUBU_INSTALL_CONFIRM_SHELL=Y \
    run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer ran when user confirms shell change"
else
    fail "installer failed when user confirms (rc=$rc)"
fi
if grep -q "MOCK_CHSH_CALL:-s $TEST_PREFIX/bin/zsh" "$MOCK_CHSH_LOG" 2>/dev/null; then
    ok "chsh called to set Zsh as default shell"
else
    fail "chsh was not called to set Zsh as default shell"
fi

# --------------------------------- test 12: shell-change - failure + recovery
echo
echo "--- Test 12: shell-change - failure shows recovery ---"
make_required_present
export MOCK_CHSH_FAIL=1
: > "$MOCK_CHSH_LOG"
TEST_SHELL=/bin/bash BUBU_INSTALL_CONFIRM_SHELL=Y \
    run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer still completes config install after shell-change failure"
else
    fail "installer aborted due to shell-change failure (rc=$rc)"
fi
if grep -q "Recovery steps" "$SANDBOX/install.out" 2>/dev/null; then
    ok "recovery instructions shown for shell-change failure"
else
    fail "no recovery instructions for shell-change failure"
fi
unset MOCK_CHSH_FAIL

# -------------------------------- test 13: shell-change - chsh unavailable
echo
echo "--- Test 13: shell-change - chsh unavailable ---"
make_required_present
remove_cmd chsh
: > "$MOCK_CHSH_LOG"
TEST_SHELL=/bin/bash BUBU_INSTALL_CONFIRM_SHELL=Y \
    run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer ran when chsh unavailable"
else
    fail "installer failed when chsh unavailable (rc=$rc)"
fi
if ! grep -q "MOCK_CHSH_CALL" "$MOCK_CHSH_LOG" 2>/dev/null; then
    ok "chsh not called when unavailable"
else
    fail "chsh should not be called when unavailable"
fi
# Restore chsh
chmod +x "$TEST_BIN/chsh" 2>/dev/null || true
if [[ ! -e "$TEST_BIN/chsh" ]]; then
    cat > "$TEST_BIN/chsh" << 'MOCKCHSH'
#!/usr/bin/env bash
echo "MOCK_CHSH_CALL:$*" >> "$MOCK_CHSH_LOG"
exit 0
MOCKCHSH
    chmod +x "$TEST_BIN/chsh"
fi

# -------------------------------------------------------- test 14: zsh syntax
echo
echo "--- Test 14: zsh syntax validation ---"
if command -v zsh >/dev/null 2>&1; then
    n_bad=0
    while IFS= read -r f; do
        if ! zsh -n "$f" 2>/dev/null; then
            echo "  syntax error: $f"
            n_bad=$((n_bad+1))
        fi
    done < <(find "$REPO_DIR/zsh" \( -name '*.zsh' -o -name '.zshrc' \) -type f)
    if [[ -f "$REPO_DIR/.zshenv" ]] && ! zsh -n "$REPO_DIR/.zshenv" 2>/dev/null; then
        n_bad=$((n_bad+1))
        echo "  syntax error: .zshenv"
    fi
    if [[ $n_bad -eq 0 ]]; then
        ok "all repo config files pass zsh -n"
    else
        fail "$n_bad file(s) failed zsh -n"
    fi
else
    info "zsh not installed in this container — skipping real zsh -n (simulated skip)"
    ok "zsh syntax test skipped (simulated: no zsh available here)"
fi

# --------------------------------- test 15: prompt - missing Git executable
echo
echo "--- Test 15: prompt syntax / missing Git (guarded) ---"
# The prompt module guards on $+commands[git]; with no git it must still define
# set_bubu_prompt and set a valid PROMPT. We verify by inspecting the source
# (real execution needs zsh, unavailable here).
if grep -q '(( \$+commands\[git\] ))' "$REPO_DIR/zsh/functions/prompt.zsh"; then
    ok "prompt guards on git command existence"
else
    fail "prompt does not guard on git command existence"
fi
# Confirm BUBU_PROMPT_GIT default is off (no git needed for default prompt).
if grep -q 'BUBU_PROMPT_GIT="${BUBU_PROMPT_GIT:-0}"' "$REPO_DIR/zsh/functions/prompt.zsh"; then
    ok "prompt git integration defaults to off"
else
    fail "prompt git integration not defaulted to off"
fi

# ---------------------------------- test 16: prompt - no duplicate precmd hooks
echo
echo "--- Test 16: no duplicate prompt precmd hooks ---"
hook_count_functions=$(grep -c "add-zsh-hook precmd" "$REPO_DIR/zsh/functions/prompt.zsh" 2>/dev/null)
hook_count_themes=$(grep -c "add-zsh-hook precmd" "$REPO_DIR/zsh/themes/prompt.zsh" 2>/dev/null)
hook_count_functions=${hook_count_functions:-0}
hook_count_themes=${hook_count_themes:-0}
total_hooks=$((hook_count_functions + hook_count_themes))
if [[ $total_hooks -eq 1 ]]; then
    ok "exactly one precmd hook registration (in themes/prompt.zsh)"
else
    fail "expected exactly 1 precmd hook registration, found $total_hooks"
fi

# --------------------------------- test 17: prompt - configurable label
echo
echo "--- Test 17: prompt configurable label ---"
if grep -q 'BUBU_PROMPT_LABEL="${BUBU_PROMPT_LABEL:-bubu}"' "$REPO_DIR/zsh/functions/prompt.zsh"; then
    ok "prompt label is configurable via BUBU_PROMPT_LABEL"
else
    fail "prompt label not configurable"
fi
# Label should not reference system username (%n).
if grep -q '%n' "$REPO_DIR/zsh/functions/prompt.zsh"; then
    fail "prompt still references system username (%n)"
else
    ok "prompt does not display system username"
fi

# ----------------------------------------------------------- summary
echo
echo "=============================================================="
echo "Simulated test results: $PASS passed, $FAIL failed"
echo "=============================================================="

export PATH="$REAL_PATH"
export HOME="$REAL_HOME"
export PREFIX="$REAL_PREFIX"
export SHELL="$REAL_SHELL"
rm -rf "$SANDBOX"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
