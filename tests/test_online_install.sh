# =============================================================================
# tests/test_online_install.sh — TP-ONL-* channel curl|sh (fake curl; no public net)
# =============================================================================
# ALIGNMENT: requirement-shell-online-install.md · requirement-shell-automatic-checksum.md
#            requirement-shell-self-management.md · requirement-shell-cli-zero-arguments.md
# =============================================================================

ci_write_channel_curl() {
    _dir="$1"
    mkdir -p "${_dir}"
    cp "${SCRIPT}" "${_dir}/payload"
    sha256sum "${_dir}/payload" | awk '{ print $1 }' > "${_dir}/payload.sha256"
    cat > "${_dir}/curl" <<'EOS'
#!/bin/sh
out=""
url=""
while [ $# -gt 0 ]; do
    case "$1" in
        -o|--output) out="$2"; shift 2 ;;
        -fsSL|-f|-s|-S|-L|-fsS|-fs|-fL) shift ;;
        -w) shift ;;
        -*) shift ;;
        *) url="$1"; shift ;;
    esac
done
if [ -n "${CURL_LOG:-}" ]; then
    printf '%s\n' "${url}" >> "${CURL_LOG}"
fi
if [ "${CURL_FAIL:-0}" = "1" ]; then
    exit 22
fi
_dir=$(dirname "$0")
_src="${_dir}/payload"
case "${url}" in
    *.sha256) _src="${_dir}/payload.sha256" ;;
esac
if [ -n "${out}" ]; then
    cat "${_src}" > "${out}"
else
    cat "${_src}"
fi
exit 0
EOS
    chmod +x "${_dir}/curl"
}

run_test_online_install() {
    t_header "TP-ONL grok-cli channel install (fake curl)"

    ci_isolated_env
    ci_write_channel_curl "${CI_HOME}/fakecurl"
    CURL_LOG="${CI_HOME}/curl.log"
    export CURL_LOG
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" \
            PATH="${CI_HOME}/fakecurl:${PATH}" \
            SCRIPT_URL="https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli" \
            sh "${SCRIPT}" 2>/dev/null
    )
    _ec=$?
    assert_eq "TP-ONL-01 empty argv channel exit 0" 0 "${_ec}"
    assert_file_exists "TP-ONL-01 placed grok-cli" "${CI_USER_BIN}/grok-cli"
    assert_not_contains "TP-ONL-01 not help" "${_out}" "Usage:"
    if [ -f "${CURL_LOG}" ] && grep -q 'install.sh' "${CURL_LOG}"; then
        t_fail "TP-ONL-01 must not fetch x.ai install.sh"
    else
        t_pass "TP-ONL-01 curl did not fetch x.ai install.sh"
    fi
    ci_cleanup_env
    unset CURL_LOG

    ci_isolated_env
    ci_write_channel_curl "${CI_HOME}/fakecurl"
    printf '%s\n' "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef" \
        > "${CI_HOME}/fakecurl/payload.sha256"
    _ec=0
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" \
            PATH="${CI_HOME}/fakecurl:${PATH}" \
            SCRIPT_URL="https://example.invalid/grok-cli" \
            sh "${SCRIPT}" 2>&1 >/dev/null
    ) || _ec=$?
    assert_eq "TP-ONL-02 mismatch exit 1" 1 "${_ec}"
    assert_contains "TP-ONL-02 mismatch text" "${_err}" "Checksum verification failed"
    ci_cleanup_env

    ci_isolated_env
    ci_write_channel_curl "${CI_HOME}/fakecurl"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install >/dev/null 2>&1
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" \
            PATH="${CI_HOME}/fakecurl:${PATH}" \
            SCRIPT_URL="https://example.invalid/grok-cli" \
            sh "${SCRIPT}" --json version-check 2>/dev/null
    )
    assert_contains "TP-ONL-03 version-check json type" "${_out}" '"type":"ver_check"'
    assert_contains "TP-ONL-03 version-check remote" "${_out}" '"remote_version"'
    ci_cleanup_env

    ci_isolated_env
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install >/dev/null 2>&1
    assert_file_exists "TP-ONL-04 pre uninstall binary" "${CI_USER_BIN}/grok-cli"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" --force self-uninstall >/dev/null 2>&1
    assert_file_missing "TP-ONL-04 self-uninstall removed binary" "${CI_USER_BIN}/grok-cli"
    ci_cleanup_env
}
