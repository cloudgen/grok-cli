# =============================================================================
# tests/test_local_lifecycle.sh — local install / uninstall / where-is-me
# =============================================================================
# Primary REQs: requirement-shell-local-self-management, requirement-shell-idempotency,
# requirement-shell-interactive-vs-noninteractive,
# requirement-shell-path-and-shell-support (TP-LC-11..14, 20..22, 23..33, rc-test)
# TP family: TP-LC-*
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_local_lifecycle() {
    t_header "Local lifecycle (TP-LC)"

    require_cmd sh
    require_cmd tar

    ci_isolated_env

    # TP-LC-01 install places binary under USER_BIN
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-01 install exit 0" 0 "$_ec"
    assert_file_exists "TP-LC-01 binary at USER_BIN" "${CI_USER_BIN}/${APP_NAME}"
    assert_contains "TP-LC-01 install success text" "$_out" "Installed"

    # TP-LC-02 installed version works
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" version 2>/dev/null)
    assert_eq "TP-LC-02 installed version exit 0" 0 "$?"
    assert_contains "TP-LC-02 installed version" "$_out" "${PRODUCT_VERSION}"

    # TP-LC-03 idempotent reinstall without force
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-03 reinstall exit 0" 0 "$_ec"
    assert_contains "TP-LC-03 already installed" "$_out" "already installed"

    # TP-LC-04 where-is-me
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" where-is-me 2>&1)
    _ec=$?
    assert_eq "TP-LC-04 where-is-me exit 0" 0 "$_ec"
    assert_contains "TP-LC-04 install path" "$_out" "${CI_USER_BIN}/${APP_NAME}"
    assert_contains "TP-LC-04 installed yes" "$_out" "yes"

    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" --json where-is-me 2>/dev/null)
    assert_contains "TP-LC-04 json installed true" "$_out" '"installed":"true"'

    # TP-LC-05 uninstall --json without force fails closed
    _err=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" --json uninstall 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-LC-05 uninstall json no-force exit 1" 1 "$_ec"
    assert_file_exists "TP-LC-05 binary remains" "${CI_USER_BIN}/${APP_NAME}"

    # TP-LC-06 uninstall --force removes
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force 2>&1)
    _ec=$?
    assert_eq "TP-LC-06 uninstall --force exit 0" 0 "$_ec"
    assert_file_missing "TP-LC-06 binary removed" "${CI_USER_BIN}/${APP_NAME}"

    # TP-LC-07 uninstall when absent is success no-op
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" uninstall --force 2>&1)
    _ec=$?
    assert_eq "TP-LC-07 uninstall absent exit 0" 0 "$_ec"
    assert_contains "TP-LC-07 nothing to uninstall" "$_out" "not installed"

    # TP-LC-08 about after install shows installed
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install >/dev/null 2>&1
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" --json about 2>/dev/null)
    assert_contains "TP-LC-08 about installed true" "$_out" '"installed":"true"'

    # TP-LC-09 managed binary mode must be 0755 (shell ship unit multi-user runnable)
    _mode=$(stat -c '%a' "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || stat -f '%OLp' "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || echo "")
    case "${_mode}" in
        755|0755) assert_eq "TP-LC-09 install mode 0755" "0755" "0755" ;;
        *) assert_eq "TP-LC-09 install mode 0755" "0755" "${_mode}" ;;
    esac
    # Must be readable+executable (not 0711 execute-without-read)
    if [ -r "${CI_USER_BIN}/${APP_NAME}" ] && [ -x "${CI_USER_BIN}/${APP_NAME}" ]; then
        assert_eq "TP-LC-09 readable+executable" "1" "1"
    else
        assert_eq "TP-LC-09 readable+executable" "1" "0"
    fi

    # TP-LC-10 re-install without --force heals broken mode (0711 trap)
    chmod 0711 "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || chmod 711 "${CI_USER_BIN}/${APP_NAME}"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-10 heal reinstall exit 0" 0 "$_ec"
    assert_contains "TP-LC-10 already installed path" "$_out" "already installed"
    _mode=$(stat -c '%a' "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || stat -f '%OLp' "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || echo "")
    case "${_mode}" in
        755|0755) assert_eq "TP-LC-10 healed mode 0755" "0755" "0755" ;;
        *) assert_eq "TP-LC-10 healed mode 0755" "0755" "${_mode}" ;;
    esac

    # TP-LC-11 install creates ~/.bashrc with exact USER_BIN PATH
    _bashrc=$(cat "${CI_HOME}/.bashrc" 2>/dev/null || true)
    _path_line=$(ci_bashrc_path_line)
    assert_file_exists "TP-LC-11 created ~/.bashrc" "${CI_HOME}/.bashrc"
    assert_contains "TP-LC-11 bashrc exact export PATH" "$_bashrc" "${_path_line}"
    assert_contains "TP-LC-11 bashrc has VERSION comment" "$_bashrc" "Added by ${APP_NAME} installer (${PRODUCT_VERSION})"

    # TP-LC-12 install creates ~/.profile that sources ~/.bashrc
    assert_file_exists "TP-LC-12 created ~/.profile" "${CI_HOME}/.profile"
    _profile=$(cat "${CI_HOME}/.profile" 2>/dev/null || true)
    assert_contains "TP-LC-12 profile sources bashrc" "$_profile" '. "${HOME}/.bashrc"'

    # TP-LC-13 second install does not duplicate PATH
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install >/dev/null 2>&1
    _path_hits=$(grep -cF "${_path_line}" "${CI_HOME}/.bashrc" 2>/dev/null || true)
    [ -z "${_path_hits}" ] && _path_hits=0
    assert_eq "TP-LC-13 PATH export once" "1" "${_path_hits}"

    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-14 keep existing .profile body
    ci_isolated_env
    printf '%s\n' "# keep-me-profile" > "${CI_HOME}/.profile"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install >/dev/null 2>&1
    _profile=$(cat "${CI_HOME}/.profile" 2>/dev/null || true)
    assert_contains "TP-LC-14 profile body kept" "$_profile" "keep-me-profile"
    assert_not_contains "TP-LC-14 did not rewrite profile with grok-cli BEGIN" "$_profile" "BEGIN grok-cli profile"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-20 BASHRC env: create in a random temp folder when missing
    ci_isolated_env
    ci_isolated_bashrc
    assert_file_missing "TP-LC-20 BASHRC absent before install" "${CI_BASHRC}"
    assert_file_missing "TP-LC-20 HOME/.bashrc absent before install" "${CI_HOME}/.bashrc"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-20 install exit 0" 0 "$_ec"
    assert_file_exists "TP-LC-20 created BASHRC in temp folder" "${CI_BASHRC}"
    assert_file_missing "TP-LC-20 did not write HOME/.bashrc" "${CI_HOME}/.bashrc"
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    _path_line=$(ci_bashrc_path_line)
    assert_contains "TP-LC-20 created header names VERSION" "$_bashrc" "Interactive rc created by ${APP_NAME} installer (${PRODUCT_VERSION})"
    assert_contains "TP-LC-20 created Added-by VERSION" "$_bashrc" "Added by ${APP_NAME} installer (${PRODUCT_VERSION})"
    assert_contains "TP-LC-20 created exact export PATH" "$_bashrc" "${_path_line}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-21 BASHRC env: modify a dongle .bashrc
    ci_isolated_env
    ci_isolated_bashrc
    printf '%s\n' "# dongle-bashrc-keep" "alias dongle_probe=true" > "${CI_BASHRC}"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-21 install exit 0" 0 "$_ec"
    assert_file_missing "TP-LC-21 did not write HOME/.bashrc" "${CI_HOME}/.bashrc"
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    _path_line=$(ci_bashrc_path_line)
    assert_contains "TP-LC-21 dongle body kept" "$_bashrc" "dongle-bashrc-keep"
    assert_contains "TP-LC-21 dongle alias kept" "$_bashrc" "alias dongle_probe=true"
    assert_contains "TP-LC-21 dongle got Added-by VERSION" "$_bashrc" "Added by ${APP_NAME} installer (${PRODUCT_VERSION})"
    assert_contains "TP-LC-21 dongle exact export PATH" "$_bashrc" "${_path_line}"
    _path_hits=$(grep -cF "${_path_line}" "${CI_BASHRC}" 2>/dev/null || true)
    [ -z "${_path_hits}" ] && _path_hits=0
    assert_eq "TP-LC-21 PATH export once" "1" "${_path_hits}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-22 BASHRC env: VERSION + exact PATH already match → no-op
    ci_isolated_env
    ci_isolated_bashrc
    _path_line=$(ci_bashrc_path_line)
    {
        printf '%s\n' "# dongle-already-good"
        printf '# Interactive rc created by %s installer (%s)\n' "${APP_NAME}" "${PRODUCT_VERSION}"
        printf '\n'
        printf '# Added by %s installer (%s)\n' "${APP_NAME}" "${PRODUCT_VERSION}"
        printf '%s\n' "${_path_line}"
    } > "${CI_BASHRC}"
    cp "${CI_BASHRC}" "${CI_BASHRC}.orig"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-22 install exit 0" 0 "$_ec"
    if cmp -s "${CI_BASHRC}" "${CI_BASHRC}.orig"; then
        t_pass "TP-LC-22 bashrc bytes unchanged"
    else
        t_fail "TP-LC-22 bashrc bytes unchanged"
    fi
    assert_not_contains "TP-LC-22 no Created BASHRC" "$_out" "Created ${CI_BASHRC}"
    assert_not_contains "TP-LC-22 no Added PATH for bash" "$_out" "Added ${CI_USER_BIN} to PATH for bash"
    assert_file_missing "TP-LC-22 did not write HOME/.bashrc" "${CI_HOME}/.bashrc"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-23 / 24 ZSHRC env modify / no-op
    ci_isolated_env
    CI_ZSHRC_DIR=$(mktemp -d "${TMPDIR:-/tmp}/gc-zshrc.XXXXXX")
    CI_ZSHRC="${CI_ZSHRC_DIR}/.zshrc"
    printf '%s\n' "# dongle-zshrc-keep" > "${CI_ZSHRC}"
    _path_line=$(ci_bashrc_path_line)
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" ZSHRC="${CI_ZSHRC}" sh "${SCRIPT}" install >/dev/null 2>&1
    _zsh=$(cat "${CI_ZSHRC}" 2>/dev/null || true)
    assert_contains "TP-LC-23 zshrc body kept" "$_zsh" "dongle-zshrc-keep"
    assert_contains "TP-LC-23 zshrc exact PATH" "$_zsh" "${_path_line}"
    cp "${CI_ZSHRC}" "${CI_ZSHRC}.orig"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" ZSHRC="${CI_ZSHRC}" sh "${SCRIPT}" install >/dev/null 2>&1
    if cmp -s "${CI_ZSHRC}" "${CI_ZSHRC}.orig"; then
        t_pass "TP-LC-24 zshrc bytes unchanged on second install"
    else
        t_fail "TP-LC-24 zshrc bytes unchanged on second install"
    fi
    rm -rf "${CI_ZSHRC_DIR}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-25 / 26 PROFILE env create / keep-body
    ci_isolated_env
    CI_PROF_DIR=$(mktemp -d "${TMPDIR:-/tmp}/gc-prof.XXXXXX")
    CI_PROF="${CI_PROF_DIR}/.profile"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PROFILE="${CI_PROF}" sh "${SCRIPT}" install >/dev/null 2>&1
    assert_file_exists "TP-LC-25 created PROFILE in temp folder" "${CI_PROF}"
    assert_file_missing "TP-LC-25 did not write HOME/.profile" "${CI_HOME}/.profile"
    _prof=$(cat "${CI_PROF}" 2>/dev/null || true)
    assert_contains "TP-LC-25 profile sources bashrc" "$_prof" '. "${HOME}/.bashrc"'
    printf '%s\n' "# keep-profile-body" > "${CI_PROF}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PROFILE="${CI_PROF}" sh "${SCRIPT}" install >/dev/null 2>&1
    _prof=$(cat "${CI_PROF}" 2>/dev/null || true)
    assert_contains "TP-LC-26 profile body kept" "$_prof" "keep-profile-body"
    rm -rf "${CI_PROF_DIR}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-27 already-installed skip heals missing PATH
    ci_isolated_env
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install >/dev/null 2>&1
    _path_line=$(ci_bashrc_path_line)
    printf '%s\n' "# leftover-comment-only" > "${CI_HOME}/.bashrc"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install 2>&1)
    assert_contains "TP-LC-27 already installed" "$_out" "already installed"
    _bashrc=$(cat "${CI_HOME}/.bashrc" 2>/dev/null || true)
    assert_contains "TP-LC-27 PATH restored" "$_bashrc" "${_path_line}"
    assert_contains "TP-LC-27 leftover body kept" "$_bashrc" "leftover-comment-only"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-28 sibling comment + exact PATH, no grok-cli comment
    ci_isolated_env
    ci_isolated_bashrc
    _path_line=$(ci_bashrc_path_line)
    {
        printf '%s\n' "# Added by sshd-cli installer (9.9.9)"
        printf '%s\n' "${_path_line}"
    } > "${CI_BASHRC}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install >/dev/null 2>&1
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    _path_hits=$(grep -cF "${_path_line}" "${CI_BASHRC}" 2>/dev/null || true)
    [ -z "${_path_hits}" ] && _path_hits=0
    assert_eq "TP-LC-28 PATH export once" "1" "${_path_hits}"
    assert_contains "TP-LC-28 sshd-cli comment kept" "$_bashrc" "Added by sshd-cli installer"
    assert_contains "TP-LC-28 grok-cli comment MAY appear" "$_bashrc" "Added by ${APP_NAME} installer (${PRODUCT_VERSION})"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-29 grok-cli comment present, exact PATH removed
    ci_isolated_env
    ci_isolated_bashrc
    printf '# Added by %s installer (%s)\n' "${APP_NAME}" "${PRODUCT_VERSION}" > "${CI_BASHRC}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install >/dev/null 2>&1
    _path_line=$(ci_bashrc_path_line)
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    assert_contains "TP-LC-29 PATH restored once" "$_bashrc" "${_path_line}"
    _path_hits=$(grep -cF "${_path_line}" "${CI_BASHRC}" 2>/dev/null || true)
    [ -z "${_path_hits}" ] && _path_hits=0
    assert_eq "TP-LC-29 PATH export once" "1" "${_path_hits}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-31 vendor grok installer block unchanged
    ci_isolated_env
    ci_isolated_bashrc
    {
        printf '%s\n' "# >>> grok installer >>>"
        printf '%s\n' 'export PATH="$HOME/.grok/bin:$PATH"'
        printf '%s\n' "# <<< grok installer <<<"
    } > "${CI_BASHRC}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install >/dev/null 2>&1
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    assert_contains "TP-LC-31 vendor begin kept" "$_bashrc" "# >>> grok installer >>>"
    assert_contains "TP-LC-31 vendor grok/bin kept" "$_bashrc" 'export PATH="$HOME/.grok/bin:$PATH"'
    assert_contains "TP-LC-31 vendor end kept" "$_bashrc" "# <<< grok installer <<<"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-32 uninstall while USER_BIN still has a sibling file
    ci_isolated_env
    ci_isolated_bashrc
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install >/dev/null 2>&1
    printf '%s\n' "x" > "${CI_USER_BIN}/sshd-cli"
    _path_line=$(ci_bashrc_path_line)
    {
        printf '%s\n' "# Added by sshd-cli installer (1.0.0)"
        printf '%s\n' "# Added by ${APP_NAME} installer (${PRODUCT_VERSION})"
        printf '%s\n' "${_path_line}"
    } > "${CI_BASHRC}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    assert_contains "TP-LC-32 PATH stays" "$_bashrc" "${_path_line}"
    assert_contains "TP-LC-32 sibling comment stays" "$_bashrc" "Added by sshd-cli installer"
    assert_not_contains "TP-LC-32 grok-cli comment gone" "$_bashrc" "Added by ${APP_NAME} installer"
    rm -f "${CI_USER_BIN}/sshd-cli"
    ci_cleanup_env

    # TP-LC-33 sudoer-cli login-hook block kept
    ci_isolated_env
    ci_isolated_bashrc
    {
        printf '%s\n' "# BEGIN sudoer-cli login hook"
        printf '%s\n' "true"
        printf '%s\n' "# END sudoer-cli login hook"
    } > "${CI_BASHRC}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install >/dev/null 2>&1
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    assert_contains "TP-LC-33 hook begin kept" "$_bashrc" "# BEGIN sudoer-cli login hook"
    assert_contains "TP-LC-33 hook end kept" "$_bashrc" "# END sudoer-cli login hook"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # rc-test routed --root (does not write HOME/.bashrc)
    ci_isolated_env
    CI_RCT=$(mktemp -d "${TMPDIR:-/tmp}/gc-rct.XXXXXX")
    assert_file_missing "rc-test HOME/.bashrc absent before" "${CI_HOME}/.bashrc"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" rc-test --root "${CI_RCT}" --file bashrc --case create 2>&1)
    _ec=$?
    assert_eq "rc-test create exit 0" 0 "$_ec"
    assert_file_exists "rc-test created fixture bashrc" "${CI_RCT}/.bashrc"
    assert_file_missing "rc-test did not write HOME/.bashrc" "${CI_HOME}/.bashrc"
    assert_contains "rc-test success text" "$_out" "rc-test bashrc create"
    rm -rf "${CI_RCT}"
    ci_cleanup_env
}
