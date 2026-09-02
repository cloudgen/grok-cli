# =============================================================================
# tests/test_grok_setup.sh — TP-VCLI-* peer grok channel + artifact (no public network)
# =============================================================================
# ALIGNMENT: requirement-grok-setup.md
# =============================================================================

# POSIX tools only — excludes host grok (~/.grok/bin) and optionally curl.
ci_toolbin() {
    _tb="${CI_HOME}/toolbin"
    mkdir -p "${_tb}"
    for _t in sh bash mktemp rm id chmod mkdir cat grep sed awk tr cut head ls mv cp ln uname dirname basename; do
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
while [ $# -gt 0 ]; do
    case "$1" in
        -o|--output)
            out="$2"
            shift 2
            ;;
        -fsSL|-f|-s|-S|-L|-fsS|-fs|-fL)
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
if [ -n "${CURL_LOG:-}" ]; then
    printf '%s\n' "${url}" >> "${CURL_LOG}"
fi
if [ "${CURL_FAIL:-0}" = "1" ]; then
    exit 22
fi
# Compressed variants: not provided by this stub (setup falls through to raw).
case "${url}" in
    *.zst|*.gz)
        exit 22
        ;;
esac
if [ "${CURL_EMPTY_BIN:-0}" = "1" ]; then
    case "${url}" in
        *grok-*)
            if [ -n "${out}" ]; then
                : > "${out}"
            fi
            exit 22
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
        body='#!/bin/sh
echo grok 0.0.0-test
exit 0
'
        ;;
    */stable|*/alpha|*/enterprise|*/stable/*|*/alpha/*|*/enterprise/*)
        body='0.0.0-test'
        ;;
    *)
        exit 22
        ;;
esac
if [ -n "${out}" ]; then
    printf '%s\n' "${body}" > "${out}"
else
    printf '%s\n' "${body}"
fi
exit 0
EOS
    chmod +x "${_dir}/curl"
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
    assert_contains "TP-VCLI-12 Next step" "${_err}" "Next:"
    assert_contains "TP-VCLI-12 Next is setup" "${_err}" "setup"
    assert_not_contains "TP-VCLI-12 does not say add USER_BIN" "${_err}" "add ${CI_USER_BIN} to PATH"
    ci_cleanup_env
}
