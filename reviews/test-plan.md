# Test plan — grok-cli

Maps **TP-*** coverage to `tests/`.  
**Suite entry:** `./tests/run.sh`  
**Ship unit:** `src/grok-cli`  
**Product VERSION:** 1.2.1  
**Last plan update:** 2026-08-30  
**Last suite run:** `./tests/run.sh` (1.2.1: PASS=280 FAIL=0 SKIP=0)

Status: **have** = automated today · **todo** = needed · **optional** · **n/a** · **skip** (environment)

---

## Baseline coverage

| Area | Status | Evidence |
|------|--------|----------|
| Syntax `sh -n` | have | TP-CLI-01 |
| version / help / about human + JSON | have | TP-CLI-02..06 |
| Type N empty argv = TTY menu / off-TTY help | have | TP-CLI-07 |
| Numbered menu verb `menu`/`main` (case 3; TTY empty argv shares handler) | have | TP-CLI-13 |
| Unknown + quiet + set -u HOME | have | TP-CLI-08..11 |
| Storage isolation | have | TP-CLI-12 |
| Help lists setup / check-session / backup / sync-auth; no restore operand | have | TP-CLI-04 |
| `setup` vendor grok installer (fake curl) | have | TP-VCLI-01..09 · 11 · 12 |
| Local install / idempotent / uninstall / mode 0755 | have | TP-LC-01..10 |
| Session gate | have | TP-GROK-CLI-03..06 |
| Backup to writable GROK_CLI_ROOT + overwrite | have | TP-GROK-CLI-07/08 |
| sync-auth no sudo + dest 0600 | have | TP-GROK-CLI-09/10 |
| Production `/var/grok-cli` without global binary fail-closed | have | TP-GROK-CLI-12 |
| JSON grant is `grok-cli backup` only | have | TP-GROK-CLI-22* |
| Independent generate dest readable | have | TP-GROK-CLI-24* |
| Operator-readable inbound-fidelity `[ERROR]` | have | TP-GROK-CLI-25* |
| Online curl / companion checksum | n/a | Local-only product |
| Folder tar.gz restore / retention | n/a | Superseded; TP-GROK-CLI-11 proves `restore` unknown |

---

## TP rows

### TP-CLI (CLI surface)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-CLI-01 | `sh -n` ship unit | `tests/test_cli.sh` | requirement-shell-cli-interface · requirement-shell-script-coding | **have** |
| TP-CLI-02 | version human | test_cli | requirement-shell-cli-interface | **have** |
| TP-CLI-03 | version JSON | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-04 | help: setup, check-session, backup, sync-auth, sudoers verbs; no restore operand; no grok-cli online channel | test_cli | requirement-shell-cli-interface · requirement-domain-grok-cli · requirement-grok-setup | **have** |
| TP-CLI-05 | help JSON short | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-06 | about JSON grok_cli_root + session | test_cli | requirement-shell-cli-storage · requirement-domain-grok-cli | **have** |
| TP-CLI-07 | empty argv Type N: off-TTY help; `--json` no command JSON help; TTY numbered list | test_cli | requirement-shell-cli-zero-arguments · requirement-shell-cli-default-interaction | **have** |
| TP-CLI-08 | unknown fail-closed | test_cli | requirement-shell-cli-interface | **have** |
| TP-CLI-09 | quiet suppresses version | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-10 | online verbs rejected | test_cli | requirement-bootstrap-chain | **have** |
| TP-CLI-11 | env -u HOME version | test_cli | requirement-shell-script-coding | **have** |
| TP-CLI-12 | storage isolation | test_cli | requirement-shell-cli-storage | **have** |
| TP-CLI-13 | `menu`/`main`: TTY daily-work list + sudoers submenu (Back 8 / Exit 9); ignore `--json` on TTY; non-TTY help following `--json`; empty argv off-TTY still help; `sudoers` not dispatched | `tests/test_cli.sh` | requirement-shell-cli-default-interaction · requirement-shell-cli-zero-arguments | **have** |

### TP-LC (local lifecycle)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-LC-01 | install → USER_BIN | test_local_lifecycle | requirement-shell-local-self-management | **have** |
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
| TP-VCLI-02 | help lists setup; no self-update / SCRIPT_URL | test_grok_setup | requirement-grok-setup · requirement-domain-grok-cli | **have** |
| TP-VCLI-03 | TTY menu excludes setup | test_cli (TP-CLI-13) | requirement-shell-cli-default-interaction | **have** |
| TP-VCLI-04 | grok already on PATH → no-op, no curl | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-05 | `--force` fetches vendor URL | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-06 | curl fail → operator-readable Next | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |
| TP-VCLI-07 | missing curl → fail closed | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-08 | fake installer places `grok`, not grok-cli | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-09 | JSON `status` installed / already_installed | test_grok_setup | requirement-grok-setup | **have** |
| TP-VCLI-10 | live x.ai fetch | — | requirement-grok-setup | **optional** |
| TP-VCLI-11 | vendor `~/.grok/bin` + stale session PATH → exit 0, not `[ERROR]` | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |
| TP-VCLI-12 | installer ran, grok missing on disk → fail closed, no USER_BIN PATH hint | test_grok_setup | requirement-grok-setup · requirement-operator-readable-error | **have** |

### TP-GROK-CLI (domain + privilege + auth ops)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-GROK-CLI-01 | print-sudoers NOPASSWD grok-cli backup; no restore; no OS tools; no `/etc` write | test_domain_grok_cli | three-layer · domain | **have** |
| TP-GROK-CLI-01b | refuse test_local without `--allow-test-local` | test_domain_grok_cli | three-layer | **have** |
| TP-GROK-CLI-02 | print-sudoers to path; user-bound | test_domain_grok_cli | three-layer | **have** |
| TP-GROK-CLI-03 | check-session missing auth.json | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-04 | expired session fail-closed | test_domain_grok_cli | grok-auth-backup | **have** |
| TP-GROK-CLI-05 | valid session | test_domain_grok_cli | grok-auth-backup | **have** |
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
