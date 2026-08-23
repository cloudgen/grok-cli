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

    # TP-GROK-CLI-03 check-session missing auth
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" sh "${SCRIPT}" check-session 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-03 check-session missing exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-03 not logged in" "$_err" "not logged in"
    assert_contains "TP-GROK-CLI-03 next grok login" "$_err" "grok login"

    # TP-GROK-CLI-04 expired session fail-closed
    gc_write_expired_auth "${CI_HOME}/.grok"
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" sh "${SCRIPT}" check-session 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-04 expired session exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-04 not valid" "$_err" "not valid"

    # TP-GROK-CLI-05 check-session valid
    gc_write_valid_auth "${CI_HOME}/.grok"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" sh "${SCRIPT}" check-session 2>&1)
    assert_eq "TP-GROK-CLI-05 valid session exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-05 valid text" "$_out" "valid session"
    _j=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" sh "${SCRIPT}" --json check-session 2>/dev/null)
    assert_contains "TP-GROK-CLI-05 json session valid" "${_j}" '"session":"valid"'

    # TP-GROK-CLI-06 backup without session fail-closed
    rm -f "${CI_HOME}/.grok/auth.json"
    _store="${CI_HOME}/var-grok-cli"
    mkdir -p "${_store}"
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_CLI_ROOT="${_store}" \
        sh "${SCRIPT}" backup 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-06 backup no session exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-06 backup next login" "$_err" "grok login"

    # TP-GROK-CLI-07 backup to writable GROK_CLI_ROOT (test override; no sudo)
    gc_write_valid_auth "${CI_HOME}/.grok"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_CLI_ROOT="${_store}" \
        sh "${SCRIPT}" backup 2>&1)
    assert_eq "TP-GROK-CLI-07 backup exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-07 backup complete" "$_out" "Backup complete"
    assert_file_exists "TP-GROK-CLI-07 dest auth.json" "${_store}/auth.json"
    assert_file_exists "TP-GROK-CLI-07 dest lock" "${_store}/auth.json.lock"
    _mode=$(stat -c '%a' "${_store}/auth.json" 2>/dev/null || stat -f '%OLp' "${_store}/auth.json" 2>/dev/null || echo "")
    assert_eq "TP-GROK-CLI-07 dest auth.json mode 0644" "644" "${_mode}"
    assert_contains "TP-GROK-CLI-07 dest has refresh_token" "$(cat "${_store}/auth.json")" "test-refresh-token"

    # TP-GROK-CLI-08 backup is idempotent overwrite
    printf 'stale\n' > "${_store}/auth.json"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_CLI_ROOT="${_store}" \
        sh "${SCRIPT}" backup 2>&1)
    assert_eq "TP-GROK-CLI-08 second backup exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-08 overwrite restored token" "$(cat "${_store}/auth.json")" "test-refresh-token"

    # TP-GROK-CLI-09 sync-auth copies into a fresh grok home without sudo
    _other="${CI_HOME}/other-grok"
    _out=$(HOME="${CI_HOME}" GROK_HOME="${_other}" GROK_CLI_ROOT="${_store}" \
        sh "${SCRIPT}" sync-auth 2>&1)
    assert_eq "TP-GROK-CLI-09 sync-auth exit 0" 0 "$?"
    assert_contains "TP-GROK-CLI-09 complete" "$_out" "sync-auth complete"
    assert_file_exists "TP-GROK-CLI-09 dest auth.json" "${_other}/auth.json"
    _omode=$(stat -c '%a' "${_other}/auth.json" 2>/dev/null || stat -f '%OLp' "${_other}/auth.json" 2>/dev/null || echo "")
    assert_eq "TP-GROK-CLI-09 dest auth.json mode 0600" "600" "${_omode}"
    assert_contains "TP-GROK-CLI-09 dest token" "$(cat "${_other}/auth.json")" "test-refresh-token"

    # TP-GROK-CLI-10 sync-auth missing store fail-closed
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_CLI_ROOT="${CI_HOME}/no-store" \
        sh "${SCRIPT}" sync-auth 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-10 missing store exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-10 next backup" "$_err" "backup"

    # TP-GROK-CLI-11 restore command unknown
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" restore anything 2>&1 >/dev/null)
    assert_eq "TP-GROK-CLI-11 restore unknown exit 1" 1 "$?"
    assert_contains "TP-GROK-CLI-11 restore unknown text" "$_err" "Unknown command"

    # TP-GROK-CLI-12 production dest /var/grok-cli without global binary fails closed (no write)
    gc_write_valid_auth "${CI_HOME}/.grok"
    _err=$(HOME="${CI_HOME}" GROK_HOME="${CI_HOME}/.grok" GROK_CLI_ROOT=/var/grok-cli \
        sh "${SCRIPT}" backup 2>&1 >/dev/null)
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

    ci_cleanup_env
}
