# Requirement ↔ test matrix — grok-cli

**Updated:** 2026-08-30  
**Product VERSION:** 1.3.0  
**Suite:** `tests/run.sh`

| Requirement key | Area | TP families | Coverage notes |
|-----------------|------|-------------|----------------|
| requirement-class-software-dev | class | TP-CLI-01, TP-CLI-11 | Syntax + stack residual; no online package |
| requirement-bootstrap-chain | architecture | TP-CLI-04, TP-CLI-10 | Online surface absent |
| requirement-project-folder | architecture | TP-LC-01, TP-GROK-CLI-07 | src ship unit; `/var/grok-cli` store |
| requirement-three-layer-privilege-model | architecture | TP-GROK-CLI-01, 01b, 02, 12, 14, 15, 15b, 19, 20, 21, 21b, 22e, 23, 23b, 23c, 24* | Trust tiers; submit; independent generate; inbound; host-probe add/update |
| requirement-sudoer-json-file | architecture | TP-GROK-CLI-22* · 24* | JSON grant is `grok-cli backup` only |
| requirement-grok-auth-backup | backup | TP-GROK-CLI-03..10, 12 · 30..33 | Session gate; deposit; sync-auth; sync-auth-from-remote; production dest fail-closed |
| requirement-grok-setup | domain | TP-VCLI-01..09 · 11 · 12 · TP-CLI-04 · TP-CLI-13 | Peer grok installer; stale PATH after `.bashrc` is not an error |
| requirement-grok-crontab | domain | TP-GROK-CLI-26..29 · TP-CLI-04 · TP-CLI-13 | Per-login crontab jobs; grant gate is this `id -un` |
| requirement-shell-cli-interface | shell | TP-CLI-* · TP-VCLI-01 | Commands, flags, dispatch; `setup` |
| requirement-shell-cli-zero-arguments | shell | TP-CLI-07 · TP-CLI-13 | Type N: TTY numbered menu; off-TTY help; not install |
| requirement-shell-cli-default-interaction | shell | TP-CLI-13 · TP-CLI-07 | Case 3 `menu`/`main` + TTY empty argv — daily-work list + sudoers submenu / off-TTY help |
| requirement-shell-local-self-management | shell | TP-LC-* | install/uninstall/where-is-me; 0755 |
| requirement-shell-output-requirements | shell | TP-CLI-03,05,08,09 | JSON / quiet / errors |
| requirement-operator-readable-error | shell | TP-GROK-CLI-25* | Operator-facing `[ERROR]` |
| requirement-shell-modular-function-design | shell | TP-CLI-01 | `gc_*` prefix |
| requirement-shell-script-coding | shell | TP-CLI-01, TP-CLI-11 | posix-sh `set -u` |
| requirement-shell-idempotency | shell | TP-LC-03,07 · TP-GROK-CLI-08 · 29 | Re-install; auth overwrite; crontab no-duplicate |
| requirement-shell-interactive-vs-noninteractive | shell | TP-LC-05 · TP-GROK-CLI-15 · 15b | Confirm fail-closed |
| requirement-shell-cli-storage | shell | TP-CLI-**06**, **12** | Cache `/dev/shm/cache/cache-${APP_NAME}` + persistence `${HOME}/.local/${APP_NAME}`; about Cache folder + Persistence storage |
| requirement-domain-grok-cli | domain | TP-GROK-CLI-01,02,11,14,15,19,20,21*,23*,24* · 26..29 · TP-CLI-04,06 · TP-VCLI-02 | Surface verbs/help/about including `setup` and `add-crontab` |
| requirement-domain-folder-backup | superseded | n/a | Retired |
| requirement-folder-archive-backup* | superseded | n/a | Retired (TP-GROK-CLI-11 proves restore unknown) |

**Absent by design (no TP Core):** online-install, remote self-management, automatic channel checksum, dest fence-test (no dest approval machine).
