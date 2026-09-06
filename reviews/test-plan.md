# Test plan — grok-cli

Maps **TP-*** coverage to `tests/`.  
**Suite entry:** `./tests/run.sh`  
**Ship unit:** `src/grok-cli`  
**Product VERSION:** 1.8.9  
**Last plan update:** 2026-09-06  
**Last suite run:** `./tests/run.sh` (1.8.9: PASS=479 FAIL=0 SKIP=0)

Status: **have** = automated today · **todo** = needed · **optional** · **n/a** · **skip** (environment)

---

## Baseline coverage

| Area | Status | Evidence |
|------|--------|----------|
| Syntax `sh -n` | have | TP-CLI-01 |
| Active REQ samples do not freeze a session login | have | TP-CLI-18 |
| version / help / about human + JSON | have | TP-CLI-02..06 |
| Empty argv: TTY menu; off-TTY Type O ensure (not help) | have | TP-CLI-07 · TP-ONL-01 |
| Numbered menu verb `menu`/`main` (case 3; TTY empty argv shares handler; off-TTY `menu` = help) | have | TP-CLI-13 · TP-CLI-17 |
| Unknown + quiet + set -u HOME | have | TP-CLI-08..11 |
| Cache folder + persistence storage | have | TP-CLI-12 |
| Termux/Android host writing (`PREFIX`, `pkg`, `noexec` smoke) | have | TP-VCLI-15..25 · TP-LC-01 |
| Help lists setup / check-session / backup / sync-auth / sync-auth-from-remote / add-crontab; no restore operand | have | TP-CLI-04 |
| `setup` grok channel + artifact (fake curl; no `install.sh`) | have | TP-VCLI-01..09 · 11..16 |
| Local install / idempotent / uninstall / mode 0755 | have | TP-LC-01..10 |
| Session gate | have | TP-GROK-CLI-03..06 |
| Backup to writable GROK_CLI_ROOT + overwrite | have | TP-GROK-CLI-07/08 |
| sync-auth no sudo + dest 0600 | have | TP-GROK-CLI-09/10 |
| Production `/var/grok-cli` without global binary fail-closed | have | TP-GROK-CLI-12 |
| JSON grant is `grok-cli backup` only | have | TP-GROK-CLI-22* |
| Independent generate dest readable | have | TP-GROK-CLI-24* |
| Operator-readable inbound-fidelity `[ERROR]` | have | TP-GROK-CLI-25* |
| add-crontab grant gate + isolated jobs + idempotent | have | TP-GROK-CLI-26..29 |
| sync-auth-from-remote four SPEC forms + fake scp; TTY menu row 3 SPEC prompt | have | TP-GROK-CLI-30..34 |
| Online curl / companion checksum / version-check / self-uninstall | have | TP-ONL-01..04 · TP-CLI-10 |
| Folder tar.gz restore / retention | n/a | Superseded; TP-GROK-CLI-11 proves `restore` unknown |

---

## TP rows

### TP-CLI (CLI surface)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-CLI-01 | `sh -n` ship unit | `tests/test_cli.sh` | requirement-shell-cli-interface · requirement-shell-script-coding | **have** |
| TP-CLI-02 | version human | test_cli | requirement-shell-cli-interface | **have** |
| TP-CLI-03 | version JSON | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-04 | help: setup, auth verbs, version-check / self-update / self-uninstall, SCRIPT_URL; no restore; no CHECKSUM | test_cli | requirement-shell-cli-interface · requirement-domain-grok-cli · requirement-grok-setup · requirement-grok-crontab · requirement-grok-auth-backup · requirement-shell-self-management | **have** |
| TP-CLI-05 | help JSON short | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-06 | about JSON cache_preferred / cache_fallback / persistence_storage + grok_cli_root + session; human Cache folder + Persistence storage | test_cli | requirement-shell-cli-storage · requirement-domain-grok-cli | **have** |
| TP-CLI-07 | empty argv: off-TTY Type O already-installed (not help); `--json` no command JSON help; TTY numbered list | test_cli | requirement-shell-cli-zero-arguments · requirement-shell-cli-default-interaction | **have** |
| TP-CLI-08 | unknown fail-closed | test_cli | requirement-shell-cli-interface | **have** |
| TP-CLI-09 | quiet suppresses version | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-10 | version-check / self-update routed (not unknown) | test_cli | requirement-shell-self-management · requirement-bootstrap-chain | **have** |
| TP-CLI-11 | env -u HOME version | test_cli | requirement-shell-script-coding | **have** |
| TP-CLI-12 | preferred cache `/dev/shm/cache/cache-${APP_NAME}`; persistence `${HOME}/.local/${APP_NAME}`; live dirs exist; cache not APP-USERNAME shape; persistence not USER_BIN | test_cli | requirement-shell-cli-storage | **have** |
| TP-CLI-13 | `menu`/`main`: TTY daily-work list (backup is 1; sync-auth-from-remote is 3; add-crontab is 4; sudoers family is 5) + submenu (Back 8 / Exit 9); ignore `--json` on TTY; off-TTY `menu` help; empty argv off-TTY is Type O ensure (not help); `sudoers` not dispatched | `tests/test_cli.sh` | requirement-shell-cli-default-interaction · requirement-shell-cli-zero-arguments | **have** |
| TP-CLI-15 | Static: ship unit has no `$(prompt_ask` / `$(prompt_yes_no` (T1-PROMPT-CAPTURE; **TP-ELEV-10**) | `tests/test_cli.sh` | requirement-shell-script-coding · interactive-vs-noninteractive | **have** |
| TP-CLI-17 | Default CLI main menu style: header `APP_NAME(APP_VERSION)` bold/italic; numbered explain italic + light gray SGR 3+37; number/name unstyled; not SGR 90; session line under title; no `check-session` row; submenu nametag; inherited `APP_VERSION` ignored | `tests/test_cli.sh` | requirement-shell-cli-default-interaction · requirement-shell-output-requirements | **have** |
| TP-CLI-18 | Active `requirement-*.md` samples do not freeze a session Unix login | `tests/test_cli.sh` | requirement-sudoer-json-file · requirement-three-layer-privilege-model · requirement-domain-grok-cli | **have** |

### TP-LC (local lifecycle)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-LC-01 | install → USER_BIN | test_local_lifecycle | requirement-shell-local-self-management · requirement-shell-termux-coding | **have** |
| TP-LC-02 | installed binary version | test_local_lifecycle | local self-management | **have** |
| TP-LC-03 | reinstall already-installed | test_local_lifecycle | requirement-shell-idempotency | **have** |
| TP-LC-04 | where-is-me | test_local_lifecycle | local self-management | **have** |
| TP-LC-05 | uninstall JSON no force fail-closed | test_local_lifecycle | interactive-vs-noninteractive | **have** |
| TP-LC-06 | uninstall --force removes | test_local_lifecycle | local self-management | **have** |
| TP-LC-07 | uninstall absent no-op | test_local_lifecycle | idempotency | **have** |
| TP-LC-08 | about shows installed | test_local_lifecycle | local self-management | **have** |
| TP-LC-09 | installed mode is `0755` | test_local_lifecycle | local self-management | **have** |
| TP-LC-10 | reinstall heals `0711` → `0755` | test_local_lifecycle | local self-management | **have** |

### TP-VCLI (vendor peer grok installer)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-VCLI-01 | `setup` is routed | `tests/test_grok_setup.sh` | requirement-grok-setup · requirement-shell-cli-interface | **have** |
| TP-VCLI-02 | help lists setup, self-update, SCRIPT_URL; no `install.sh` | test_grok_setup | requirement-grok-setup · requirement-domain-grok-cli | **have** |
| TP-VCLI-03 | TTY menu excludes setup | test_cli (TP-CLI-13) | requirement-shell-cli-default-interaction | **have** |
| TP-VCLI-04 | grok already on PATH → no-op, no curl | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-05 | `--force` fetches channel pointer + artifact (not `install.sh`) | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-06 | curl fail → operator-readable Next | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |
| TP-VCLI-07 | missing curl → fail closed | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-08 | fake fetch places `grok` under `~/.grok/bin`, not grok-cli | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-09 | JSON `status` installed / already_installed | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-10 | live x.ai fetch | — | requirement-grok-setup | **optional** |
| TP-VCLI-11 | vendor `~/.grok/bin` + stale session PATH → exit 0, not `[ERROR]` | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |
| TP-VCLI-12 | binary download fail → fail closed, no USER_BIN PATH hint | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |
| TP-VCLI-13 | curl log MUST NOT contain `install.sh` | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-14 | curl log contains channel pointer and `grok-` artifact | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-15 | smoke `--version` runs under `~/.grok/downloads` (not cache/`/tmp`/`/dev/shm`) | test_grok_setup | requirement-grok-setup · requirement-shell-termux-coding · requirement-project-folder | **have** |
| TP-VCLI-16 | smoke `--version` fail → operator-readable Next + captured stderr | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |
| TP-VCLI-17 | existing grok that cannot run (wrong arch / exec fail) is not `already_installed`; fetch proceeds | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-18 | downloaded ELF `e_machine` mismatch → fail closed, no place | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |
| TP-VCLI-19 | Android `e_type` 2 smoke fail after retries → Next `pkg install proot` (not “check the download”) | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |
| TP-VCLI-20 | Android smoke succeeds only with TERMUX_EXEC_OPTOUT → POSIX wrapper; vendor file unchanged | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-21 | Android smoke succeeds only under `proot` → wrapper execs `proot` | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-22 | Termux: opt-out fail, `proot` missing, `pkg` present → `pkg install -y proot` then proot wrapper | test_grok_setup | requirement-grok-setup · requirement-shell-termux-coding | **have** |
| TP-VCLI-23 | Termux `pkg install` fail → fail closed, Next `pkg install proot`, no place | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |
| TP-VCLI-24 | artifact HTTP 403 → error names `HTTP 403` | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |
| TP-VCLI-25 | Android + no nameserver → `~/.grok/resolv.conf` + wrapper `proot -b …:/etc/resolv.conf` | test_grok_setup | requirement-grok-setup | **have** |

### TP-ONL (grok-cli channel install)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-ONL-01 | off-TTY empty argv places `USER_BIN/grok-cli` (fake curl; not help; not x.ai `install.sh`) | `tests/test_online_install.sh` | requirement-shell-online-install · requirement-shell-cli-zero-arguments | **have** |
| TP-ONL-02 | companion digest mismatch aborts | test_online_install | requirement-shell-automatic-checksum | **have** |
| TP-ONL-03 | `version-check --json` reports remote_version | test_online_install | requirement-shell-self-management | **have** |
| TP-ONL-04 | `self-uninstall --force` removes managed binary | test_online_install | requirement-shell-self-management | **have** |

### TP-GROK-CLI (domain + privilege + auth ops)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-GROK-CLI-01 | print-sudoers NOPASSWD grok-cli backup; no restore; no OS tools; no `/etc` write | test_domain_grok_cli | three-layer · domain | **have** |
| TP-GROK-CLI-01b | refuse test_local without `--allow-test-local` | test_domain_grok_cli | three-layer | **have** |
| TP-GROK-CLI-02 | print-sudoers to path; user-bound | test_domain_grok_cli | three-layer | **have** |
| TP-GROK-CLI-03 | check-session missing peer grok; Next setup then grok login | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-04 | `auth.json` looks valid but `grok -p hello` fails | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-05 | `grok -p hello` exit 0; no grok answer leak | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-06 | backup without session fail-closed | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-07 | backup writable GROK_CLI_ROOT; dest 0644 | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-08 | backup overwrite same basenames | test_domain_grok_cli | grok-auth-backup · idempotency | **have** |
| TP-GROK-CLI-09 | sync-auth dest 0600 no sudo | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-10 | sync-auth missing store fail-closed | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-11 | `restore` is unknown | test_domain_grok_cli | domain | **have** |
| TP-GROK-CLI-12 | `/var/grok-cli` without global binary fail-closed | test_domain_grok_cli | grok-auth-backup · three-layer | **have** |
| TP-GROK-CLI-14 | print-sudoers-install-script | test_domain_grok_cli | three-layer | **have** |
| TP-GROK-CLI-15 | remove-project-sudoers draft-only | test_domain_grok_cli | three-layer · interactive | **have** |
| TP-GROK-CLI-15b | multi-draft needs path | test_domain_grok_cli | three-layer | **have** |
| TP-GROK-CLI-19 | submit missing sudoer-cli | test_domain_grok_cli | three-layer | **have** |
| TP-GROK-CLI-20 | submit stub inbound | test_domain_grok_cli | three-layer | **have** |
| TP-GROK-CLI-21 / 21b | public inbound first; env override; no Type 0 mkdir | test_domain_grok_cli | three-layer · domain | **have** |
| TP-GROK-CLI-22 / 22b / 22c / 22d / 22e / 22f | JSON grant backup only; no OS tools; convert; inbound | test_domain_grok_cli | sudoer-json-file | **have** |
| TP-GROK-CLI-23 / 23b / 23c | host fragment → update default | test_domain_grok_cli | three-layer | **have** |
| TP-GROK-CLI-24 / 24b / 24c / 24d | independent generate dest readable | test_domain_grok_cli | sudoer-json-file · three-layer | **have** |
| TP-GROK-CLI-25 / 25b / 25c | operator-readable inbound incomplete | test_domain_grok_cli | operator-readable-error | **have** |
| TP-GROK-CLI-26 / 26b | add-crontab fail-closed without this login’s backup grant; wrong-user / wrong-argv / sibling fragment refused | test_domain_grok_cli | grok-crontab | **have** |
| TP-GROK-CLI-27 | add-crontab fail-closed without global binary | test_domain_grok_cli | grok-crontab | **have** |
| TP-GROK-CLI-28 / 28b | isolated crontab gets studied backup + sync-auth jobs on GLOBAL_BIN; user is `id -un` | test_domain_grok_cli | grok-crontab | **have** |
| TP-GROK-CLI-29 / 29b | re-run does not duplicate; other crontab lines kept | test_domain_grok_cli | grok-crontab · idempotency | **have** |
| TP-GROK-CLI-30 / 30b | sync-auth-from-remote missing/invalid SPEC fail-closed | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-31 / 31b / 31c / 31d | four SPEC forms (IPv4, user@IPv4, domain, user@domain) via fake scp | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-32 | dest auth.json mode 0600 | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-33 | missing remote auth fail-closed with Next: | test_domain_grok_cli | grok-auth-backup · operator-readable-error | **have** |
| TP-GROK-CLI-34 | TTY menu `sync-auth-from-remote` row (main **3**) shows SPEC prompt; typed SPEC is not mixed with prompt text; fake scp completes (INC-20260902-001) | test_domain_grok_cli | grok-auth-backup · interactive-vs-noninteractive · output | **have** |
| TP-GROK-CLI-35 | expired `auth.json` + `grok -p hello` ok → logged in (live probe wins) | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-36 | grok `-p hello` stdout/stderr not printed (no token leak) | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-37 | Core tests fake `GROK_BIN`; no public network | test_domain_grok_cli | grok-auth-backup · termux-coding | **have** |
| TP-GROK-CLI-38 | valid-looking `auth.json` without grok is not logged in | test_domain_grok_cli | grok-auth-backup | **have** |
