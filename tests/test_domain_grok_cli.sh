# =============================================================================
# tests/test_domain_grok_cli.sh — grok auth backup/sync + domain surface
# =============================================================================
# Primary ops REQ: requirement-grok-auth-backup (NOT domain)
# Domain surface:  requirement-domain-grok-cli (verbs/help/about pointers)
# Privilege peer:  requirement-three-layer-privilege-model
# JSON grant:      requirement-sudoer-json-file
# TP family: TP-GROK-CLI-*
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

gc_write_valid_auth() {
    _dir="${1:-}"
    mkdir -p "${_dir}"
    cat > "${_dir}/auth.json" <<'AUTH'
{
  "https://auth.x.ai::test-client": {
    "key": "test-access-token",
    "auth_mode": "oidc",
    "refresh_token": "test-refresh-token",
    "expires_at": "2099-01-01T00:00:00Z"
  }
}
AUTH
    printf 'lock\n' > "${_dir}/auth.json.lock"
    chmod 0600 "${_dir}/auth.json"
}

gc_write_expired_auth() {
    _dir="${1:-}"
    mkdir -p "${_dir}"
    cat > "${_dir}/auth.json" <<'AUTH'
{
  "https://auth.x.ai::test-client": {
    "key": "expired-access-token",
    "auth_mode": "oidc",
    "expires_at": "2000-01-01T00:00:00Z"
  }
}
AUTH
}

run_test_domain_grok_cli() {
    t_header "Domain grok-cli (TP-GROK-CLI)"

    require_cmd sh

    ci_isolated_env

    # TP-GROK-CLI-01 print-sudoers human emits fragment; Type 0 must not install /etc
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" print-sudoers --allow-test-local 2>&1)
    _ec=$?
    assert_eq "TP-GROK-CLI-01 print-sudoers exit 0" 0 "$_ec"
    assert_contains "TP-GROK-CLI-01 NOPASSWD" "$_out" "NOPASSWD"
    assert_contains "TP-GROK-CLI-01 project backup verb" "$_out" "grok-cli backup"
    assert_not_contains "TP-GROK-CLI-01 no restore verb" "$_out" "grok-cli restore"
    assert_contains "TP-GROK-CLI-01 admin install hint" "$_out" "sudoers.d/"
    assert_contains "TP-GROK-CLI-01 test mode banner" "$_out" "TEST MODE ONLY"
    assert_not_contains "TP-GROK-CLI-01 no tar Cmnd" "$_out" "tar -tzf"
    if [ -e /etc/sudoers.d/grok-cli ]; then
        t_pass "TP-GROK-CLI-01 host has admin sudoers (print-sudoers is Type 0 only; no /etc write attempted)"
    else
        assert_file_missing "TP-GROK-CLI-01 no /etc write" "/etc/sudoers.d/grok-cli"
    fi

    # TP-GROK-CLI-01b refuse test_local emit without allow flag
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" print-sudoers 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-GROK-CLI-01b refuse without allow-test-local exit 1" 1 "$_ec"
    assert_contains "TP-GROK-CLI-01b hint allow-test-local" "$_err" "allow-test-local"

    # TP-GROK-CLI-02 print-sudoers to path
    _frag="${CI_HOME}/out/sudoers-draft.txt"
    mkdir -p "${CI_HOME}/out"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" print-sudoers --allow-test-local "${_frag}" 2>&1)
    _ec=$?
    assert_eq "TP-GROK-CLI-02 write fragment exit 0" 0 "$_ec"
    assert_file_exists "TP-GROK-CLI-02 fragment file" "${_frag}"
    assert_contains "TP-GROK-CLI-02 file has project backup" "$(cat "${_frag}")" "grok-cli backup"
    assert_not_contains "TP-GROK-CLI-02 no ALL ALL" "$(cat "${_frag}")" "NOPASSWD: ALL"
    assert_contains "TP-GROK-CLI-02 test mode in file" "$(cat "${_frag}")" "TEST MODE ONLY"
    _ci_user=$(id -un 2>/dev/null || echo "unknown")
    assert_contains "TP-GROK-CLI-02 user-bound" "$(cat "${_frag}")" "${_ci_user} ALL=(root)"

    # TP-GROK-CLI-22 JSON sudoer file
    _jgrant="${_frag}.json"
    assert_file_exists "TP-GROK-CLI-22 JSON grant file" "${_jgrant}"
    _jbody=$(cat "${_jgrant}")
    assert_contains "TP-GROK-CLI-22 path is grok-cli" "${_jbody}" '/grok-cli"'
    assert_contains "TP-GROK-CLI-22 backup args" "${_jbody}" '"backup"'
    assert_not_contains "TP-GROK-CLI-22 no restore args" "${_jbody}" '"restore"'
    assert_not_contains "TP-GROK-CLI-22b no mkdir" "${_jbody}" "mkdir"
    assert_not_contains "TP-GROK-CLI-22b no /usr/bin/cp" "${_jbody}" "/usr/bin/cp"
    assert_not_contains "TP-GROK-CLI-22b no tar" "${_jbody}" "tar"
    assert_not_contains "TP-GROK-CLI-22b no /bin/rm" "${_jbody}" "/bin/rm"
    assert_not_contains "TP-GROK-CLI-22b no install -m" "${_jbody}" "install"
    assert_not_contains "TP-GROK-CLI-22c no deposit path" "${_jbody}" "/var/grok-cli"

    # TP-GROK-CLI-22e pretty emit through real sudoer-cli keeps backup
    _srcli=""
    if [ -x "${REPO_ROOT}/../sudoer-cli/src/sudoer-cli" ]; then
        _srcli="${REPO_ROOT}/../sudoer-cli/src/sudoer-cli"
    elif [ -x /usr/local/bin/sudoer-cli ]; then
        _srcli=/usr/local/bin/sudoer-cli
    elif command -v sudoer-cli >/dev/null 2>&1; then
        _srcli=$(command -v sudoer-cli)
    fi
    if [ -n "${_srcli}" ] && [ -x "${_srcli}" ]; then
        _pback="${CI_HOME}/out/pretty-back.sudoers"
        _prod="${CI_HOME}/out/prod-grant.json"
        mkdir -p "${CI_HOME}/out"
        # Convert check uses production path /usr/local/bin (isolated GLOBAL_BIN is not a well-known binary).
        HOME="${CI_HOME}" GLOBAL_BIN=/usr/local/bin sh "${SCRIPT}" print-sudoers --allow-test-local "${CI_HOME}/out/prod-frag.txt" >/dev/null 2>&1
        _prod="${CI_HOME}/out/prod-frag.txt.json"
        _crc=1
        if [ -f "${_prod}" ]; then
            HOME="${CI_HOME}" sh "${_srcli}" json-to-sudoers --file "${_prod}" --out "${_pback}" >/dev/null 2>&1
            _crc=$?
        fi
        assert_eq "TP-GROK-CLI-22e pretty convert exit 0" 0 "${_crc}"
        _pbtxt=$(cat "${_pback}" 2>/dev/null || true)
        assert_contains "TP-GROK-CLI-22e convert keeps backup" "${_pbtxt}" "grok-cli backup"
        assert_not_contains "TP-GROK-CLI-22e convert no restore" "${_pbtxt}" "grok-cli restore"
    else
        t_skip "TP-GROK-CLI-22e sudoer-cli not installed"
    fi

    # TP-GROK-CLI-03 check-session missing peer grok
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" sh "${SCRIPT}" check-session 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-03 check-session missing grok exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-03 not installed" "$_err" "not installed"
    assert_contains "TP-GROK-CLI-03 next setup" "$_err" "setup"
    assert_contains "TP-GROK-CLI-03 next grok login" "$_err" "grok login"

    # TP-GROK-CLI-04 auth.json looks valid but grok -p hello fails (file check is not enough)
    gc_write_valid_auth "${CI_HOME}/.grok"
    ci_fake_grok_fail
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        sh "${SCRIPT}" check-session 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-04 probe fail exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-04 not logged in" "$_err" "not logged in"
    assert_contains "TP-GROK-CLI-04 next grok login" "$_err" "grok login"

    # TP-GROK-CLI-05 check-session valid = grok -p hello exit 0
    ci_fake_grok_ok
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        sh "${SCRIPT}" check-session 2>&1)
    assert_eq "TP-GROK-CLI-05 valid session exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-05 probe text" "$_out" "grok -p hello"
    assert_not_contains "TP-GROK-CLI-05 no grok answer leak" "$_out" "hello-from-fake-grok"
    _j=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        sh "${SCRIPT}" --json check-session 2>/dev/null)
    assert_contains "TP-GROK-CLI-05 json session valid" "${_j}" '"session":"valid"'

    # TP-GROK-CLI-06 backup without live session fail-closed
    ci_fake_grok_fail
    _store="${CI_HOME}/var-grok-cli"
    mkdir -p "${_store}"
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        GROK_CLI_ROOT="${_store}" sh "${SCRIPT}" backup 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-06 backup no session exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-06 backup next login" "$_err" "grok login"

    # TP-GROK-CLI-07 backup to writable GROK_CLI_ROOT (test override; no sudo)
    gc_write_valid_auth "${CI_HOME}/.grok"
    ci_fake_grok_ok
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        GROK_CLI_ROOT="${_store}" sh "${SCRIPT}" backup 2>&1)
    assert_eq "TP-GROK-CLI-07 backup exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-07 backup complete" "$_out" "Backup complete"
    assert_file_exists "TP-GROK-CLI-07 dest auth.json" "${_store}/auth.json"
    assert_file_exists "TP-GROK-CLI-07 dest lock" "${_store}/auth.json.lock"
    _mode=$(stat -c '%a' "${_store}/auth.json" 2>/dev/null || stat -f '%OLp' "${_store}/auth.json" 2>/dev/null || echo "")
    assert_eq "TP-GROK-CLI-07 dest auth.json mode 0644" "644" "${_mode}"
    assert_contains "TP-GROK-CLI-07 dest has refresh_token" "$(cat "${_store}/auth.json")" "test-refresh-token"

    # TP-GROK-CLI-08 backup is idempotent overwrite
    printf 'stale\n' > "${_store}/auth.json"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        GROK_CLI_ROOT="${_store}" sh "${SCRIPT}" backup 2>&1)
    assert_eq "TP-GROK-CLI-08 second backup exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-08 overwrite restored token" "$(cat "${_store}/auth.json")" "test-refresh-token"

    # TP-GROK-CLI-09 sync-auth copies into a fresh grok home without sudo
    # (logged-out dest: live probe must not be valid — drop fake grok).
    unset GROK_BIN 2>/dev/null || true
    rm -f "${CI_USER_BIN}/grok" "${CI_GLOBAL_BIN}/grok"
    _other="${CI_HOME}/other-grok"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${_other}" GROK_CLI_ROOT="${_store}" \
        env -u GROK_BIN sh "${SCRIPT}" sync-auth 2>&1)
    assert_eq "TP-GROK-CLI-09 sync-auth exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-09 complete" "$_out" "sync-auth complete"
    assert_file_exists "TP-GROK-CLI-09 dest auth.json" "${_other}/auth.json"
    _omode=$(stat -c '%a' "${_other}/auth.json" 2>/dev/null || stat -f '%OLp' "${_other}/auth.json" 2>/dev/null || echo "")
    assert_eq "TP-GROK-CLI-09 dest auth.json mode 0600" "600" "${_omode}"
    assert_contains "TP-GROK-CLI-09 dest token" "$(cat "${_other}/auth.json")" "test-refresh-token"

    # TP-GROK-CLI-10 sync-auth missing store fail-closed
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_CLI_ROOT="${CI_HOME}/no-store" \
        env -u GROK_BIN sh "${SCRIPT}" sync-auth 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-10 missing store exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-10 next backup" "$_err" "backup"

    # TP-GROK-CLI-11 restore command unknown
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" restore anything 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-11 restore unknown exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-11 restore unknown text" "$_err" "Unknown command"

    # TP-GROK-CLI-12 production dest /var/grok-cli without global binary fails closed (no write)
    gc_write_valid_auth "${CI_HOME}/.grok"
    ci_fake_grok_ok
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        GROK_CLI_ROOT=/var/grok-cli sh "${SCRIPT}" backup 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-12 production dest without global binary exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-12 next install/grant" "$_err" "install"

    # TP-GROK-CLI-14 admin install script
    _script="${CI_HOME}/sudoers-admin.sh"
    _user=$(id -un 2>/dev/null || echo "unknown")
    _draft_default="${CI_HOME}/.config/grok-cli/sudoers.fragment-${_user}"
    : "${CI_SUDOERS_D:=${CI_HOME}/sudoers.d}"
    _installed_default="${CI_SUDOERS_D}/grok-cli-${_user}"
    _installed_real="/etc/sudoers.d/grok-cli-${_user}"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" print-sudoers-install-script --allow-test-local "${_script}" 2>&1)
    _ec=$?
    assert_eq "TP-GROK-CLI-14 install-script exit 0" 0 "$_ec"
    assert_file_exists "TP-GROK-CLI-14 admin script file" "${_script}"
    assert_file_exists "TP-GROK-CLI-14 project-sudoers-file draft per-user" "${_draft_default}"
    assert_contains "TP-GROK-CLI-14 script has install" "$(cat "${_script}")" "cmd_install"
    assert_contains "TP-GROK-CLI-14 script has uninstall" "$(cat "${_script}")" "cmd_uninstall"
    assert_contains "TP-GROK-CLI-14 per-user installed path" "$(cat "${_script}")" "${_installed_default}"
    assert_contains "TP-GROK-CLI-14 no etc write by type0" "$_out" "Handoff"
    sh -n "${_script}"
    assert_eq "TP-GROK-CLI-14 admin script sh -n" 0 "$?"
    _st=$(sh "${_script}" status 2>&1)
    assert_contains "TP-GROK-CLI-14 status draft path" "$_st" "sudoers.fragment-${_user}"
    assert_contains "TP-GROK-CLI-14 require root for install" "$(sh "${_script}" install 2>&1 || true)" "root"

    # TP-GROK-CLI-15 remove-project-sudoers
    _draft="${_draft_default}"
    assert_file_exists "TP-GROK-CLI-15 draft exists before remove" "${_draft}"
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" remove-project-sudoers 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-15 remove without force fail-closed" 1 "$?"
    assert_file_exists "TP-GROK-CLI-15 draft remains without force" "${_draft}"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" remove-project-sudoers --force 2>&1)
    assert_eq "TP-GROK-CLI-15 remove --force exit 0" 0 "$?"
    assert_file_missing "TP-GROK-CLI-15 draft removed" "${_draft}"
    assert_contains "TP-GROK-CLI-15 mentions host path" "$_out" "sudoers.d/"
    mkdir -p "${CI_SUDOERS_D}"
    printf '# probe\n' > "${_installed_default}"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" remove-project-sudoers --force 2>&1)
    assert_contains "TP-GROK-CLI-15 host elev still active warn" "$_out" "STILL ACTIVE"
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" remove-project-sudoers --force /etc/sudoers.d/grok-cli 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-15 refuse /etc exit 1" 1 "$?"
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" remove-project-sudoers --force "${_installed_real}" 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-15 refuse per-user /etc exit 1" 1 "$?"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" remove-project-sudoers --force 2>&1)
    assert_eq "TP-GROK-CLI-15 already absent exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-15 already absent text" "$_out" "not present"
    rm -f "${_installed_default}"

    # TP-GROK-CLI-15b multi-draft
    mkdir -p "${CI_HOME}/.config/grok-cli"
    printf '# legacy draft\n' > "${CI_HOME}/.config/grok-cli/sudoers.fragment"
    printf '# user draft\n' > "${_draft_default}"
    printf '# other draft\n' > "${CI_HOME}/.config/grok-cli/sudoers.fragment-otheruser"
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" remove-project-sudoers --force 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-15b multi-draft noninteractive needs path" 1 "$?"
    assert_contains "TP-GROK-CLI-15b multi-draft message" "$_err" "multiple drafts"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" remove-project-sudoers --force "${_draft_default}" 2>&1)
    assert_eq "TP-GROK-CLI-15b remove explicit path exit 0" 0 "$?"
    assert_file_missing "TP-GROK-CLI-15b explicit draft removed" "${_draft_default}"
    assert_file_exists "TP-GROK-CLI-15b legacy draft remains" "${CI_HOME}/.config/grok-cli/sudoers.fragment"
    assert_file_exists "TP-GROK-CLI-15b other draft remains" "${CI_HOME}/.config/grok-cli/sudoers.fragment-otheruser"

    # TP-GROK-CLI-22d submit refuses OS-tool grant
    _badgrant="${CI_HOME}/out/bad-os-tool.json"
    printf '%s\n' '{"commands":[{"path":"/usr/bin/mkdir","args":["-p","/var/grok-cli"]}]}' >"${_badgrant}"
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" submit-sudoer-request --allow-test-local "${_badgrant}" 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-22d refuse OS-tool grant exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-22d refuse message" "${_err}" "OS-tool"

    # TP-GROK-CLI-19 submit fail-closed when sudoer-cli missing
    _err=$(HOME="${CI_HOME}" SUDOER_CLI="${CI_HOME}/no-such-sudoer-cli" \
        sh "${SCRIPT}" submit-sudoer-request --allow-test-local 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-19 submit missing cli exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-19 missing sudoer-cli" "$_err" "sudoer-cli not found"

    # TP-GROK-CLI-20 submit via stub sudoer-cli
    _stub_dir="${CI_HOME}/stub-sudoer"
    mkdir -p "${_stub_dir}/bin" "${_stub_dir}/sudoer-approving"
    cat > "${_stub_dir}/bin/sudoer-cli" <<'STUB'
#!/bin/sh
_file=""
_svc=""
while [ $# -gt 0 ]; do
    case "$1" in
        --json) ;;
        --file) _file="$2"; shift ;;
        --purpose) shift ;;
        --service) _svc="$2"; shift ;;
        add-sudoer-request|update-sudoer-request) ;;
        *) ;;
    esac
    shift
done
[ -n "${_file}" ] && [ -f "${_file}" ] || exit 1
_id="sudoer-20260822-${_svc:-grok-cli}-stub-add-1.json"
_in="${LPU_HOME:-}/sudoer-approving"
[ -d "${_in}" ] || _in="${SUDOER_QUEUE_INBOUND:-}"
[ -d "${_in}" ] || exit 1
cp "${_file}" "${_in}/${_id}" || exit 1
printf 'request_id=%s\n' "${_id}"
exit 0
STUB
    chmod 0755 "${_stub_dir}/bin/sudoer-cli"
    _out=$(HOME="${CI_HOME}" \
        SUDOER_CLI="${_stub_dir}/bin/sudoer-cli" \
        SUDOER_ADM_USER="$(id -un)" \
        SUDOER_QUEUE_INBOUND="${_stub_dir}/sudoer-approving" \
        sh "${SCRIPT}" submit-sudoer-request --allow-test-local 2>&1)
    assert_eq "TP-GROK-CLI-20 submit stub exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-20 request_id" "$_out" "request_id="
    assert_contains "TP-GROK-CLI-20 default add when no host fragment" "$_out" "Submitted add"
    _njson=$(find "${_stub_dir}/sudoer-approving" -type f | wc -l | tr -d ' ')
    assert_eq "TP-GROK-CLI-20 inbound has file" 1 "${_njson}"
    _stub_body=$(cat "${_stub_dir}/sudoer-approving/"*.json 2>/dev/null || true)
    assert_contains "TP-GROK-CLI-22f stub inbound has backup" "${_stub_body}" '"backup"'
    assert_not_contains "TP-GROK-CLI-22f stub inbound no restore" "${_stub_body}" '"restore"'

    # TP-GROK-CLI-23 host fragment present → default action=update
    _user23=$(id -un)
    : "${CI_SUDOERS_D:=${CI_HOME}/sudoers.d}"
    mkdir -p "${CI_SUDOERS_D}"
    printf '# host fragment\n' > "${CI_SUDOERS_D}/grok-cli-${_user23}"
    _j23=$(HOME="${CI_HOME}" \
        SUDOER_CLI="${_stub_dir}/bin/sudoer-cli" \
        SUDOER_ADM_USER="$(id -un)" \
        SUDOER_QUEUE_INBOUND="${_stub_dir}/sudoer-approving" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        sh "${SCRIPT}" --json submit-sudoer-request --allow-test-local 2>/dev/null)
    assert_eq "TP-GROK-CLI-23 host present submit exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-23 action update" "${_j23}" '"action":"update"'
    assert_contains "TP-GROK-CLI-23 host present true" "${_j23}" '"host_fragment_present":"true"'
    _j23b=$(HOME="${CI_HOME}" \
        SUDOER_CLI="${_stub_dir}/bin/sudoer-cli" \
        SUDOER_ADM_USER="$(id -un)" \
        SUDOER_QUEUE_INBOUND="${_stub_dir}/sudoer-approving" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        sh "${SCRIPT}" --json submit-sudoer-request --add --allow-test-local 2>/dev/null)
    assert_eq "TP-GROK-CLI-23b --add override exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-23b forced add" "${_j23b}" '"action":"add"'
    rm -f "${CI_SUDOERS_D}/grok-cli-${_user23}"

    printf '# other user host fragment\n' > "${CI_SUDOERS_D}/grok-cli-otheruser"
    _j23c=$(HOME="${CI_HOME}" \
        SUDOER_CLI="${_stub_dir}/bin/sudoer-cli" \
        SUDOER_ADM_USER="$(id -un)" \
        SUDOER_QUEUE_INBOUND="${_stub_dir}/sudoer-approving" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        sh "${SCRIPT}" --json submit-sudoer-request --allow-test-local 2>/dev/null)
    assert_eq "TP-GROK-CLI-23c other-user submit exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-23c stays add" "${_j23c}" '"action":"add"'
    rm -f "${CI_SUDOERS_D}/grok-cli-otheruser"

    # TP-GROK-CLI-24 generate writes verified compact JSON (backup only)
    _user24=$(id -un)
    _gen_default="${CI_HOME}/.config/grok-cli/sudoer-request-${_user24}.json"
    _out24=$(HOME="${CI_HOME}" GLOBAL_BIN=/usr/local/bin sh "${SCRIPT}" generate-sudoer-request --allow-test-local 2>&1)
    assert_eq "TP-GROK-CLI-24 generate exit 0" 0 "$?"
    assert_file_exists "TP-GROK-CLI-24 default dest exists" "${_gen_default}"
    _gen_body=$(cat "${_gen_default}" 2>/dev/null || true)
    assert_contains "TP-GROK-CLI-24 has backup" "${_gen_body}" '"backup"'
    assert_not_contains "TP-GROK-CLI-24 no restore" "${_gen_body}" '"restore"'
    assert_contains "TP-GROK-CLI-24 human next submit" "${_out24}" "submit-sudoer-request"
    _gen_exp="${CI_HOME}/out/verified-grant.json"
    _out24b=$(HOME="${CI_HOME}" GLOBAL_BIN=/usr/local/bin sh "${SCRIPT}" generate-sudoer-request --allow-test-local "${_gen_exp}" 2>&1)
    assert_eq "TP-GROK-CLI-24b explicit path exit 0" 0 "$?"
    assert_file_exists "TP-GROK-CLI-24b explicit dest" "${_gen_exp}"
    _err24c=$(HOME="${CI_HOME}" sh "${SCRIPT}" generate-sudoer-request --allow-test-local /etc/sudoers.d/grok-cli-nope 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-24b refuse /etc exit 1" 1 "$?"
    if [ -r "${_gen_exp}" ]; then
        t_pass "TP-GROK-CLI-24d dest readable without sudo"
    else
        t_fail "TP-GROK-CLI-24d dest readable without sudo (not readable: ${_gen_exp})"
    fi
    if [ -n "${_srcli}" ] && [ -x "${_srcli}" ]; then
        _p24="${CI_HOME}/out/gen-convert.sudoers"
        HOME="${CI_HOME}" sh "${_srcli}" json-to-sudoers --file "${_gen_exp}" --out "${_p24}" >/dev/null 2>&1
        _c24ec=$?
        assert_eq "TP-GROK-CLI-24c convert exit 0" 0 "${_c24ec}"
        _c24=$(cat "${_p24}" 2>/dev/null || true)
        assert_contains "TP-GROK-CLI-24c convert backup" "${_c24}" "grok-cli backup"
    fi

    # TP-GROK-CLI-25 operator-readable inbound-fidelity error (no backup in queued body)
    _stub25="${CI_HOME}/stub-drop"
    mkdir -p "${_stub25}/bin" "${_stub25}/sudoer-approving"
    cat > "${_stub25}/bin/sudoer-cli" <<'STUB25'
#!/bin/sh
_file=""
_svc=""
while [ $# -gt 0 ]; do
    case "$1" in
        --json) ;;
        --file) _file="$2"; shift ;;
        --purpose) shift ;;
        --service) _svc="$2"; shift ;;
        add-sudoer-request|update-sudoer-request) ;;
        *) ;;
    esac
    shift
done
[ -n "${_file}" ] && [ -f "${_file}" ] || exit 1
_id="sudoer-20260822-${_svc:-grok-cli}-stub-drop-1.json"
_in="${LPU_HOME:-}/sudoer-approving"
[ -d "${_in}" ] || _in="${SUDOER_QUEUE_INBOUND:-}"
[ -d "${_in}" ] || exit 1
printf '%s\n' '{"purpose":"grant","commands":[{"args":["sync-auth"]}]}' >"${_in}/${_id}" || exit 1
printf 'request_id=%s\n' "${_id}"
exit 0
STUB25
    chmod 0755 "${_stub25}/bin/sudoer-cli"
    _err25=$(HOME="${CI_HOME}" \
        SUDOER_CLI="${_stub25}/bin/sudoer-cli" \
        SUDOER_ADM_USER="$(id -un)" \
        SUDOER_QUEUE_INBOUND="${_stub25}/sudoer-approving" \
        sh "${SCRIPT}" submit-sudoer-request --allow-test-local 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-25 inbound incomplete exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-25 what happened" "${_err25}" "incomplete"
    assert_contains "TP-GROK-CLI-25b next generate" "${_err25}" "generate-sudoer-request"
    assert_not_contains "TP-GROK-CLI-25c no sibling jargon" "${_err25}" "sibling re-encode"

    # TP-GROK-CLI-21 public inbound preferred
    _pub21="${CI_HOME}/var-sudoer-cli"
    mkdir -p "${_pub21}/sudoer-request" "${CI_HOME}/sudoer-approving"
    _j21=$(HOME="${CI_HOME}" \
        SUDOER_PUBLIC_ROOT="${_pub21}" \
        SUDOER_ADM_USER="$(id -un)" \
        SUDOER_QUEUE_INBOUND="" \
        sh "${SCRIPT}" --json about 2>/dev/null)
    assert_contains "TP-GROK-CLI-21 about prefers public inbound" "${_j21}" "${_pub21}/sudoer-request"
    assert_not_contains "TP-GROK-CLI-21 not leftover approving" "${_j21}" "${CI_HOME}/sudoer-approving"
    _missing21="${CI_HOME}/var-sudoer-cli-absent"
    _j21b=$(HOME="${CI_HOME}" \
        SUDOER_PUBLIC_ROOT="${_missing21}" \
        SUDOER_ADM_USER="no-such-sudoer-adm-gc21" \
        SUDOER_QUEUE_INBOUND="" \
        sh "${SCRIPT}" --json about 2>/dev/null)
    assert_contains "TP-GROK-CLI-21 missing public is not_found" "${_j21b}" '"sudoer_inbound":"not_found"'
    assert_file_missing "TP-GROK-CLI-21 no Type 0 mkdir public inbound" "${_missing21}/sudoer-request"
    _env21="${CI_HOME}/env-inbound"
    mkdir -p "${_env21}"
    _j21c=$(HOME="${CI_HOME}" \
        SUDOER_PUBLIC_ROOT="${_pub21}" \
        SUDOER_QUEUE_INBOUND="${_env21}" \
        SUDOER_ADM_USER="$(id -un)" \
        sh "${SCRIPT}" --json about 2>/dev/null)
    assert_contains "TP-GROK-CLI-21b env inbound wins" "${_j21c}" "${_env21}"

    HOME="${CI_HOME}" sh "${SCRIPT}" remove-project-sudoers --force "${CI_HOME}/.config/grok-cli/sudoers.fragment" >/dev/null 2>&1 || true
    HOME="${CI_HOME}" sh "${SCRIPT}" remove-project-sudoers --force "${CI_HOME}/.config/grok-cli/sudoers.fragment-otheruser" >/dev/null 2>&1 || true

    # TP-GROK-CLI-26..29 add-crontab (isolated fake crontab; never the operator crontab)
    : "${CI_SUDOERS_D:=${CI_HOME}/sudoers.d}"
    mkdir -p "${CI_SUDOERS_D}" "${CI_HOME}/bin" "${CI_GLOBAL_BIN}"
    _user_cron=$(id -un)
    rm -f "${CI_SUDOERS_D}/grok-cli-${_user_cron}" "${CI_GLOBAL_BIN}/grok-cli"
    printf '#!/bin/sh\nexit 0\n' > "${CI_GLOBAL_BIN}/grok-cli"
    chmod 0755 "${CI_GLOBAL_BIN}/grok-cli"
    _fake_cron="${CI_HOME}/bin/crontab"
    _cron_store="${CI_HOME}/crontab.txt"
    cat > "${_fake_cron}" <<'FAKECRON'
#!/bin/sh
store="${GROK_CLI_CRONTAB_FILE:-}"
[ -n "${store}" ] || exit 1
if [ "${1:-}" = "-l" ]; then
    if [ -f "${store}" ]; then
        cat "${store}"
        exit 0
    fi
    echo "no crontab for test" >&2
    exit 1
fi
if [ "${1:-}" = "-" ]; then
    cat > "${store}"
    exit 0
fi
if [ -n "${1:-}" ] && [ -f "$1" ]; then
    cat "$1" > "${store}"
    exit 0
fi
exit 1
FAKECRON
    chmod 0755 "${_fake_cron}"
    rm -f "${_cron_store}"

    _err=$(HOME="${CI_HOME}" \
        GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        GROK_CLI_CRONTAB="${_fake_cron}" \
        GROK_CLI_CRONTAB_FILE="${_cron_store}" \
        sh "${SCRIPT}" add-crontab 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-26 no grant exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-26 next generate" "${_err}" "generate-sudoer-request"

    printf 'otheruser ALL=(root) NOPASSWD: %s/grok-cli backup\n' "${CI_GLOBAL_BIN}" \
        > "${CI_SUDOERS_D}/grok-cli-${_user_cron}"
    _err=$(HOME="${CI_HOME}" \
        GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        GROK_CLI_CRONTAB="${_fake_cron}" \
        GROK_CLI_CRONTAB_FILE="${_cron_store}" \
        sh "${SCRIPT}" add-crontab 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-26b wrong-user fragment exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-26b next generate" "${_err}" "generate-sudoer-request"

    printf '%s ALL=(root) NOPASSWD: %s/grok-cli restore\n' "${_user_cron}" "${CI_GLOBAL_BIN}" \
        > "${CI_SUDOERS_D}/grok-cli-${_user_cron}"
    _err=$(HOME="${CI_HOME}" \
        GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        GROK_CLI_CRONTAB="${_fake_cron}" \
        GROK_CLI_CRONTAB_FILE="${_cron_store}" \
        sh "${SCRIPT}" add-crontab 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-26b wrong-argv fragment exit 1" 1 "$?"

    printf '%s ALL=(root) NOPASSWD: %s/grok-cli backup\n' "${_user_cron}" "${CI_GLOBAL_BIN}" \
        > "${CI_SUDOERS_D}/grok-cli-otheruser"
    rm -f "${CI_SUDOERS_D}/grok-cli-${_user_cron}"
    _err=$(HOME="${CI_HOME}" \
        GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        GROK_CLI_CRONTAB="${_fake_cron}" \
        GROK_CLI_CRONTAB_FILE="${_cron_store}" \
        sh "${SCRIPT}" add-crontab 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-26b sibling fragment does not count exit 1" 1 "$?"
    rm -f "${CI_SUDOERS_D}/grok-cli-otheruser"

    rm -f "${CI_GLOBAL_BIN}/grok-cli"
    printf '%s ALL=(root) NOPASSWD: %s/grok-cli backup\n' "${_user_cron}" "${CI_GLOBAL_BIN}" \
        > "${CI_SUDOERS_D}/grok-cli-${_user_cron}"
    _err=$(HOME="${CI_HOME}" \
        GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        GROK_CLI_CRONTAB="${_fake_cron}" \
        GROK_CLI_CRONTAB_FILE="${_cron_store}" \
        sh "${SCRIPT}" add-crontab 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-27 missing global binary exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-27 next install" "${_err}" "install"

    printf '#!/bin/sh\nexit 0\n' > "${CI_GLOBAL_BIN}/grok-cli"
    chmod 0755 "${CI_GLOBAL_BIN}/grok-cli"
    printf '# keep me\n0 3 * * * /usr/bin/true\n' > "${_cron_store}"
    _out=$(HOME="${CI_HOME}" \
        GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        GROK_CLI_CRONTAB="${_fake_cron}" \
        GROK_CLI_CRONTAB_FILE="${_cron_store}" \
        sh "${SCRIPT}" add-crontab 2>/dev/null)
    assert_eq "TP-GROK-CLI-28 add-crontab exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-28 complete" "${_out}" "add-crontab complete"
    _body=$(cat "${_cron_store}")
    assert_contains "TP-GROK-CLI-28 backup job" "${_body}" "sudo ${CI_GLOBAL_BIN}/grok-cli backup"
    assert_contains "TP-GROK-CLI-28 sync job" "${_body}" "${CI_GLOBAL_BIN}/grok-cli sync-auth"
    assert_contains "TP-GROK-CLI-28 schedule backup" "${_body}" "*/30 * * * * sudo "
    assert_contains "TP-GROK-CLI-28 schedule sync" "${_body}" "45 * * * * ${CI_GLOBAL_BIN}/grok-cli sync-auth"
    assert_not_contains "TP-GROK-CLI-28b jobs have no sudo on sync-auth line pair" "${_body}" "sudo ${CI_GLOBAL_BIN}/grok-cli sync-auth"
    assert_contains "TP-GROK-CLI-29b preserves other jobs" "${_body}" "/usr/bin/true"
    _n_backup=$(printf '%s\n' "${_body}" | grep -c "sudo ${CI_GLOBAL_BIN}/grok-cli backup" || true)
    _n_sync=$(printf '%s\n' "${_body}" | grep -c "${CI_GLOBAL_BIN}/grok-cli sync-auth" || true)
    assert_eq "TP-GROK-CLI-28 one backup line" "1" "${_n_backup}"
    assert_eq "TP-GROK-CLI-28 one sync line" "1" "${_n_sync}"

    _out=$(HOME="${CI_HOME}" \
        GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        GROK_CLI_CRONTAB="${_fake_cron}" \
        GROK_CLI_CRONTAB_FILE="${_cron_store}" \
        sh "${SCRIPT}" add-crontab 2>/dev/null)
    assert_eq "TP-GROK-CLI-29 re-run exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-29 already present" "${_out}" "already present"
    _body2=$(cat "${_cron_store}")
    _n_backup2=$(printf '%s\n' "${_body2}" | grep -c "sudo ${CI_GLOBAL_BIN}/grok-cli backup" || true)
    _n_sync2=$(printf '%s\n' "${_body2}" | grep -c "${CI_GLOBAL_BIN}/grok-cli sync-auth" || true)
    assert_eq "TP-GROK-CLI-29 no duplicate backup" "1" "${_n_backup2}"
    assert_eq "TP-GROK-CLI-29 no duplicate sync" "1" "${_n_sync2}"

    _j=$(HOME="${CI_HOME}" \
        GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        GROK_CLI_CRONTAB="${_fake_cron}" \
        GROK_CLI_CRONTAB_FILE="${_cron_store}" \
        sh "${SCRIPT}" --json add-crontab 2>/dev/null)
    assert_contains "TP-GROK-CLI-29 json type" "${_j}" '"type":"add-crontab"'
    assert_contains "TP-GROK-CLI-29 json already" "${_j}" '"already_present":"true"'
    assert_contains "TP-GROK-CLI-28b json user is id -un" "${_j}" "\"user\":\"${_user_cron}\""

    rm -f "${CI_SUDOERS_D}/grok-cli-${_user_cron}" "${_cron_store}" "${CI_GLOBAL_BIN}/grok-cli"

    # TP-GROK-CLI-30..34 sync-auth-from-remote (isolated fake scp; never real SSH)
    # Logged-out dest: drop fake grok so the live probe is not valid.
    unset GROK_BIN 2>/dev/null || true
    rm -f "${CI_USER_BIN}/grok" "${CI_GLOBAL_BIN}/grok" "${CI_HOME}/.grok/bin/grok"
    mkdir -p "${CI_HOME}/bin" "${CI_HOME}/remote-store"
    gc_write_valid_auth "${CI_HOME}/remote-store"
    printf 'lock\n' > "${CI_HOME}/remote-store/auth.json.lock"
    _fake_scp="${CI_HOME}/bin/scp"
    _scp_log="${CI_HOME}/scp.log"
    : > "${_scp_log}"
    cat > "${_fake_scp}" <<'FAKESCP'
#!/bin/sh
fix="${GROK_CLI_REMOTE_FIXTURE:-}"
log="${GROK_CLI_SCP_LOG:-}"
while [ $# -gt 0 ]; do
    case "$1" in
        -o) shift 2; continue ;;
        -*) shift; continue ;;
        *) break ;;
    esac
done
src="${1:-}"
dest="${2:-}"
[ -n "${src}" ] && [ -n "${dest}" ] || exit 1
if [ -n "${log}" ]; then
    printf '%s\n' "${src}" >> "${log}"
fi
base="${src##*:}"
base="${base##*/}"
if [ -z "${fix}" ] || [ ! -f "${fix}/${base}" ]; then
    exit 1
fi
cp "${fix}/${base}" "${dest}" || exit 1
exit 0
FAKESCP
    chmod 0755 "${_fake_scp}"

    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-remote" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        GROK_CLI_SCP_LOG="${_scp_log}" \
        sh "${SCRIPT}" sync-auth-from-remote 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-30 missing spec exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-30 next SPEC" "${_err}" "sync-auth-from-remote USER@HOST"

    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-remote" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        sh "${SCRIPT}" sync-auth-from-remote 'bad;rm' 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-30b invalid spec exit 1" 1 "$?"

    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-remote" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        sh "${SCRIPT}" sync-auth-from-remote 'a@b@c' 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-30b extra @ exit 1" 1 "$?"

    : > "${_scp_log}"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-ip" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        GROK_CLI_SCP_LOG="${_scp_log}" GROK_CLI_REMOTE_ROOT="/var/grok-cli" \
        sh "${SCRIPT}" sync-auth-from-remote 192.0.2.10 2>/dev/null)
    assert_eq "TP-GROK-CLI-31 IPv4 exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-31 complete" "${_out}" "sync-auth-from-remote complete"
    assert_file_exists "TP-GROK-CLI-31 dest auth.json" "${CI_HOME}/.grok-ip/auth.json"
    assert_contains "TP-GROK-CLI-31 IPv4 scp src" "$(cat "${_scp_log}")" "192.0.2.10:/var/grok-cli/auth.json"
    _mode=$(stat -c '%a' "${CI_HOME}/.grok-ip/auth.json" 2>/dev/null || stat -f '%OLp' "${CI_HOME}/.grok-ip/auth.json" 2>/dev/null || echo "")
    assert_eq "TP-GROK-CLI-32 dest auth.json mode 0600" "600" "${_mode}"
    assert_contains "TP-GROK-CLI-31 dest token" "$(cat "${CI_HOME}/.grok-ip/auth.json")" "test-refresh-token"

    : > "${_scp_log}"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-userip" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        GROK_CLI_SCP_LOG="${_scp_log}" GROK_CLI_REMOTE_ROOT="/var/grok-cli" \
        sh "${SCRIPT}" sync-auth-from-remote operator@192.0.2.10 2>/dev/null)
    assert_eq "TP-GROK-CLI-31b user@IPv4 exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-31b scp src" "$(cat "${_scp_log}")" "operator@192.0.2.10:/var/grok-cli/auth.json"

    : > "${_scp_log}"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-dom" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        GROK_CLI_SCP_LOG="${_scp_log}" GROK_CLI_REMOTE_ROOT="/var/grok-cli" \
        sh "${SCRIPT}" sync-auth-from-remote host.example.com 2>/dev/null)
    assert_eq "TP-GROK-CLI-31c domain exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-31c scp src" "$(cat "${_scp_log}")" "host.example.com:/var/grok-cli/auth.json"

    : > "${_scp_log}"
    _j=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-udom" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        GROK_CLI_SCP_LOG="${_scp_log}" GROK_CLI_REMOTE_ROOT="/var/grok-cli" \
        sh "${SCRIPT}" --json sync-auth-from-remote operator@host.example.com 2>/dev/null)
    assert_eq "TP-GROK-CLI-31d user@domain exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-31d json type" "${_j}" '"type":"sync-auth-from-remote"'
    assert_contains "TP-GROK-CLI-31d json host" "${_j}" '"host":"host.example.com"'
    assert_contains "TP-GROK-CLI-31d json user" "${_j}" '"user":"operator"'
    assert_contains "TP-GROK-CLI-31d scp src" "$(cat "${_scp_log}")" "operator@host.example.com:/var/grok-cli/auth.json"
    assert_not_contains "TP-GROK-CLI-31d json no token" "${_j}" "test-refresh-token"

    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-miss" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/empty-remote" \
        sh "${SCRIPT}" sync-auth-from-remote 192.0.2.10 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-33 missing remote auth exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-33 next ssh or backup" "${_err}" "Next:"

    # TP-GROK-CLI-34: TTY menu pick 3 (sync-auth-from-remote) must show the SPEC prompt (INC-20260902-001).
    # Fake scp only; never real SSH. Kill the child if it still hangs after timeout.
    # Clear preferred-remote so this case proves the prompt without a stored default.
    rm -f "${CI_HOME}/.local/grok-cli/preferred-remote"
    if command -v python3 >/dev/null 2>&1; then
        _pty_out=$(
            HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-menu-remote" \
            GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
            GROK_CLI_REMOTE_ROOT="/var/grok-cli" \
            PTY_IN="3
192.0.2.10
" python3 - "${SCRIPT}" menu <<'PY'
import os, pty, select, signal, sys, time
script = sys.argv[1]
cmd = sys.argv[2:]
payload = os.environ.get("PTY_IN", "9\n").encode()
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
        )
        assert_contains "TP-GROK-CLI-34 menu pick 3 shows SPEC prompt" "${_pty_out}" \
            "Remote (user@host, IPv4, domain, or user@domain):"
        assert_contains "TP-GROK-CLI-34 menu pick 3 completes" "${_pty_out}" \
            "sync-auth-from-remote complete"
        assert_not_contains "TP-GROK-CLI-34 SPEC not mixed with prompt text" "${_pty_out}" \
            "is not user@host"
        assert_file_exists "TP-GROK-CLI-34 dest auth.json" "${CI_HOME}/.grok-menu-remote/auth.json"
    else
        t_skip "TP-GROK-CLI-34 (python3 not available for PTY)"
    fi

    # TP-GROK-CLI-41: successful pull saves preferred SPEC; TTY prompt shows it
    # at the end as [default]; empty Enter uses that default.
    : > "${_scp_log}"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-pref" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        GROK_CLI_SCP_LOG="${_scp_log}" GROK_CLI_REMOTE_ROOT="/var/grok-cli" \
        sh "${SCRIPT}" sync-auth-from-remote operator@192.0.2.10 2>/dev/null)
    assert_eq "TP-GROK-CLI-41 save after success exit 0" 0 "$?"
    _pref="${CI_HOME}/.local/grok-cli/preferred-remote"
    assert_file_exists "TP-GROK-CLI-41 preferred-remote leaf" "${_pref}"
    assert_eq "TP-GROK-CLI-41 stored SPEC" "operator@192.0.2.10" "$(tr -d '\r\n' < "${_pref}")"
    _pmode=$(stat -c '%a' "${_pref}" 2>/dev/null || stat -f '%OLp' "${_pref}" 2>/dev/null || echo "")
    assert_eq "TP-GROK-CLI-41 preferred-remote mode 0600" "600" "${_pmode}"
    case "${_pref}" in
        */.local/grok-cli/preferred-remote) t_pass "TP-GROK-CLI-41 leaf is under persistence" ;;
        *) t_fail "TP-GROK-CLI-41 leaf not under persistence: ${_pref}" ;;
    esac
    if command -v python3 >/dev/null 2>&1; then
        : > "${_scp_log}"
        _pty_out=$(
            HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok-pref-tty" \
            GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
            GROK_CLI_SCP_LOG="${_scp_log}" GROK_CLI_REMOTE_ROOT="/var/grok-cli" \
            PTY_IN="3

" python3 - "${SCRIPT}" menu <<'PY'
import os, pty, select, signal, sys, time
script = sys.argv[1]
cmd = sys.argv[2:]
payload = os.environ.get("PTY_IN", "9\n").encode()
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
        )
        assert_contains "TP-GROK-CLI-41 TTY prompt shows stored default at end" "${_pty_out}" \
            "Remote (user@host, IPv4, domain, or user@domain) [operator@192.0.2.10]:"
        assert_contains "TP-GROK-CLI-41 empty Enter uses stored SPEC" "${_pty_out}" \
            "sync-auth-from-remote complete"
        assert_contains "TP-GROK-CLI-41 empty Enter scp src" "$(cat "${_scp_log}")" \
            "operator@192.0.2.10:/var/grok-cli/auth.json"
        assert_file_exists "TP-GROK-CLI-41 dest from default" "${CI_HOME}/.grok-pref-tty/auth.json"
    else
        t_skip "TP-GROK-CLI-41 TTY default prompt (python3 not available for PTY)"
    fi

    # TP-GROK-CLI-42 sync-auth skips when grok is already logged in
    ci_fake_grok_ok
    _keep="${CI_HOME}/keep-grok"
    gc_write_valid_auth "${_keep}"
    _keep_body=$(cat "${_keep}/auth.json")
    _out=$(HOME="${CI_HOME}" GROK_HOME="${_keep}" GROK_BIN="${GROK_BIN}" \
        GROK_CLI_ROOT="${_store}" sh "${SCRIPT}" sync-auth 2>&1)
    assert_eq "TP-GROK-CLI-42 logged-in skip exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-42 skip message" "$_out" \
        "No sync-auth for logged-in environment."
    assert_not_contains "TP-GROK-CLI-42 did not copy" "$_out" "sync-auth complete"
    assert_eq "TP-GROK-CLI-42 dest unchanged" "${_keep_body}" "$(cat "${_keep}/auth.json")"
    _j=$(HOME="${CI_HOME}" GROK_HOME="${_keep}" GROK_BIN="${GROK_BIN}" \
        GROK_CLI_ROOT="${_store}" sh "${SCRIPT}" --json sync-auth 2>/dev/null)
    assert_contains "TP-GROK-CLI-42 json type" "${_j}" '"type":"sync-auth"'
    assert_contains "TP-GROK-CLI-42 json skipped" "${_j}" '"status":"skipped"'
    assert_contains "TP-GROK-CLI-42 json reason" "${_j}" '"reason":"logged-in"'
    if command -v python3 >/dev/null 2>&1; then
        _pty_out=$(HOME="${CI_HOME}" GROK_HOME="${_keep}" GROK_BIN="${GROK_BIN}" \
            GROK_CLI_ROOT="${_store}" PTY_IN="9" ci_pty_capture "${SCRIPT}" menu)
        assert_contains "TP-GROK-CLI-42 menu logged in" "${_pty_out}" "logged in"
        assert_contains "TP-GROK-CLI-42 menu hides sync-auth" "${_pty_out}" \
            "sync-auth and sync-auth-from-remote features are not available for logged-in environment."
        assert_not_contains "TP-GROK-CLI-42 menu no sync-auth row" "${_pty_out}" "sync-auth:"
        assert_not_contains "TP-GROK-CLI-42 menu did not copy" "${_pty_out}" "sync-auth complete"
    else
        t_skip "TP-GROK-CLI-42 menu skip (python3 not available for PTY)"
    fi

    # TP-GROK-CLI-43 sync-auth-from-remote skips when grok is already logged in
    : > "${_scp_log}"
    _keep2="${CI_HOME}/keep-grok-remote"
    mkdir -p "${_keep2}"
    printf 'keep-remote\n' > "${_keep2}/auth.json"
    chmod 0600 "${_keep2}/auth.json"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${_keep2}" GROK_BIN="${GROK_BIN}" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        GROK_CLI_SCP_LOG="${_scp_log}" GROK_CLI_REMOTE_ROOT="/var/grok-cli" \
        sh "${SCRIPT}" sync-auth-from-remote operator@192.0.2.10 2>&1)
    assert_eq "TP-GROK-CLI-43 logged-in skip exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-43 skip message" "$_out" \
        "No sync-auth for logged-in environment."
    assert_not_contains "TP-GROK-CLI-43 did not copy" "$_out" "sync-auth-from-remote complete"
    assert_eq "TP-GROK-CLI-43 dest unchanged" "keep-remote" "$(tr -d '\r\n' < "${_keep2}/auth.json")"
    assert_eq "TP-GROK-CLI-43 no scp" "" "$(cat "${_scp_log}")"
    _j=$(HOME="${CI_HOME}" GROK_HOME="${_keep2}" GROK_BIN="${GROK_BIN}" \
        GROK_CLI_SCP="${_fake_scp}" GROK_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        GROK_CLI_SCP_LOG="${_scp_log}" GROK_CLI_REMOTE_ROOT="/var/grok-cli" \
        sh "${SCRIPT}" --json sync-auth-from-remote operator@192.0.2.10 2>/dev/null)
    assert_contains "TP-GROK-CLI-43 json type" "${_j}" '"type":"sync-auth-from-remote"'
    assert_contains "TP-GROK-CLI-43 json skipped" "${_j}" '"status":"skipped"'
    assert_contains "TP-GROK-CLI-43 json reason" "${_j}" '"reason":"logged-in"'

    # TP-GROK-CLI-35 live probe wins over expired auth.json
    gc_write_expired_auth "${CI_HOME}/.grok"
    ci_fake_grok_ok
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        sh "${SCRIPT}" check-session 2>&1)
    assert_eq "TP-GROK-CLI-35 expired file + probe ok exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-35 probe text" "$_out" "grok -p hello"

    # TP-GROK-CLI-36 probe stdout is not printed (no token/answer leak)
    _tokfake="${CI_USER_BIN}/grok-secret"
    mkdir -p "${CI_USER_BIN}"
    cat > "${_tokfake}" <<'FAKE'
#!/bin/sh
echo "secret-token-must-not-leak"
echo "refresh_token=leak-me" >&2
exit 0
FAKE
    chmod +x "${_tokfake}"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${_tokfake}" \
        sh "${SCRIPT}" check-session 2>&1)
    assert_eq "TP-GROK-CLI-36 leak-fake exit 0" 0 "$?"
    assert_not_contains "TP-GROK-CLI-36 no stdout leak" "$_out" "secret-token-must-not-leak"
    assert_not_contains "TP-GROK-CLI-36 no stderr token leak" "$_out" "refresh_token=leak-me"

    # TP-GROK-CLI-37 Core tests never need public network (fake GROK_BIN)
    ci_fake_grok_ok
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        sh "${SCRIPT}" check-session 2>&1)
    assert_eq "TP-GROK-CLI-37 fake grok no network exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-37 used probe" "$_out" "grok -p hello"

    # TP-GROK-CLI-38 probe runs before auth.json: missing grok does not parse-succeed
    unset GROK_BIN 2>/dev/null || true
    rm -f "${CI_USER_BIN}/grok" "${CI_HOME}/.grok/bin/grok" "${CI_GLOBAL_BIN}/grok"
    gc_write_valid_auth "${CI_HOME}/.grok"
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" env -u GROK_BIN \
        sh "${SCRIPT}" check-session 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-38 valid file without grok exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-38 not installed" "$_err" "not installed"

    # TP-GROK-CLI-39 elevated probe (uid 0 + SUDO_USER) uses invoking grok home, not /root
    if ! command -v getent >/dev/null 2>&1; then
        t_skip "TP-GROK-CLI-39 (getent not available to fake SUDO_USER home)"
    else
        _real_id=$(PATH="${CI_PATH_ORIG:-$PATH}" command -v id)
        _real_getent=$(PATH="${CI_PATH_ORIG:-$PATH}" command -v getent)
        _fakebin="${CI_HOME}/fake-root-bin"
        mkdir -p "${_fakebin}"
        cat > "${_fakebin}/id" <<FAKEID
#!/bin/sh
case "\${1:-}" in
  -u) printf '0\\n'; exit 0 ;;
  -un) printf 'root\\n'; exit 0 ;;
esac
exec ${_real_id} "\$@"
FAKEID
        cat > "${_fakebin}/getent" <<FAKEGETENT
#!/bin/sh
if [ "\${1:-}" = "passwd" ] && [ -n "\${2:-}" ] && [ "\${2}" = "\${FAKE_PASSWD_USER:-}" ]; then
    printf '%s:x:1000:1000::%s:/bin/sh\\n' "\$2" "\${FAKE_PASSWD_HOME}"
    exit 0
fi
exec ${_real_getent} "\$@"
FAKEGETENT
        chmod 0755 "${_fakebin}/id" "${_fakebin}/getent"
        _probegrok="${CI_HOME}/probe-home-grok"
        _envlog="${CI_HOME}/probe-env.log"
        cat > "${_probegrok}" <<'FAKEGROK'
#!/bin/sh
if [ -n "${GROK_PROBE_ENV_LOG:-}" ]; then
    printf 'HOME=%s\nGROK_HOME=%s\n' "${HOME}" "${GROK_HOME:-}" > "${GROK_PROBE_ENV_LOG}"
fi
_h="${GROK_HOME:-${HOME}/.grok}"
if [ "${1:-}" = "-p" ]; then
    if [ -f "${_h}/auth.json" ]; then
        echo ok
        exit 0
    fi
    echo "login required" >&2
    exit 1
fi
exit 0
FAKEGROK
        chmod 0755 "${_probegrok}"
        gc_write_valid_auth "${CI_HOME}/.grok"
        _rootish="${CI_HOME}/as-root"
        mkdir -p "${_rootish}"
        _store39="${CI_HOME}/var-grok-cli-39"
        mkdir -p "${_store39}"
        rm -f "${_envlog}"
        _out=$(HOME="${_rootish}" \
            SUDO_USER="cli-sudo-user" \
            FAKE_PASSWD_USER="cli-sudo-user" \
            FAKE_PASSWD_HOME="${CI_HOME}" \
            GROK_BIN="${_probegrok}" \
            GROK_PROBE_ENV_LOG="${_envlog}" \
            GROK_CLI_ROOT="${_store39}" \
            PATH="${_fakebin}:${PATH}" \
            env -u GROK_HOME \
            sh "${SCRIPT}" backup 2>&1)
        _ec=$?
        assert_eq "TP-GROK-CLI-39 elevated backup exit 0" 0 "${_ec}"
        assert_contains "TP-GROK-CLI-39 backup complete" "${_out}" "Backup complete"
        assert_file_exists "TP-GROK-CLI-39 dest auth.json" "${_store39}/auth.json"
        _plog=$(cat "${_envlog}" 2>/dev/null || true)
        assert_contains "TP-GROK-CLI-39 probe HOME is invoking home" "${_plog}" "HOME=${CI_HOME}"
        assert_contains "TP-GROK-CLI-39 probe GROK_HOME is invoking grok home" "${_plog}" "GROK_HOME=${CI_HOME}/.grok"
        assert_not_contains "TP-GROK-CLI-39 probe HOME is not as-root" "${_plog}" "HOME=${_rootish}"
        unset SUDO_USER FAKE_PASSWD_USER FAKE_PASSWD_HOME GROK_PROBE_ENV_LOG 2>/dev/null || true
    fi

    # TP-GROK-CLI-40 grant present + elevated child fail is not "sudo refused"
    _user40=$(id -un 2>/dev/null || echo "unknown")
    mkdir -p "${CI_SUDOERS_D}" "${CI_GLOBAL_BIN}" "${CI_HOME}/bin"
    printf '%s ALL=(root) NOPASSWD: %s/grok-cli backup\n' "${_user40}" "${CI_GLOBAL_BIN}" \
        > "${CI_SUDOERS_D}/grok-cli-${_user40}"
    printf '#!/bin/sh\nexit 0\n' > "${CI_GLOBAL_BIN}/grok-cli"
    chmod 0755 "${CI_GLOBAL_BIN}/grok-cli"
    cat > "${CI_HOME}/bin/sudo" <<'FAKESUDO'
#!/bin/sh
while [ "${1:-}" = "-n" ]; do
    shift
done
echo "Cannot backup: grok is not logged in (exit 1: login required). Next: grok login, then grok-cli backup." >&2
exit 1
FAKESUDO
    chmod 0755 "${CI_HOME}/bin/sudo"
    gc_write_valid_auth "${CI_HOME}/.grok"
    ci_fake_grok_ok
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        GROK_CLI_ROOT=/var/grok-cli \
        GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SUDOERS_D_DIR="${CI_SUDOERS_D}" \
        PATH="${CI_HOME}/bin:${PATH}" \
        sh "${SCRIPT}" backup 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-40 grant-present child fail exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-40 grant already in place" "${_err}" "already in place"
    assert_contains "TP-GROK-CLI-40 next grok login" "${_err}" "grok login"
    assert_not_contains "TP-GROK-CLI-40 not generate-sudoer-request" "${_err}" "generate-sudoer-request"
    rm -f "${CI_HOME}/bin/sudo" "${CI_SUDOERS_D}/grok-cli-${_user40}" "${CI_GLOBAL_BIN}/grok-cli"

    # TP-GROK-CLI-44 hanging grok that ignores SIGTERM still fail-closes
    # (GNU timeout -k / watchdog). Outer timeout keeps the suite from freezing
    # if the product bound is missing.
    ci_fake_grok_hang
    gc_write_valid_auth "${CI_HOME}/.grok"
    _start=$(date +%s)
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        GROK_PROMPT_TIMEOUT=1 GROK_PROMPT_KILL_AFTER=1 \
        timeout 12 sh "${SCRIPT}" check-session 2>&1 >/dev/null)
    _ec=$?
    _elapsed=$(($(date +%s) - _start))
    assert_eq "TP-GROK-CLI-44 hang grok check-session exit 1" 1 "${_ec}"
    assert_contains "TP-GROK-CLI-44 not logged in" "${_err}" "not logged in"
    assert_contains "TP-GROK-CLI-44 probe timed out" "${_err}" "timed out"
    assert_contains "TP-GROK-CLI-44 next grok login" "${_err}" "grok login"
    if [ "${_elapsed}" -lt 12 ]; then
        t_pass "TP-GROK-CLI-44 hang grok did not freeze (${_elapsed}s)"
    else
        t_fail "TP-GROK-CLI-44 hang grok froze for ${_elapsed}s"
    fi

    # TP-GROK-CLI-45 same hang without GNU timeout -k (POSIX watchdog).
    # Stub timeout is on the child's PATH; the suite guard must be GNU timeout
    # resolved before the stub is written (ci PATH puts USER_BIN first).
    _gnu_timeout=$(PATH="/usr/bin:/bin" command -v timeout)
    if [ -z "${_gnu_timeout}" ] || [ ! -x "${_gnu_timeout}" ]; then
        t_skip "TP-GROK-CLI-45 no GNU timeout for suite guard"
    else
        _stubto="${CI_USER_BIN}/timeout"
        printf '#!/bin/sh\nexit 2\n' > "${_stubto}"
        chmod 0755 "${_stubto}"
        _start=$(date +%s)
        _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
            GROK_PROMPT_TIMEOUT=1 GROK_PROMPT_KILL_AFTER=1 \
            PATH="${CI_USER_BIN}:${CI_GLOBAL_BIN}:/usr/bin:/bin" \
            "${_gnu_timeout}" 12 sh "${SCRIPT}" check-session 2>&1 >/dev/null)
        _ec=$?
        _elapsed=$(($(date +%s) - _start))
        assert_eq "TP-GROK-CLI-45 watchdog hang grok exit 1" 1 "${_ec}"
        assert_contains "TP-GROK-CLI-45 not logged in" "${_err}" "not logged in"
        assert_contains "TP-GROK-CLI-45 probe timed out" "${_err}" "timed out"
        if [ "${_elapsed}" -lt 12 ]; then
            t_pass "TP-GROK-CLI-45 watchdog did not freeze (${_elapsed}s)"
        else
            t_fail "TP-GROK-CLI-45 watchdog froze for ${_elapsed}s"
        fi
        rm -f "${_stubto}"
    fi

    ci_cleanup_env

    # TP-GROK-CLI-46 run starts grok with --no-auto-update
    ci_isolated_env
    _log="${CI_HOME}/grok-run.log"
    cat > "${CI_USER_BIN}/grok" <<'EOS'
#!/bin/sh
printf 'ARGS'
for _a in "$@"; do
    printf ' %s' "${_a}"
done
printf '\n'
exit 0
EOS
    chmod +x "${CI_USER_BIN}/grok"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GROK_BIN="${CI_USER_BIN}/grok" \
            PATH="${CI_USER_BIN}:${CI_GLOBAL_BIN}:/usr/bin:/bin" \
            sh "${SCRIPT}" run 2>/dev/null
    )
    _ec=$?
    assert_eq "TP-GROK-CLI-46 run exit 0" 0 "${_ec}"
    assert_contains "TP-GROK-CLI-46 injects --no-auto-update" "${_out}" "--no-auto-update"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GROK_BIN="${CI_USER_BIN}/grok" \
            PATH="${CI_USER_BIN}:${CI_GLOBAL_BIN}:/usr/bin:/bin" \
            sh "${SCRIPT}" run -p hello 2>/dev/null
    )
    assert_contains "TP-GROK-CLI-46 run -p hello keeps --no-auto-update" "${_out}" "--no-auto-update"
    assert_contains "TP-GROK-CLI-46 run -p hello passes -p hello" "${_out}" "-p hello"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GROK_BIN="${CI_USER_BIN}/grok" \
            PATH="${CI_USER_BIN}:${CI_GLOBAL_BIN}:/usr/bin:/bin" \
            sh "${SCRIPT}" run --no-auto-update -p hello 2>/dev/null
    )
    _nau=$(printf '%s' "${_out}" | tr ' ' '\n' | grep -c -- '--no-auto-update' || true)
    assert_eq "TP-GROK-CLI-46 does not duplicate --no-auto-update" 1 "${_nau}"
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GROK_BIN="${CI_USER_BIN}/grok" \
            PATH="${CI_USER_BIN}:${CI_GLOBAL_BIN}:/usr/bin:/bin" \
            sh "${SCRIPT}" --json run 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-GROK-CLI-46 --json run exit 1" 1 "${_ec}"
    assert_contains "TP-GROK-CLI-46 --json run Next is run" "${_err}" "Next:"
    assert_contains "TP-GROK-CLI-46 --json run Next names run" "${_err}" " run"
    ci_cleanup_env

    ci_isolated_env
    _err=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" \
            PATH="${CI_USER_BIN}:${CI_GLOBAL_BIN}:/usr/bin:/bin" \
            sh "${SCRIPT}" run 2>&1 >/dev/null
    )
    _ec=$?
    assert_eq "TP-GROK-CLI-46 missing grok exit 1" 1 "${_ec}"
    assert_contains "TP-GROK-CLI-46 missing grok Next setup" "${_err}" "setup"
    ci_cleanup_env

    # TP-GROK-CLI-47 source dispatch: proot on PATH uses reaper.
    _src=$(cat "${SCRIPT}")
    assert_contains "TP-GROK-CLI-47 gc_grok_p_once_run" "${_src}" "gc_grok_p_once_run"
    assert_contains "TP-GROK-CLI-47 command -v proot dispatch" "${_src}" 'command -v proot'
    assert_contains "TP-GROK-CLI-47 proot-exit-reaper marker" "${_src}" "proot-exit-reaper"

    # TP-GROK-CLI-48 with fake proot on PATH, instant grok still succeeds
    # (reaper path; collector exits; no hang).
    ci_isolated_env
    ci_fake_grok_ok
    gc_write_valid_auth "${CI_HOME}/.grok"
    cat > "${CI_USER_BIN}/proot" <<'EOS'
#!/bin/sh
exec "$@"
EOS
    chmod +x "${CI_USER_BIN}/proot"
    _start=$(date +%s)
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_BIN="${GROK_BIN}" \
        PATH="${CI_USER_BIN}:${PATH}" \
        GROK_PROMPT_TIMEOUT=8 GROK_PROMPT_KILL_AFTER=1 \
        sh "${SCRIPT}" check-session 2>&1 >/dev/null)
    _ec=$?
    _elapsed=$(($(date +%s) - _start))
    assert_eq "TP-GROK-CLI-48 proot-path check-session exit 0" 0 "${_ec}"
    if [ "${_elapsed}" -lt 12 ]; then
        t_pass "TP-GROK-CLI-48 reaper path did not freeze (${_elapsed}s)"
    else
        t_fail "TP-GROK-CLI-48 reaper path froze for ${_elapsed}s"
    fi
    ci_cleanup_env
}
