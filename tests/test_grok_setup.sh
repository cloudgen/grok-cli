# =============================================================================
# tests/test_grok_setup.sh — TP-VCLI-* peer grok channel + artifact (no public network)
# =============================================================================
# ALIGNMENT: requirement-grok-setup.md
# =============================================================================

# POSIX tools only — excludes host grok (~/.grok/bin) and optionally curl.
ci_toolbin() {
    _tb="${CI_HOME}/toolbin"
    mkdir -p "${_tb}"
    for _t in sh bash mktemp rm id chmod mkdir cat grep sed awk tr cut head ls mv cp ln uname dirname basename od dd; do
        _c=$(command -v "${_t}" 2>/dev/null || true)
        if [ -n "${_c}" ] && [ ! -e "${_tb}/${_t}" ]; then
            ln -s "${_c}" "${_tb}/${_t}" 2>/dev/null || true
        fi
    done
    printf '%s' "${_tb}"
}

ci_write_fake_curl() {
    _dir="$1"
    mkdir -p "${_dir}"
    cat > "${_dir}/curl" <<'EOS'
#!/bin/sh
out=""
url=""
writeout=""
while [ $# -gt 0 ]; do
    case "$1" in
        -o|--output)
            out="$2"
            shift 2
            ;;
        -w|--write-out)
            writeout="$2"
            shift 2
            ;;
        -fsSL|-f|-s|-S|-L|-fsS|-fs|-fL|-sS)
            shift
            ;;
        --)
            shift
            ;;
        -*)
            shift
            ;;
        *)
            url="$1"
            shift
            ;;
    esac
done
emit_http() {
    if [ -n "${writeout}" ]; then
        printf '%s' "$1"
    fi
}
if [ -n "${CURL_LOG:-}" ]; then
    printf '%s\n' "${url}" >> "${CURL_LOG}"
fi
if [ "${CURL_FAIL:-0}" = "1" ]; then
    emit_http "000"
    exit 22
fi
if [ -n "${CURL_HTTP:-}" ]; then
    case "${url}" in
        *grok-*)
            emit_http "${CURL_HTTP}"
            exit 22
            ;;
    esac
fi
# Compressed variants: not provided by this stub (setup falls through to raw).
case "${url}" in
    *.zst|*.gz)
        emit_http "404"
        exit 22
        ;;
esac
if [ "${CURL_EMPTY_BIN:-0}" = "1" ]; then
    case "${url}" in
        *grok-*)
            if [ -n "${out}" ]; then
                : > "${out}"
            fi
            emit_http "200"
            exit 0
            ;;
    esac
fi
body=""
case "${url}" in
    *install.sh*)
        body='#!/bin/sh
exit 0
'
        ;;
    *grok-*)
        if [ "${CURL_ANDROID_SMOKE:-}" = "optout" ]; then
            body='#!/bin/sh
if [ "${TERMUX_EXEC_OPTOUT:-}" = "1" ]; then
printf "%s\n" "$0" > "$(dirname "$0")/.smoke-path"
echo grok 0.0.0-test
exit 0
fi
echo "error: grok has unexpected e_type: 2" >&2
exit 1
'
        elif [ "${CURL_ANDROID_SMOKE:-}" = "proot" ]; then
            body='#!/bin/sh
if [ -n "${LD_PRELOAD:-}" ]; then
echo "error: grok has unexpected e_type: 2" >&2
exit 1
fi
if [ "${GROK_UNDER_PROOT:-}" = "1" ]; then
printf "%s\n" "$0" > "$(dirname "$0")/.smoke-path"
echo grok 0.0.0-test
exit 0
fi
echo "error: grok has unexpected e_type: 2" >&2
exit 1
'
        elif [ "${CURL_ANDROID_SMOKE:-}" = "etype" ]; then
            body='#!/bin/sh
echo "error: grok has unexpected e_type: 2" >&2
exit 1
'
        elif [ "${CURL_SMOKE_FAIL:-0}" = "1" ]; then
            body='#!/bin/sh
echo boom-from-smoke >&2
exit 7
'
        else
            body='#!/bin/sh
printf "%s\n" "$0" > "$(dirname "$0")/.smoke-path"
echo grok 0.0.0-test
exit 0
'
        fi
        ;;
    */stable|*/alpha|*/enterprise|*/stable/*|*/alpha/*|*/enterprise/*)
        body='0.0.0-test'
        ;;
    *)
        exit 22
        ;;
esac
if [ -n "${out}" ]; then
    if [ "${CURL_ELF_MACHINE:-}" = "62" ]; then
        case "${url}" in
            *grok-*)
                printf '\177ELF\002\001\001\000\000\000\000\000\000\000\000\000\002\000\076\000' > "${out}"
                emit_http "200"
                exit 0
                ;;
        esac
    fi
    if [ "${CURL_ELF_MACHINE:-}" = "183" ]; then
        case "${url}" in
            *grok-*)
                printf '\177ELF\002\001\001\000\000\000\000\000\000\000\000\000\002\000\267\000' > "${out}"
                emit_http "200"
                exit 0
                ;;
        esac
    fi
    printf '%s\n' "${body}" > "${out}"
else
    printf '%s\n' "${body}"
fi
emit_http "200"
exit 0
EOS
    chmod +x "${_dir}/curl"
}

# Fake uname that still reports this host's Linux/arch, plus Android so
# gc_setup_host_is_android matches. Overwrites a toolbin symlink — do not
# cat onto the symlink (that would rewrite the real uname).
ci_write_android_uname() {
    _dir="$1"
    _host_s=$(uname -s 2>/dev/null || echo Linux)
    _host_m=$(uname -m 2>/dev/null || echo x86_64)
    rm -f "${_dir}/uname"
    cat > "${_dir}/uname" <<EOF
#!/bin/sh
case "\${1:-}" in
    -s) printf '%s\\n' "${_host_s}" ;;
    -m) printf '%s\\n' "${_host_m}" ;;
    -o) printf '%s\\n' "Android" ;;
    -a) printf '%s\\n' "${_host_s} localhost 0.0 ${_host_m} Android" ;;
    *) printf '%s\\n' "${_host_s}" ;;
esac
EOF
    chmod +x "${_dir}/uname"
}

# Fake Termux pkg: install -y proot writes a proot stub next to this pkg
# (same PATH dir). Does not talk to packages.termux.org.
ci_write_fake_pkg() {
    _dir="$1"
    rm -f "${_dir}/pkg"
    cat > "${_dir}/pkg" <<'EOS'
#!/bin/sh
if [ -n "${PKG_LOG:-}" ]; then
    printf '%s\n' "$*" >> "${PKG_LOG}"
fi
if [ "${PKG_FAIL:-0}" = "1" ]; then
    exit 1
fi
_has_install=0
_has_proot=0
_has_y=0
for _a in "$@"; do
    case "${_a}" in
        install) _has_install=1 ;;
        proot) _has_proot=1 ;;
        -y|--yes) _has_y=1 ;;
    esac
done
if [ "${_has_install}" -eq 1 ] && [ "${_has_proot}" -eq 1 ] && [ "${_has_y}" -eq 1 ]; then
    _bindir=$(dirname "$0")
    cat > "${_bindir}/proot" <<'EOP'
#!/bin/sh
GROK_UNDER_PROOT=1
export GROK_UNDER_PROOT
exec "$@"
EOP
    chmod +x "${_bindir}/proot"
    exit 0
fi
exit 1
EOS
    chmod +x "${_dir}/pkg"
}

run_test_grok_setup() {
    t_header "TP-VCLI grok-cli setup (peer grok channel + artifact)"

    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            sh "${SCRIPT}" setup 2>&1 >/dev/null
    ) || true
    assert_not_contains "TP-VCLI-01 setup is routed" "${_err}" "Unknown command"
    ci_cleanup_env

    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" help 2>/dev/null)
    assert_contains "TP-VCLI-02 help lists setup" "${_out}" "setup"
    assert_contains "TP-VCLI-02 help names x.ai" "${_out}" "x.ai"
    assert_contains "TP-VCLI-02 help lists self-update" "${_out}" "self-update"
    assert_contains "TP-VCLI-02 help names SCRIPT_URL" "${_out}" "SCRIPT_URL"
    assert_not_contains "TP-VCLI-02 help no install.sh" "${_out}" "install.sh"
    ci_cleanup_env

    # TP-VCLI-04 already-installed: stub grok on PATH, fake curl must not run
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    CURL_LOG="${CI_HOME}/curl.log"
    export CURL_LOG
    printf '%s\n' '#!/bin/sh' 'echo grok-stub' > "${CI_USER_BIN}/grok"
    chmod +x "${CI_USER_BIN}/grok"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_USER_BIN}:${CI_HOME}/fakecurl:${_tb}" \
            sh "${SCRIPT}" --json setup 2>/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-04 already-installed exit 0" 0 "${_ec}"
    assert_contains "TP-VCLI-04 JSON already_installed" "${_out}" "already_installed"
    if [ -f "${CURL_LOG}" ]; then
        t_fail "TP-VCLI-04 curl was invoked on skip"
    else
        t_pass "TP-VCLI-04 no curl on skip"
    fi
    ci_cleanup_env
    unset CURL_LOG

    # TP-VCLI-05 --force fetches even when grok present
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    CURL_LOG="${CI_HOME}/curl.log"
    export CURL_LOG
    printf '%s\n' '#!/bin/sh' 'echo grok-stub' > "${CI_USER_BIN}/grok"
    chmod +x "${CI_USER_BIN}/grok"
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_USER_BIN}:${CI_HOME}/fakecurl:${_tb}" \
            CURL_LOG="${CURL_LOG}" \
            sh "${SCRIPT}" --force setup 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-05 --force exit 0" 0 "${_ec}"
    if [ -f "${CURL_LOG}" ] && grep -q '/stable' "${CURL_LOG}" && grep -q 'grok-' "${CURL_LOG}"; then
        t_pass "TP-VCLI-05 curl hit channel pointer and artifact"
    else
        t_fail "TP-VCLI-05 curl log missing channel/artifact URL"
    fi
    if [ -f "${CURL_LOG}" ] && grep -q 'install.sh' "${CURL_LOG}"; then
        t_fail "TP-VCLI-05 curl must not fetch install.sh"
    else
        t_pass "TP-VCLI-05 curl did not fetch install.sh"
    fi
    ci_cleanup_env
    unset CURL_LOG

    # TP-VCLI-06 curl fail — operator-readable
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            CURL_FAIL=1 \
            sh "${SCRIPT}" setup 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-06 curl fail exit 1" 1 "${_ec}"
    assert_contains "TP-VCLI-06 error happened" "${_err}" "Download of the grok version pointer failed"
    assert_contains "TP-VCLI-06 names HTTP status" "${_err}" "HTTP 000"
    assert_contains "TP-VCLI-06 Next step" "${_err}" "Next:"
    assert_contains "TP-VCLI-06 did not install grok-cli" "${_err}" "did not install"
    ci_cleanup_env

    # TP-VCLI-07 missing curl
    ci_isolated_env
    _tb=$(ci_toolbin)
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_USER_BIN}:${_tb}" \
            sh "${SCRIPT}" setup 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-07 missing curl exit 1" 1 "${_ec}"
    assert_contains "TP-VCLI-07 mentions curl" "${_err}" "curl is not on PATH"
    assert_contains "TP-VCLI-07 Next" "${_err}" "Next:"
    ci_cleanup_env

    # TP-VCLI-08 fake fetch places grok under ~/.grok/bin, not grok-cli
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    CURL_LOG="${CI_HOME}/curl.log"
    export CURL_LOG
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            CURL_LOG="${CURL_LOG}" \
            sh "${SCRIPT}" --json setup 2>/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-08 setup exit 0" 0 "${_ec}"
    assert_file_exists "TP-VCLI-08 peer grok at vendor dir" "${CI_HOME}/.grok/bin/grok"
    assert_file_missing "TP-VCLI-08 did not write grok-cli as peer" "${CI_USER_BIN}/grok-cli"
    assert_file_missing "TP-VCLI-08 did not write grok-cli under vendor dir" "${CI_HOME}/.grok/bin/grok-cli"
    assert_contains "TP-VCLI-09 JSON installed" "${_out}" '"status":"installed"'
    assert_contains "TP-VCLI-09 JSON peer grok" "${_out}" '"peer":"grok"'
    if [ -f "${CURL_LOG}" ] && grep -q 'install.sh' "${CURL_LOG}"; then
        t_fail "TP-VCLI-13 curl must not fetch install.sh"
    else
        t_pass "TP-VCLI-13 curl did not fetch install.sh"
    fi
    if [ -f "${CURL_LOG}" ] && grep -q '/stable' "${CURL_LOG}" && grep -q 'grok-' "${CURL_LOG}"; then
        t_pass "TP-VCLI-14 curl hit channel pointer and grok- artifact"
    else
        t_fail "TP-VCLI-14 curl log missing channel/artifact"
    fi
    ci_cleanup_env
    unset CURL_LOG

    # TP-VCLI-11 vendor dir (~/.grok/bin), not on this session PATH: success, not ERROR
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    _vendor_bin="${CI_HOME}/.grok/bin"
    _all=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" \
            PATH="${CI_HOME}/fakecurl:${_tb}" \
            sh "${SCRIPT}" setup 2>&1
    )
    _ec=$?
    assert_eq "TP-VCLI-11 vendor-dir setup exit 0" 0 "${_ec}"
    assert_file_exists "TP-VCLI-11 peer grok at vendor dir" "${_vendor_bin}/grok"
    assert_contains "TP-VCLI-11 success names install path" "${_all}" "installed at ${_vendor_bin}/grok"
    assert_contains "TP-VCLI-11 explains stale PATH" "${_all}" "does not apply until a new session"
    assert_contains "TP-VCLI-11 next is new terminal" "${_all}" "open a new terminal"
    assert_not_contains "TP-VCLI-11 not an ERROR" "${_all}" "[ERROR]"
    assert_not_contains "TP-VCLI-11 does not send operator to USER_BIN" "${_all}" "add ${CI_USER_BIN} to PATH"
    _j=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" \
            PATH="${CI_HOME}/fakecurl:${_tb}" \
            sh "${SCRIPT}" --json setup 2>/dev/null
    )
    assert_contains "TP-VCLI-11 JSON already_installed after disk probe" "${_j}" '"status":"already_installed"'
    assert_contains "TP-VCLI-11 JSON on_path false" "${_j}" '"on_path":"false"'
    ci_cleanup_env

    # TP-VCLI-12 binary download empty/fail: fail closed, no PATH-hint lie
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" CURL_EMPTY_BIN=1 \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            sh "${SCRIPT}" setup 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-12 missing grok exit 1" 1 "${_ec}"
    assert_contains "TP-VCLI-12 error happened" "${_err}" "Download of the grok binary failed"
    assert_contains "TP-VCLI-12 names HTTP status" "${_err}" "HTTP 200 empty body"
    assert_contains "TP-VCLI-12 Next step" "${_err}" "Next:"
    assert_contains "TP-VCLI-12 Next is setup" "${_err}" "setup"
    assert_not_contains "TP-VCLI-12 does not say add USER_BIN" "${_err}" "add ${CI_USER_BIN} to PATH"
    ci_cleanup_env

    # TP-VCLI-15 smoke --version runs under GROK_HOME/downloads (not cache/tmp)
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            sh "${SCRIPT}" setup 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-15 setup exit 0" 0 "${_ec}"
    assert_file_exists "TP-VCLI-15 smoke-path recorded" "${CI_HOME}/.grok/downloads/.smoke-path"
    _sp=$(cat "${CI_HOME}/.grok/downloads/.smoke-path" 2>/dev/null || true)
    assert_contains "TP-VCLI-15 smoke path is downloads" "${_sp}" ".grok/downloads/"
    assert_not_contains "TP-VCLI-15 smoke path is not /tmp/cache" "${_sp}" "/tmp/cache/"
    assert_not_contains "TP-VCLI-15 smoke path is not /dev/shm" "${_sp}" "/dev/shm/"
    ci_cleanup_env

    # TP-VCLI-16 smoke --version fail: operator-readable Next + captured stderr
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" CURL_SMOKE_FAIL=1 \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            sh "${SCRIPT}" setup 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-16 smoke fail exit 1" 1 "${_ec}"
    assert_contains "TP-VCLI-16 error happened" "${_err}" "failed to run --version"
    assert_contains "TP-VCLI-16 captured stderr" "${_err}" "boom-from-smoke"
    assert_contains "TP-VCLI-16 captured exit" "${_err}" "exit 7"
    assert_contains "TP-VCLI-16 Next step" "${_err}" "Next:"
    assert_contains "TP-VCLI-16 Next is setup" "${_err}" "setup"
    assert_contains "TP-VCLI-16 did not install grok-cli" "${_err}" "did not install"
    assert_file_missing "TP-VCLI-16 did not leave tmp binary" "${CI_HOME}/.grok/bin/grok"
    ci_cleanup_env

    # TP-VCLI-17 existing grok that cannot run is not already_installed (Termux
    # x86_64 scp onto aarch64): fetch the matching artifact.
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    CURL_LOG="${CI_HOME}/curl.log"
    export CURL_LOG
    mkdir -p "${CI_HOME}/.grok/bin"
    printf '%s\n' '#!/bin/sh' \
        'echo "error: grok is for EM_X86_64 (62) instead of EM_AARCH64" >&2' \
        'exit 126' > "${CI_HOME}/.grok/bin/grok"
    chmod +x "${CI_HOME}/.grok/bin/grok"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            CURL_LOG="${CURL_LOG}" \
            sh "${SCRIPT}" --json setup 2>/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-17 unusable grok setup exit 0" 0 "${_ec}"
    assert_contains "TP-VCLI-17 JSON installed (not already_installed)" "${_out}" '"status":"installed"'
    assert_not_contains "TP-VCLI-17 not already_installed" "${_out}" "already_installed"
    if [ -f "${CURL_LOG}" ] && grep -q 'grok-' "${CURL_LOG}"; then
        t_pass "TP-VCLI-17 fetched artifact for unusable existing grok"
    else
        t_fail "TP-VCLI-17 did not fetch after unusable existing grok"
    fi
    _placed=$(cat "${CI_HOME}/.grok/downloads/.smoke-path" 2>/dev/null || true)
    assert_contains "TP-VCLI-17 replaced with a runnable download" "${_placed}" ".grok/downloads/"
    ci_cleanup_env
    unset CURL_LOG

    # TP-VCLI-18 downloaded ELF e_machine does not match this host → fail closed
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    _host_m=$(uname -m 2>/dev/null || true)
    _wrong_elf=""
    case "${_host_m}" in
        x86_64|amd64|AMD64) _wrong_elf="183" ;;
        aarch64|arm64|ARM64) _wrong_elf="62" ;;
    esac
    if [ -z "${_wrong_elf}" ]; then
        t_skip "TP-VCLI-18 host arch ${_host_m} has no opposite ELF fixture"
    else
        _err=$(
            HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" \
                PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
                CURL_ELF_MACHINE="${_wrong_elf}" \
                sh "${SCRIPT}" setup 2>&1 >/dev/null
        )
        _ec=$?
        assert_eq "TP-VCLI-18 wrong ELF exit 1" 1 "${_ec}"
        assert_contains "TP-VCLI-18 error names wrong architecture" "${_err}" "wrong architecture"
        assert_contains "TP-VCLI-18 Next is setup --force on this device" "${_err}" "setup --force"
        assert_contains "TP-VCLI-18 Next says do not scp" "${_err}" "do not scp"
        assert_contains "TP-VCLI-18 Next step" "${_err}" "Next:"
        assert_file_missing "TP-VCLI-18 did not place wrong-arch grok" "${CI_HOME}/.grok/bin/grok"
    fi
    ci_cleanup_env

    # TP-VCLI-19 Android e_type 2 (ET_EXEC) after retries: operator Next is
    # pkg install proot, not "check the download".
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    ci_write_android_uname "${_tb}"
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" CURL_ANDROID_SMOKE=etype \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            sh "${SCRIPT}" setup 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-19 Android e_type fail exit 1" 1 "${_ec}"
    assert_contains "TP-VCLI-19 error names static Linux executable" "${_err}" "static Linux executable"
    assert_contains "TP-VCLI-19 captured e_type" "${_err}" "e_type: 2"
    assert_contains "TP-VCLI-19 Next is pkg install proot" "${_err}" "pkg install proot"
    assert_contains "TP-VCLI-19 Next is setup --force" "${_err}" "setup --force"
    assert_contains "TP-VCLI-19 Next step" "${_err}" "Next:"
    assert_contains "TP-VCLI-19 did not install grok-cli" "${_err}" "did not install"
    assert_not_contains "TP-VCLI-19 not check-the-download Next" "${_err}" "check the download"
    assert_file_missing "TP-VCLI-19 did not place grok" "${CI_HOME}/.grok/bin/grok"
    _host_m=$(uname -m 2>/dev/null || true)
    _plat=""
    case "${_host_m}" in
        x86_64|amd64|AMD64) _plat="linux-x86_64" ;;
        aarch64|arm64|ARM64) _plat="linux-aarch64" ;;
    esac
    if [ -n "${_plat}" ]; then
        assert_file_exists "TP-VCLI-19 left grok-*.failed" "${CI_HOME}/.grok/downloads/grok-${_plat}.failed"
        assert_contains "TP-VCLI-19 error names left file" "${_err}" "grok-${_plat}.failed"
    else
        t_skip "TP-VCLI-19 failed-path host arch ${_host_m}"
    fi
    ci_cleanup_env

    # TP-VCLI-20 Android smoke succeeds only with TERMUX_EXEC_OPTOUT: place
    # a POSIX wrapper; vendor file under downloads is unchanged.
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    ci_write_android_uname "${_tb}"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" CURL_ANDROID_SMOKE=optout \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            sh "${SCRIPT}" --json setup 2>/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-20 optout wrapper setup exit 0" 0 "${_ec}"
    assert_contains "TP-VCLI-20 JSON installed" "${_out}" '"status":"installed"'
    assert_file_exists "TP-VCLI-20 placed grok wrapper" "${CI_HOME}/.grok/bin/grok"
    if [ -L "${CI_HOME}/.grok/bin/grok" ]; then
        t_fail "TP-VCLI-20 grok must be a wrapper script, not a symlink"
    else
        t_pass "TP-VCLI-20 grok is not a symlink"
    fi
    _wrap=$(cat "${CI_HOME}/.grok/bin/grok" 2>/dev/null || true)
    assert_contains "TP-VCLI-20 wrapper sets TERMUX_EXEC_OPTOUT" "${_wrap}" "TERMUX_EXEC_OPTOUT=1"
    assert_contains "TP-VCLI-20 wrapper unsets LD_PRELOAD" "${_wrap}" "unset LD_PRELOAD"
    _host_m=$(uname -m 2>/dev/null || true)
    _plat=""
    case "${_host_m}" in
        x86_64|amd64|AMD64) _plat="linux-x86_64" ;;
        aarch64|arm64|ARM64) _plat="linux-aarch64" ;;
    esac
    if [ -n "${_plat}" ]; then
        assert_file_exists "TP-VCLI-20 vendor file in downloads" "${CI_HOME}/.grok/downloads/grok-${_plat}"
        _vendor=$(head -n1 "${CI_HOME}/.grok/downloads/grok-${_plat}" 2>/dev/null || true)
        assert_contains "TP-VCLI-20 vendor file not byte-patched" "${_vendor}" "#!/bin/sh"
    else
        t_skip "TP-VCLI-20 vendor path host arch ${_host_m}"
    fi
    ci_cleanup_env

    # TP-VCLI-21 Android smoke succeeds only under proot: wrapper execs proot.
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    ci_write_android_uname "${_tb}"
    cat > "${_tb}/proot" <<'EOS'
#!/bin/sh
GROK_UNDER_PROOT=1
export GROK_UNDER_PROOT
exec "$@"
EOS
    chmod +x "${_tb}/proot"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" CURL_ANDROID_SMOKE=proot \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            LD_PRELOAD=injected \
            sh "${SCRIPT}" --json setup 2>/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-21 proot wrapper setup exit 0" 0 "${_ec}"
    assert_contains "TP-VCLI-21 JSON installed" "${_out}" '"status":"installed"'
    assert_file_exists "TP-VCLI-21 placed grok wrapper" "${CI_HOME}/.grok/bin/grok"
    _wrap=$(cat "${CI_HOME}/.grok/bin/grok" 2>/dev/null || true)
    assert_contains "TP-VCLI-21 wrapper execs proot" "${_wrap}" "command -v proot"
    assert_contains "TP-VCLI-21 wrapper unsets LD_PRELOAD" "${_wrap}" "unset LD_PRELOAD"
    assert_contains "TP-VCLI-21 wrapper sets TERMUX_EXEC_OPTOUT" "${_wrap}" "TERMUX_EXEC_OPTOUT=1"
    assert_contains "TP-VCLI-26 wrapper uses --kill-on-exit" "${_wrap}" "kill-on-exit"
    assert_not_contains "TP-VCLI-26 wrapper does not use -k for kill" "${_wrap}" " -k "
    assert_contains "TP-VCLI-27 wrapper injects --no-auto-update for -p" "${_wrap}" "--no-auto-update"
    assert_contains "TP-VCLI-27 wrapper SIGKILLs hung -p" "${_wrap}" "kill -KILL"
    ci_cleanup_env

    # TP-VCLI-22 Termux: opt-out fails, proot missing, pkg present →
    # pkg install -y proot, then proot wrapper.
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    ci_write_android_uname "${_tb}"
    ci_write_fake_pkg "${_tb}"
    PKG_LOG="${CI_HOME}/pkg.log"
    export PKG_LOG
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" CURL_ANDROID_SMOKE=proot \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            PKG_LOG="${PKG_LOG}" LD_PRELOAD=injected \
            sh "${SCRIPT}" --json setup 2>/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-22 pkg-install proot setup exit 0" 0 "${_ec}"
    assert_contains "TP-VCLI-22 JSON installed" "${_out}" '"status":"installed"'
    assert_file_exists "TP-VCLI-22 placed grok wrapper" "${CI_HOME}/.grok/bin/grok"
    _wrap=$(cat "${CI_HOME}/.grok/bin/grok" 2>/dev/null || true)
    assert_contains "TP-VCLI-22 wrapper execs proot" "${_wrap}" "command -v proot"
    if [ -f "${PKG_LOG}" ] && grep -q 'install' "${PKG_LOG}" && grep -q 'proot' "${PKG_LOG}"; then
        t_pass "TP-VCLI-22 pkg install proot was invoked"
    else
        t_fail "TP-VCLI-22 pkg install proot was not invoked"
    fi
    if [ -f "${PKG_LOG}" ] && grep -q -- '-y' "${PKG_LOG}"; then
        t_pass "TP-VCLI-22 pkg used -y (non-interactive)"
    else
        t_fail "TP-VCLI-22 pkg missing -y"
    fi
    ci_cleanup_env
    unset PKG_LOG

    # TP-VCLI-23 Termux pkg install fails: fail closed, Next pkg install proot,
    # no hang, grok not placed.
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    ci_write_android_uname "${_tb}"
    ci_write_fake_pkg "${_tb}"
    PKG_LOG="${CI_HOME}/pkg.log"
    export PKG_LOG
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" CURL_ANDROID_SMOKE=etype \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            PKG_LOG="${PKG_LOG}" PKG_FAIL=1 \
            sh "${SCRIPT}" setup 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-23 pkg-fail e_type exit 1" 1 "${_ec}"
    assert_contains "TP-VCLI-23 Next is pkg install proot" "${_err}" "pkg install proot"
    assert_contains "TP-VCLI-23 Next is setup --force" "${_err}" "setup --force"
    assert_not_contains "TP-VCLI-23 not check-the-download Next" "${_err}" "check the download"
    assert_file_missing "TP-VCLI-23 did not place grok" "${CI_HOME}/.grok/bin/grok"
    if [ -f "${PKG_LOG}" ] && grep -q 'proot' "${PKG_LOG}"; then
        t_pass "TP-VCLI-23 attempted pkg install proot"
    else
        t_fail "TP-VCLI-23 did not attempt pkg install"
    fi
    ci_cleanup_env
    unset PKG_LOG

    # TP-VCLI-24 artifact HTTP 403: error names HTTP status
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" CURL_HTTP=403 \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            sh "${SCRIPT}" setup 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-24 HTTP 403 exit 1" 1 "${_ec}"
    assert_contains "TP-VCLI-24 error happened" "${_err}" "Download of the grok binary failed"
    assert_contains "TP-VCLI-24 names HTTP 403" "${_err}" "HTTP 403"
    assert_contains "TP-VCLI-24 Next step" "${_err}" "Next:"
    assert_contains "TP-VCLI-24 Next is setup" "${_err}" "setup"
    assert_file_missing "TP-VCLI-24 did not place grok" "${CI_HOME}/.grok/bin/grok"
    ci_cleanup_env

    # TP-VCLI-25 Android + no nameserver: write GROK_HOME/resolv.conf and
    # rewrite wrapper as proot -b bind (musl DNS).
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    ci_write_android_uname "${_tb}"
    cat > "${_tb}/proot" <<'EOS'
#!/bin/sh
GROK_UNDER_PROOT=1
export GROK_UNDER_PROOT
exec "$@"
EOS
    chmod +x "${_tb}/proot"
    : > "${CI_HOME}/empty-resolv"
    _all=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" CURL_ANDROID_SMOKE=optout \
            PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            GROK_SETUP_RESOLV_FILE="${CI_HOME}/empty-resolv" \
            sh "${SCRIPT}" setup 2>&1
    )
    _ec=$?
    assert_eq "TP-VCLI-25 DNS-bind setup exit 0" 0 "${_ec}"
    assert_file_exists "TP-VCLI-25 wrote grok resolv.conf" "${CI_HOME}/.grok/resolv.conf"
    _ns=$(cat "${CI_HOME}/.grok/resolv.conf" 2>/dev/null || true)
    assert_contains "TP-VCLI-25 resolv has nameserver" "${_ns}" "nameserver"
    _wrap=$(cat "${CI_HOME}/.grok/bin/grok" 2>/dev/null || true)
    assert_contains "TP-VCLI-25 wrapper uses proot" "${_wrap}" "command -v proot"
    assert_contains "TP-VCLI-25 wrapper binds resolv" "${_wrap}" "-b"
    assert_contains "TP-VCLI-25 bind target /etc/resolv.conf" "${_wrap}" "/etc/resolv.conf"
    assert_contains "TP-VCLI-25 INFO names bind" "${_all}" "Bound"
    ci_cleanup_env

    # TP-VCLI-28 already-installed Android proot wrapper without kill-on-exit
    # is rewritten (no curl). Operator does not need setup --force.
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    ci_write_android_uname "${_tb}"
    cat > "${_tb}/proot" <<'EOS'
#!/bin/sh
GROK_UNDER_PROOT=1
export GROK_UNDER_PROOT
exec "$@"
EOS
    chmod +x "${_tb}/proot"
    _host_m=$(uname -m 2>/dev/null || true)
    _plat=""
    case "${_host_m}" in
        x86_64|amd64|AMD64) _plat="linux-x86_64" ;;
        aarch64|arm64|ARM64) _plat="linux-aarch64" ;;
    esac
    if [ -z "${_plat}" ]; then
        t_skip "TP-VCLI-28 host arch ${_host_m}"
        ci_cleanup_env
        return 0
    fi
    mkdir -p "${CI_HOME}/.grok/downloads" "${CI_HOME}/.grok/bin"
    _vendor="${CI_HOME}/.grok/downloads/grok-${_plat}"
    printf '%s\n' '#!/bin/sh' 'echo grok 0.0.0-test' > "${_vendor}"
    chmod +x "${_vendor}"
    cat > "${CI_HOME}/.grok/bin/grok" <<EOF
#!/bin/sh
unset LD_PRELOAD
TERMUX_EXEC_OPTOUT=1
export TERMUX_EXEC_OPTOUT
_g='${_vendor}'
_p=\$(command -v proot 2>/dev/null || true)
exec "\${_p}" "\${_g}" "\$@"
EOF
    chmod +x "${CI_HOME}/.grok/bin/grok"
    ln -sf "${CI_HOME}/.grok/bin/grok" "${CI_USER_BIN}/grok"
    CURL_LOG="${CI_HOME}/curl.log"
    export CURL_LOG
    _all=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" \
            PATH="${CI_USER_BIN}:${_tb}:${CI_HOME}/fakecurl" \
            sh "${SCRIPT}" setup 2>&1
    )
    _ec=$?
    assert_eq "TP-VCLI-28 heal setup exit 0" 0 "${_ec}"
    assert_contains "TP-VCLI-28 already installed" "${_all}" "already installed"
    assert_contains "TP-VCLI-28 INFO rewrote wrapper" "${_all}" "Rewrote"
    _wrap=$(cat "${CI_HOME}/.grok/bin/grok" 2>/dev/null || true)
    assert_contains "TP-VCLI-28 healed wrapper has kill-on-exit" "${_wrap}" "kill-on-exit"
    assert_contains "TP-VCLI-28 healed wrapper has --no-auto-update" "${_wrap}" "--no-auto-update"
    if [ -f "${CURL_LOG}" ]; then
        t_fail "TP-VCLI-28 curl was invoked on wrapper heal"
    else
        t_pass "TP-VCLI-28 no curl on wrapper heal"
    fi
    ci_cleanup_env
    unset CURL_LOG
}
