# =============================================================================
# tests/helpers.sh — shared assertions for grok-cli CI tests
# =============================================================================
# Source from test scripts (POSIX /bin/sh). Does not modify product code.
# =============================================================================

# shellcheck disable=SC2034
: "${TESTS_ROOT:=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)}"
: "${REPO_ROOT:=$(CDPATH= cd -- "${TESTS_ROOT}/.." && pwd)}"
: "${SCRIPT:=${REPO_ROOT}/src/grok-cli}"
: "${APP_NAME:=grok-cli}"
: "${PASS:=0}"
: "${FAIL:=0}"
: "${SKIP:=0}"

# Product VERSION SSOT from ship unit (keep tests free of frozen semver literals)
PRODUCT_VERSION=$(grep '^VERSION="' "${SCRIPT}" 2>/dev/null | head -n1 | cut -d'"' -f2)
: "${PRODUCT_VERSION:=unknown}"
PRODUCT_APP=$(grep '^APP_NAME="' "${SCRIPT}" 2>/dev/null | head -n1 | cut -d'"' -f2)
: "${PRODUCT_APP:=${APP_NAME}}"
APP_NAME="${PRODUCT_APP}"

# --- output ---
t_info()  { printf '  · %s\n' "$*"; }
t_pass()  { PASS=$((PASS + 1)); printf '  PASS  %s\n' "$*"; }
t_fail()  { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$*" >&2; }
t_skip()  { SKIP=$((SKIP + 1)); printf '  SKIP  %s\n' "$*"; }
t_header() { printf '\n== %s ==\n' "$*"; }

# --- assertions ---
assert_eq() {
    _lab="$1"; _exp="$2"; _act="$3"
    if [ "$_exp" = "$_act" ]; then
        t_pass "$_lab"
    else
        t_fail "$_lab (expected='$(_trunc "$_exp")' actual='$(_trunc "$_act")')"
    fi
}

assert_contains() {
    _lab="$1"; _hay="$2"; _ndl="$3"
    case "$_hay" in
        *"$_ndl"*) t_pass "$_lab" ;;
        *) t_fail "$_lab (missing '$(_trunc "$_ndl")' in '$(_trunc "$_hay")')" ;;
    esac
}

assert_not_contains() {
    _lab="$1"; _hay="$2"; _ndl="$3"
    case "$_hay" in
        *"$_ndl"*) t_fail "$_lab (unexpected '$(_trunc "$_ndl")')" ;;
        *) t_pass "$_lab" ;;
    esac
}

assert_exit() {
    _lab="$1"; _exp="$2"; shift 2
    "$@" >/dev/null 2>&1
    _act=$?
    assert_eq "$_lab" "$_exp" "$_act"
}

assert_file_exists() {
    _lab="$1"; _path="$2"
    if [ -e "$_path" ]; then
        t_pass "$_lab"
    else
        t_fail "$_lab (missing $_path)"
    fi
}

assert_file_missing() {
    _lab="$1"; _path="$2"
    if [ -e "$_path" ]; then
        t_fail "$_lab (still exists: $_path)"
    else
        t_pass "$_lab"
    fi
}

_trunc() {
    printf '%s' "$1" | tr '\n' ' ' | cut -c1-160
}

# Isolated HOME + USER_BIN + GLOBAL_BIN for install tests.
# GLOBAL_BIN is redirected so a host /usr/local/bin install cannot pollute
# uninstall target selection or trust-tier detection (TP-LC / print-sudoers).
# Sets CI_HOME, CI_USER_BIN, CI_GLOBAL_BIN.
ci_isolated_env() {
    CI_HOME=$(mktemp -d "${TMPDIR:-/tmp}/fb-home.XXXXXX")
    CI_USER_BIN="${CI_HOME}/.local/bin"
    CI_GLOBAL_BIN="${CI_HOME}/.global-bin"
    mkdir -p "${CI_USER_BIN}" "${CI_GLOBAL_BIN}"
    export HOME="${CI_HOME}"
    export USER_BIN="${CI_USER_BIN}"
    export GLOBAL_BIN="${CI_GLOBAL_BIN}"
    # Isolate host sudoers.d probe so a live /etc/sudoers.d fragment
    # does not flip default submit add → update (TP-23 uses this dir).
    CI_SUDOERS_D="${CI_HOME}/sudoers.d"
    mkdir -p "${CI_SUDOERS_D}"
    export SUDOERS_D_DIR="${CI_SUDOERS_D}"
    # Local-only product: ensure no channel env is required
    unset SCRIPT_URL 2>/dev/null || true
    unset CHECKSUM 2>/dev/null || true
    # Peer grok probe searches GROK_HOME/bin; do not leak the host session.
    unset GROK_HOME 2>/dev/null || true
    unset GROK_BIN 2>/dev/null || true
    # Drop host grok (often /usr/local/bin) so session tests cannot call xAI.
    # Do not put Termux PREFIX/bin on PATH (that exposes proot/curl). Link
    # python3 and timeout into CI_USER_BIN for PTY / bounded probes.
    if [ -z "${CI_PATH_ORIG:-}" ]; then
        CI_PATH_ORIG="${PATH}"
    fi
    _py=$(command -v python3 2>/dev/null || true)
    if [ -n "${_py}" ] && [ -x "${_py}" ]; then
        ln -sf "${_py}" "${CI_USER_BIN}/python3"
    fi
    _to=$(command -v timeout 2>/dev/null || true)
    if [ -n "${_to}" ] && [ -x "${_to}" ]; then
        ln -sf "${_to}" "${CI_USER_BIN}/timeout"
    fi
    unset _py _to
    export PATH="${CI_USER_BIN}:${CI_GLOBAL_BIN}:/usr/bin:/bin"
    # Default isolated host is multi-user so Android uname / host Termux
    # env do not steal TP-CLI-07/13/17. Termux cases set TERMUX_VERSION.
    unset TERMUX_VERSION 2>/dev/null || true
    export GROK_CLI_HOST_OVERRIDE=multiuser
    unset BASHRC 2>/dev/null || true
    unset ZSHRC 2>/dev/null || true
    unset PROFILE 2>/dev/null || true
    unset FISH_CONFIG 2>/dev/null || true
    CI_BASHRC=
    CI_BASHRC_DIR=
}

# Redirect BASHRC to a file in a random temp folder (not ${HOME}/.bashrc).
ci_isolated_bashrc() {
    CI_BASHRC_DIR=$(mktemp -d "${TMPDIR:-/tmp}/gc-bashrc.XXXXXX")
    CI_BASHRC="${CI_BASHRC_DIR}/.bashrc"
    export BASHRC="${CI_BASHRC}"
}

ci_cleanup_bashrc() {
    if [ -n "${CI_BASHRC_DIR:-}" ] && [ -d "${CI_BASHRC_DIR}" ]; then
        rm -rf "${CI_BASHRC_DIR}"
    fi
    CI_BASHRC_DIR=
    CI_BASHRC=
    unset BASHRC 2>/dev/null || true
}

ci_bashrc_path_line() {
    printf 'export PATH="%s:$PATH"' "${CI_USER_BIN}"
}

# Write a fake peer grok that never hits the network.
# Usage: ci_write_fake_grok PATH [exit_code_for_-p]
ci_write_fake_grok() {
    _fp="${1:-}"
    _fec="${2:-0}"
    if [ -z "${_fp}" ]; then
        return 1
    fi
    mkdir -p "$(dirname "${_fp}")"
    cat > "${_fp}" <<FAKE
#!/bin/sh
# Core-test fake grok — never hits the network.
case "\${1:-}" in
  --version)
    echo "grok 0.0.0-test"
    exit 0
    ;;
  -p)
    echo "hello-from-fake-grok"
    exit ${_fec}
    ;;
  *)
    exit ${_fec}
    ;;
esac
FAKE
    chmod +x "${_fp}"
}

ci_fake_grok_ok() {
    mkdir -p "${CI_USER_BIN}"
    ci_write_fake_grok "${CI_USER_BIN}/grok" 0
    export GROK_BIN="${CI_USER_BIN}/grok"
}

ci_fake_grok_fail() {
    mkdir -p "${CI_USER_BIN}"
    ci_write_fake_grok "${CI_USER_BIN}/grok" 1
    export GROK_BIN="${CI_USER_BIN}/grok"
}

# Fake grok that ignores SIGTERM and never exits (Termux proot hang class).
ci_write_fake_grok_hang() {
    _fp="${1:-}"
    if [ -z "${_fp}" ]; then
        return 1
    fi
    mkdir -p "$(dirname "${_fp}")"
    cat > "${_fp}" <<'FAKE'
#!/bin/sh
# Core-test hang grok — ignores SIGTERM so timeout without -k would freeze.
if [ -n "${GROK_PROBE_LOG:-}" ]; then
    printf '%s\n' "-p ${1-}" >> "${GROK_PROBE_LOG}"
fi
trap '' TERM INT HUP
while :; do
    sleep 1
done
FAKE
    chmod +x "${_fp}"
}

ci_fake_grok_hang() {
    mkdir -p "${CI_USER_BIN}"
    ci_write_fake_grok_hang "${CI_USER_BIN}/grok"
    export GROK_BIN="${CI_USER_BIN}/grok"
}

# Match product gc_session_uses_local_auth (proot on PATH or Termux).
ci_session_uses_local_auth() {
    if [ -n "${TERMUX_VERSION:-}" ]; then
        return 0
    fi
    case "${GROK_CLI_HOST_OVERRIDE:-}" in
        multiuser|gitbash|windows-cmd) return 1 ;;
        termux) return 0 ;;
    esac
    if command -v proot >/dev/null 2>&1; then
        return 0
    fi
    if [ -n "${PREFIX:-}" ]; then
        return 0
    fi
    case "$(uname -s 2>/dev/null)" in
        *Android*) return 0 ;;
    esac
    return 1
}

ci_cleanup_env() {
    ci_cleanup_bashrc
    if [ -n "${CI_HOME:-}" ] && [ -d "${CI_HOME}" ]; then
        rm -rf "${CI_HOME}"
        CI_HOME=
        CI_USER_BIN=
        CI_GLOBAL_BIN=
    fi
    unset GLOBAL_BIN 2>/dev/null || true
    unset GROK_BIN 2>/dev/null || true
    unset GROK_CLI_HOST_OVERRIDE 2>/dev/null || true
    if [ -n "${CI_PATH_ORIG:-}" ]; then
        export PATH="${CI_PATH_ORIG}"
    fi
}

# Run SCRIPT under a PTY. Sends PTY_IN (default "9") plus a trailing newline.
# Kills the child after PTY_TIMEOUT seconds (default 6) so a missed payload
# cannot hang the suite. Prints child output on stdout.
ci_pty_capture() {
    python3 - "$@" <<'PY'
import os, pty, select, signal, sys, time
script = sys.argv[1]
cmd = sys.argv[2:]
payload = (os.environ.get("PTY_IN", "9") + "\n").encode()
timeout = float(os.environ.get("PTY_TIMEOUT", "6"))
pid, fd = pty.fork()
if pid == 0:
    os.execv("/bin/sh", ["sh", script] + cmd)
time.sleep(0.2)
try:
    os.write(fd, payload)
except OSError:
    pass
out = bytearray()
end = time.time() + timeout
exited = False
while time.time() < end:
    r, _, _ = select.select([fd], [], [], 0.2)
    if fd in r:
        try:
            chunk = os.read(fd, 4096)
        except OSError:
            break
        if not chunk:
            break
        out += chunk
    wpid, _st = os.waitpid(pid, os.WNOHANG)
    if wpid:
        exited = True
        break
if not exited:
    try:
        os.kill(pid, signal.SIGTERM)
    except OSError:
        pass
try:
    os.waitpid(pid, 0)
except ChildProcessError:
    pass
sys.stdout.buffer.write(out.replace(b"\r\n", b"\n").replace(b"\r", b"\n"))
PY
}

ci_run() {
    sh "${SCRIPT}" "$@"
}

ci_capture() {
    _out="$1"; _err="$2"; shift 2
    if [ "$1" = "--" ]; then shift; fi
    "$@" >"$_out" 2>"$_err"
    CI_EXIT=$?
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        t_fail "required command missing: $1"
        return 1
    fi
    return 0
}
