# =============================================================================
# tests/test_cli.sh — CLI surface (local-only; no network)
# =============================================================================
# Primary REQs: requirement-shell-cli-interface, requirement-shell-cli-zero-arguments,
# requirement-shell-cli-default-interaction, requirement-shell-output-requirements,
# requirement-shell-cli-storage
# TP family: TP-CLI-*
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_cli() {
    t_header "CLI surface (TP-CLI)"

    require_cmd sh
    require_cmd grep
    # TP-CLI-01 syntax
    sh -n "${SCRIPT}"
    assert_eq "TP-CLI-01 sh -n ship unit" 0 "$?"

    # TP-CLI-02 version human
    _out=$(sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-02 version exit 0" 0 "$_ec"
    assert_contains "TP-CLI-02 version mentions app" "$_out" "${APP_NAME}"
    assert_contains "TP-CLI-02 version mentions VERSION" "$_out" "${PRODUCT_VERSION}"

    # TP-CLI-03 version json
    _out=$(sh "${SCRIPT}" --json version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-03 version --json exit 0" 0 "$_ec"
    assert_contains "TP-CLI-03 type version" "$_out" '"type":"version"'
    assert_contains "TP-CLI-03 app field" "$_out" "\"app\":\"${APP_NAME}\""
    assert_contains "TP-CLI-03 version field" "$_out" "\"version\":\"${PRODUCT_VERSION}\""

    # TP-CLI-04 help lists local lifecycle + domain; not online verbs
    _out=$(sh "${SCRIPT}" help 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-04 help exit 0" 0 "$_ec"
    assert_contains "TP-CLI-04 help install" "$_out" "install"
    assert_contains "TP-CLI-04 help setup" "$_out" "setup"
    assert_contains "TP-CLI-04 help menu" "$_out" "menu"
    assert_contains "TP-CLI-04 help uninstall" "$_out" "uninstall"
    assert_contains "TP-CLI-04 help where-is-me" "$_out" "where-is-me"
    assert_contains "TP-CLI-04 help backup" "$_out" "backup"
    assert_contains "TP-CLI-04 help check-session" "$_out" "check-session"
    assert_contains "TP-CLI-04 help sync-auth" "$_out" "sync-auth"
    assert_not_contains "TP-CLI-04 help no restore" "$_out" "restore <"
    assert_contains "TP-CLI-04 help print-sudoers" "$_out" "print-sudoers"
    assert_contains "TP-CLI-04 help install-script" "$_out" "print-sudoers-install-script"
    assert_contains "TP-CLI-04 help remove-project-sudoers" "$_out" "remove-project-sudoers"
    assert_contains "TP-CLI-04 help submit-sudoer-request" "$_out" "submit-sudoer-request"
    assert_contains "TP-CLI-04 help generate-sudoer-request" "$_out" "generate-sudoer-request"
    assert_contains "TP-CLI-04 help public inbound" "$_out" "/var/sudoer-cli/sudoer-request"
    assert_contains "TP-CLI-04 help --update" "$_out" "--update"
    assert_contains "TP-CLI-04 help --add" "$_out" "--add"
    assert_contains "TP-CLI-04 help SUDOER_PUBLIC_ROOT" "$_out" "SUDOER_PUBLIC_ROOT"
    assert_contains "TP-CLI-04 help GROK_CLI_ROOT" "$_out" "GROK_CLI_ROOT"
    assert_contains "TP-CLI-04 help --json" "$_out" "--json"
    assert_not_contains "TP-CLI-04 no self-update" "$_out" "self-update"
    assert_not_contains "TP-CLI-04 no self-uninstall" "$_out" "self-uninstall"
    assert_not_contains "TP-CLI-04 no version-check" "$_out" "version-check"
    assert_not_contains "TP-CLI-04 no SCRIPT_URL channel" "$_out" "SCRIPT_URL"
    assert_not_contains "TP-CLI-04 no CHECKSUM" "$_out" "CHECKSUM"

    # TP-CLI-05 help json
    _out=$(sh "${SCRIPT}" --json help 2>/dev/null)
    assert_eq "TP-CLI-05 help --json exit 0" 0 "$?"
    assert_contains "TP-CLI-05 help json success" "$_out" '"type":"success"'

    # TP-CLI-06 about json domain + cache folders, no channel
    _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-06 about --json exit 0" 0 "$_ec"
    assert_contains "TP-CLI-06 type about" "$_out" '"type":"about"'
    assert_contains "TP-CLI-06 cache_preferred" "$_out" '"cache_preferred"'
    assert_contains "TP-CLI-06 cache_fallback" "$_out" '"cache_fallback"'
    assert_contains "TP-CLI-06 persistence_storage" "$_out" '"persistence_storage"'
    assert_contains "TP-CLI-06 effective_storage" "$_out" '"effective_storage"'
    _hum=$(sh "${SCRIPT}" about 2>/dev/null)
    assert_contains "TP-CLI-06 human Cache folder preferred" "$_hum" "Cache folder (preferred)"
    assert_contains "TP-CLI-06 human Cache folder fallback" "$_hum" "Cache folder (fallback)"
    assert_contains "TP-CLI-06 human Persistence storage" "$_hum" "Persistence storage"
    assert_not_contains "TP-CLI-06 no Storage (effective) label" "$_hum" "Storage (effective)"
    assert_not_contains "TP-CLI-06 no Storage (fallback) label" "$_hum" "Storage (fallback)"
    assert_contains "TP-CLI-06 grok_cli_root" "$_out" '"grok_cli_root"'
    assert_contains "TP-CLI-06 deposit_dir" "$_out" '"deposit_dir"'
    assert_contains "TP-CLI-06 session" "$_out" '"session"'
    assert_contains "TP-CLI-06 sudoer_cli" "$_out" '"sudoer_cli"'
    assert_contains "TP-CLI-06 sudoer_adm" "$_out" '"sudoer_adm"'
    assert_contains "TP-CLI-06 sudoer_inbound" "$_out" '"sudoer_inbound"'
    assert_contains "TP-CLI-06 host_sudoers_present" "$_out" '"host_sudoers_present"'
    assert_not_contains "TP-CLI-06 no CHECKSUM" "$_out" "CHECKSUM"
    assert_not_contains "TP-CLI-06 no SCRIPT_URL" "$_out" "SCRIPT_URL"

    # TP-CLI-07 empty argv = Type N (not install). Off-TTY: help. TTY: numbered menu.
    _out=$(sh "${SCRIPT}" 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-07 empty argv off-TTY exit 0" 0 "$_ec"
    assert_contains "TP-CLI-07 empty argv off-TTY is help" "$_out" "Usage:"
    assert_contains "TP-CLI-07 empty argv off-TTY mentions help" "$_out" "help"
    assert_not_contains "TP-CLI-07 empty argv off-TTY not numbered list" "$_out" "9. Exit"

    _out=$(sh "${SCRIPT}" --json 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-07 --json no command exit 0" 0 "$_ec"
    assert_contains "TP-CLI-07 --json no command is JSON help" "$_out" '"type":"success"'
    assert_not_contains "TP-CLI-07 --json no command not numbered list" "$_out" "9. Exit"

    if command -v python3 >/dev/null 2>&1; then
        _out=$(PTY_IN="9" python3 - "${SCRIPT}" <<'PY'
import os, pty, select, sys, time
script = sys.argv[1]
payload = (os.environ.get("PTY_IN", "9") + "\n").encode()
pid, fd = pty.fork()
if pid == 0:
    os.execv("/bin/sh", ["sh", script])
time.sleep(0.2)
try:
    os.write(fd, payload)
except OSError:
    pass
out = bytearray()
end = time.time() + 4
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
        break
try:
    os.waitpid(pid, 0)
except ChildProcessError:
    pass
sys.stdout.buffer.write(out.replace(b"\r\n", b"\n").replace(b"\r", b"\n"))
PY
)
        assert_contains "TP-CLI-07 TTY empty argv is numbered list" "$_out" "9. Exit"
        assert_contains "TP-CLI-07 TTY empty argv check-session first" "$_out" "1. check-session:"
        assert_not_contains "TP-CLI-07 TTY empty argv not help dump" "$_out" "Usage:"
    else
        t_skip "TP-CLI-07 TTY empty argv (no python3 for PTY)"
    fi

    # TP-CLI-08 unknown command fail-closed
    _err=$(sh "${SCRIPT}" no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CLI-08 unknown exit 1" 1 "$_ec"
    assert_contains "TP-CLI-08 unknown error text" "$_err" "Unknown command"

    _err=$(sh "${SCRIPT}" --json no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CLI-08 unknown --json exit 1" 1 "$_ec"
    assert_contains "TP-CLI-08 unknown --json type" "$_err" '"type":"out_error"'

    # TP-CLI-09 quiet suppresses version info
    _out=$(sh "${SCRIPT}" --quiet version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-09 quiet version exit 0" 0 "$_ec"
    _trim=$(printf '%s' "$_out" | tr -d ' \t\n\r')
    if [ -z "$_trim" ]; then
        t_pass "TP-CLI-09 quiet suppresses human version"
    else
        t_fail "TP-CLI-09 quiet expected empty stdout, got '$(_trunc "$_out")'"
    fi

    # TP-CLI-10 online verbs rejected
    _err=$(sh "${SCRIPT}" self-update 2>&1 >/dev/null)
    assert_eq "TP-CLI-10 self-update exit 1" 1 "$?"
    assert_contains "TP-CLI-10 self-update unknown" "$_err" "Unknown command"

    _err=$(sh "${SCRIPT}" version-check 2>&1 >/dev/null)
    assert_eq "TP-CLI-10 version-check exit 1" 1 "$?"

    # TP-CLI-11 set -u HOME unset still works for version
    _out=$(env -u HOME sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-11 env -u HOME version exit 0" 0 "$_ec"
    assert_contains "TP-CLI-11 env -u HOME version text" "$_out" "${PRODUCT_VERSION}"

    # TP-CLI-12 cache isolation under temp HOME
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" --json about 2>/dev/null)
    assert_contains "TP-CLI-12 isolated about has app in cache" "$_out" "${APP_NAME}"
    _pref=$(printf '%s' "$_out" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 cache_preferred path" "/dev/shm/cache/cache-${APP_NAME}" "$_pref"
    _fb=$(printf '%s' "$_out" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
    case "${_fb}" in
        */cache-${APP_NAME}) t_pass "TP-CLI-12 cache_fallback ends cache-${APP_NAME}" ;;
        *) t_fail "TP-CLI-12 cache_fallback unexpected: '${_fb:-empty}'" ;;
    esac
    _eff=$(printf '%s' "$_out" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
    if [ -n "$_eff" ] && [ -d "$_eff" ]; then
        t_pass "TP-CLI-12 effective cache directory exists"
    else
        t_fail "TP-CLI-12 effective cache missing: '${_eff:-empty}'"
    fi
    case "${_eff}" in
        */${APP_NAME}-*) t_fail "TP-CLI-12 effective cache must not be APP-USERNAME ram-drive shape: '${_eff}'" ;;
        *) t_pass "TP-CLI-12 effective cache is not APP-USERNAME ram-drive shape" ;;
    esac
    _persist=$(printf '%s' "$_out" | sed -n 's/.*"persistence_storage":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 persistence_storage path" "${CI_HOME}/.local/${APP_NAME}" "$_persist"
    if [ -n "$_persist" ] && [ -d "$_persist" ]; then
        t_pass "TP-CLI-12 persistence storage directory exists"
    else
        t_fail "TP-CLI-12 persistence storage missing: '${_persist:-empty}'"
    fi
    case "${_persist}" in
        */.local/bin|*/.local/bin/) t_fail "TP-CLI-12 persistence must not be USER_BIN: '${_persist}'" ;;
        *) t_pass "TP-CLI-12 persistence is not the install bin directory" ;;
    esac
    ci_cleanup_env

    # TP-CLI-13 menu/main: off-TTY help; TTY numbered list; empty argv off-TTY still help
    _out=$(sh "${SCRIPT}" menu 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-13 menu off-TTY exit 0" 0 "$_ec"
    assert_contains "TP-CLI-13 menu off-TTY is help" "$_out" "Usage:"
    assert_not_contains "TP-CLI-13 menu off-TTY not the numbered list" "$_out" "9. Exit"

    _out=$(sh "${SCRIPT}" main 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-13 main off-TTY exit 0" 0 "$_ec"
    assert_contains "TP-CLI-13 main off-TTY is help" "$_out" "Usage:"

    _out=$(sh "${SCRIPT}" --json menu 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-13 menu --json off-TTY exit 0" 0 "$_ec"
    assert_contains "TP-CLI-13 menu --json off-TTY JSON help" "$_out" '"type":"success"'
    assert_not_contains "TP-CLI-13 menu --json off-TTY not numbered list" "$_out" "9. Exit"

    _out=$(sh "${SCRIPT}" 2>/dev/null)
    assert_not_contains "TP-CLI-13 empty argv off-TTY not numbered list" "$_out" "9. Exit"
    assert_contains "TP-CLI-13 empty argv off-TTY still help" "$_out" "Usage:"

    _out=$(sh "${SCRIPT}" --quiet menu 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-13 menu --quiet off-TTY exit 0" 0 "$_ec"
    assert_contains "TP-CLI-13 menu --quiet off-TTY still help" "$_out" "Usage:"

    if command -v python3 >/dev/null 2>&1; then
        _out=$(PTY_IN="99" python3 - "${SCRIPT}" menu <<'PY'
import os, pty, select, sys, time
script = sys.argv[1]
cmd = sys.argv[2:]
payload = (os.environ.get("PTY_IN", "99") + "\n").encode()
pid, fd = pty.fork()
if pid == 0:
    os.execv("/bin/sh", ["sh", script] + cmd)
time.sleep(0.2)
try:
    os.write(fd, payload)
except OSError:
    pass
out = bytearray()
end = time.time() + 4
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
        break
try:
    os.waitpid(pid, 0)
except ChildProcessError:
    pass
sys.stdout.buffer.write(out.replace(b"\r\n", b"\n").replace(b"\r", b"\n"))
PY
)
        assert_contains "TP-CLI-13 TTY menu check-session first" "$_out" "1. check-session:"
        assert_contains "TP-CLI-13 TTY menu backup second" "$_out" "2. backup:"
        assert_contains "TP-CLI-13 TTY menu family sudoers" "$_out" "4. sudoers:"
        assert_contains "TP-CLI-13 TTY menu Exit 9" "$_out" "9. Exit"
        assert_not_contains "TP-CLI-13 TTY menu no install row" "$_out" "1. Install"
        assert_not_contains "TP-CLI-13 TTY menu no setup row" "$_out" "setup:"
        assert_not_contains "TP-CLI-13 TTY menu no help verb row" "$_out" "help: Show this help"
        assert_not_contains "TP-CLI-13 TTY main hides generate row" "$_out" "1. generate-sudoer-request:"
        _out=$(PTY_IN="99" python3 - "${SCRIPT}" --json menu <<'PY'
import os, pty, select, sys, time
script = sys.argv[1]
cmd = sys.argv[2:]
payload = (os.environ.get("PTY_IN", "99") + "\n").encode()
pid, fd = pty.fork()
if pid == 0:
    os.execv("/bin/sh", ["sh", script] + cmd)
time.sleep(0.2)
try:
    os.write(fd, payload)
except OSError:
    pass
out = bytearray()
end = time.time() + 4
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
        break
try:
    os.waitpid(pid, 0)
except ChildProcessError:
    pass
sys.stdout.buffer.write(out.replace(b"\r\n", b"\n").replace(b"\r", b"\n"))
PY
)
        assert_contains "TP-CLI-13 TTY menu --json still numbered list" "$_out" "9. Exit"
        assert_not_contains "TP-CLI-13 TTY menu --json ignores JSON help" "$_out" '"type":"success"'
        _out=$(PTY_IN="12
9" python3 - "${SCRIPT}" menu <<'PY'
import os, pty, select, sys, time
script = sys.argv[1]
cmd = sys.argv[2:]
payload = (os.environ.get("PTY_IN", "99") + "\n").encode()
pid, fd = pty.fork()
if pid == 0:
    os.execv("/bin/sh", ["sh", script] + cmd)
time.sleep(0.2)
try:
    os.write(fd, payload)
except OSError:
    pass
out = bytearray()
end = time.time() + 4
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
        break
try:
    os.waitpid(pid, 0)
except ChildProcessError:
    pass
sys.stdout.buffer.write(out.replace(b"\r\n", b"\n").replace(b"\r", b"\n"))
PY
)
        assert_contains "TP-CLI-13 TTY pick 12 not a menu choice" "$_out" "Not a menu choice"
        _out=$(PTY_IN="4
8
9" python3 - "${SCRIPT}" menu <<'PY'
import os, pty, select, sys, time
script = sys.argv[1]
cmd = sys.argv[2:]
payload = (os.environ.get("PTY_IN", "99") + "\n").encode()
pid, fd = pty.fork()
if pid == 0:
    os.execv("/bin/sh", ["sh", script] + cmd)
time.sleep(0.2)
try:
    os.write(fd, payload)
except OSError:
    pass
out = bytearray()
end = time.time() + 6
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
        break
try:
    os.waitpid(pid, 0)
except ChildProcessError:
    pass
sys.stdout.buffer.write(out.replace(b"\r\n", b"\n").replace(b"\r", b"\n"))
PY
)
        assert_contains "TP-CLI-13 TTY submenu generate row" "$_out" "1. generate-sudoer-request:"
        assert_contains "TP-CLI-13 TTY submenu Back 8" "$_out" "8. Back"
        assert_contains "TP-CLI-13 TTY submenu Exit 9" "$_out" "9. Exit"
        _err=$(sh "${SCRIPT}" sudoers 2>&1 >/dev/null)
        assert_eq "TP-CLI-13 sudoers not a live command" 1 "$?"
        assert_contains "TP-CLI-13 sudoers unknown" "$_err" "Unknown command"
    else
        t_skip "TP-CLI-13 TTY menu (no python3 for PTY)"
        t_skip "TP-CLI-13 TTY menu --json (no python3 for PTY)"
        t_skip "TP-CLI-13 TTY pick 12 (no python3 for PTY)"
        t_skip "TP-CLI-13 TTY sudoers submenu (no python3 for PTY)"
    fi
}
