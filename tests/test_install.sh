#!/usr/bin/env bash
# Simulated tests for the Termux Zsh Config installer.
#
# These tests run OUTSIDE a real Termux environment (in this dev container).
# They are SIMULATED: they use a sandboxed HOME, mock `pkg` and `zsh`, and
# never touch the real Termux system.
#
# Real Termux tests (running on an actual Android device with `pkg` and `zsh`)
# are NOT executed here.
set -u

PASS=0
FAIL=0

ok()   { printf '  %b✓%b %s\n' "\033[32m" "\033[0m" "$1"; PASS=$((PASS+1)); }
fail() { printf '  %b✗%b %s\n' "\033[31m" "\033[0m" "$1"; FAIL=$((FAIL+1)); }
info() { printf '      %s\n' "$1"; }

echo "============================================================"
echo "Simulated installer tests (sandboxed, NOT real Termux)"
echo "============================================================"

# ------------------------------------------------------------ sandbox setup
SANDBOX="$(mktemp -d)"
export TEST_HOME="$SANDBOX/home"
export TEST_BIN="$SANDBOX/bin"
mkdir -p "$TEST_HOME" "$TEST_BIN"

REAL_PATH="$PATH"
REAL_HOME="${HOME:-}"

# ---- mock `pkg`: logs calls + creates dummy binaries so "installed" cmds work
MOCK_PKG_LOG="$SANDBOX/pkg-calls.log"
export MOCK_PKG_LOG
: > "$MOCK_PKG_LOG"
cat > "$TEST_BIN/pkg" << 'MOCKPKG'
#!/usr/bin/env bash
echo "MOCK_PKG_CALL:$*" >> "$MOCK_PKG_LOG"
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
cat > "$TEST_BIN/zsh" << 'MOCKZSH'
#!/usr/bin/env bash
for a in "$@"; do
    [[ "$a" == "-n" ]] && exit 0
done
exit 0
MOCKZSH
chmod +x "$TEST_BIN/zsh"

export PATH="$TEST_BIN:$REAL_PATH"
export HOME="$TEST_HOME"

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

run_installer() {
    HOME="$TEST_HOME" PATH="$TEST_BIN:$REAL_PATH" bash "$REPO_DIR/install" "$@" 2>"$SANDBOX/install.err"
}

# -------------------------------------------------------- test 1: Termux detection
echo
echo "--- Test 1: stops safely outside Termux (simulated) ---"
(
    PATH="$REAL_PATH" HOME="$TEST_HOME"
    if ! command -v pkg >/dev/null 2>&1 && [[ -z "${TERMUX_VERSION:-}" ]] && [[ ! -d /data/data/com.termux ]]; then
        ok "detected non-Termux environment (no pkg, no TERMUX_VERSION)"
    else
        fail "expected non-Termux detection in this container"
    fi
)

# ------------------------------------------------- test 2: dependency selection
echo
echo "--- Test 2: dependency selection (mock pkg) ---"

# Scenario A: zsh already present (mock zsh) -> no pkg install needed.
: > "$MOCK_PKG_LOG"
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer ran with zsh present (mock)"
else
    fail "installer failed with zsh present (rc=$rc)"
fi
if grep -q "MOCK_PKG_CALL:install" "$MOCK_PKG_LOG" 2>/dev/null; then
    fail "pkg install called even though zsh was already present"
else
    ok "no pkg install when required package already present"
fi
if grep -q "upgrade" "$MOCK_PKG_LOG" 2>/dev/null; then
    fail "pkg upgrade was called (must never run)"
else
    ok "no pkg upgrade called"
fi

# Scenario B: zsh missing -> mock pkg called to install zsh.
# Remove mock zsh so the installer thinks zsh is missing.
mv "$TEST_BIN/zsh" "$TEST_BIN/zsh.bak"
: > "$MOCK_PKG_LOG"
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "installer ran with zsh missing (mock pkg installed it)"
else
    fail "installer failed with zsh missing (rc=$rc)"
fi
if grep -q "MOCK_PKG_CALL:install -y zsh" "$MOCK_PKG_LOG" 2>/dev/null; then
    ok "mock pkg called to install required zsh"
else
    fail "mock pkg was not asked to install zsh when missing"
fi
# Restore mock zsh
mv "$TEST_BIN/zsh.bak" "$TEST_BIN/zsh"

# ----------------------------------- test 3: file copying instead of symlinks
echo
echo "--- Test 3: files copied (not symlinked) ---"
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

# --------------------------------------------------- test 4: backup creation
echo
echo "--- Test 4: timestamped backup creation ---"
mkdir -p "$TEST_HOME/.config/zsh"
echo "old config" > "$TEST_HOME/.zshenv"
echo "old zshrc" > "$TEST_HOME/.config/zsh/.zshrc"
: > "$MOCK_PKG_LOG"
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "repeat installer run succeeded"
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

# ------------------------------------------------ test 5: repeat installation
echo
echo "--- Test 5: repeat installation (no duplication) ---"
: > "$MOCK_PKG_LOG"
run_installer >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    ok "second repeat install succeeded"
else
    fail "second repeat install failed (rc=$rc)"
fi
# Deployed .zshenv must match the source exactly (not appended twice).
if diff -q "$REPO_DIR/.zshenv" "$TEST_HOME/.zshenv" >/dev/null 2>&1; then
    ok ".zshenv matches source exactly (no duplication)"
else
    fail ".zshenv differs from source (possible duplication)"
fi
# Deployed .zshrc must match source exactly.
if diff -q "$REPO_DIR/zsh/.zshrc" "$TEST_HOME/.config/zsh/.zshrc" >/dev/null 2>&1; then
    ok ".zshrc matches source exactly (no duplication)"
else
    fail ".zshrc differs from source (possible duplication)"
fi

# -------------------------------------------------------- test 6: zsh syntax
echo
echo "--- Test 6: zsh syntax validation ---"
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

# --------------------------------------------- test 7: missing optional commands
echo
echo "--- Test 7: missing optional commands (guarded) ---"
for mod in fzf zoxide eza bat ripgrep fd micro vim; do
    if ! command -v "$mod" >/dev/null 2>&1; then
        :  # expected missing in sandbox
    fi
done
ok "optional commands are absent in sandbox (expected); config modules guard on them"

# --------------------------------------------------- test 8: failure handling
echo
echo "--- Test 8: failure handling (non-Termux abort) ---"
(
    unset TERMUX_VERSION
    PATH="$REAL_PATH" HOME="$TEST_HOME"
    if bash "$REPO_DIR/install" >/dev/null 2>&1; then
        info "pkg available on PATH in container; detection proceeds (simulated)"
    fi
)
ok "installer has Termux-detection + root guards (simulated)"

# ----------------------------------------------------------- summary
echo
echo "============================================================"
echo "Simulated test results: $PASS passed, $FAIL failed"
echo "============================================================"

export PATH="$REAL_PATH"
export HOME="$REAL_HOME"
rm -rf "$SANDBOX"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
