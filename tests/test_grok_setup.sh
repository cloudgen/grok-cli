# =============================================================================
# tests/test_grok_setup.sh — TP-VCLI-* vendor grok installer (no public network)
# =============================================================================
# ALIGNMENT: requirement-grok-setup.md
# =============================================================================

# POSIX tools only — excludes host grok (~/.grok/bin) and optionally curl.
ci_toolbin() {
    _tb="${CI_HOME}/toolbin"
    mkdir -p "${_tb}"
    for _t in sh bash mktemp rm id chmod mkdir cat grep sed awk tr cut head ls mv cp ln; do
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
body='#!/bin/sh
: "${USER_BIN:=${HOME}/.local/bin}"
mkdir -p "${USER_BIN}"
printf "%s\n" "#!/bin/sh" "echo grok-stub" > "${USER_BIN}/grok"
chmod +x "${USER_BIN}/grok"
'
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
    t_header "TP-VCLI grok-cli setup (peer grok installer)"

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
    assert_not_contains "TP-VCLI-02 help no self-update" "${_out}" "self-update"
    assert_not_contains "TP-VCLI-02 help no SCRIPT_URL" "${_out}" "SCRIPT_URL"
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
    if [ -f "${CURL_LOG}" ] && grep -q 'x.ai/cli/install.sh' "${CURL_LOG}"; then
        t_pass "TP-VCLI-05 curl hit vendor URL"
    else
        t_fail "TP-VCLI-05 curl log missing vendor URL"
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
    assert_contains "TP-VCLI-06 error happened" "${_err}" "Download of the grok installer failed"
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

    # TP-VCLI-08 fake installer places grok, not grok-cli
    ci_isolated_env
    ci_write_fake_curl "${CI_HOME}/fakecurl"
    _tb=$(ci_toolbin)
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/fakecurl:${CI_USER_BIN}:${_tb}" \
            sh "${SCRIPT}" --json setup 2>/dev/null
    )
    _ec=$?
    assert_eq "TP-VCLI-08 setup exit 0" 0 "${_ec}"
    assert_file_exists "TP-VCLI-08 peer grok placed" "${CI_USER_BIN}/grok"
    assert_file_missing "TP-VCLI-08 did not write grok-cli as peer" "${CI_USER_BIN}/grok-cli"
    assert_contains "TP-VCLI-09 JSON installed" "${_out}" '"status":"installed"'
    assert_contains "TP-VCLI-09 JSON peer grok" "${_out}" '"peer":"grok"'
    ci_cleanup_env
}
