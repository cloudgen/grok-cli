# Requirement ↔ test matrix — grok-cli

**Updated:** 2026-09-07 (1.8.21 PRoot-exit reaper)  
**Product VERSION:** 1.8.21  
**Suite:** `tests/run.sh`

| Requirement key | Area | TP families | Coverage notes |
|-----------------|------|-------------|----------------|
| requirement-class-software-dev | class | TP-CLI-01, TP-CLI-11 | Syntax + stack residual; dual-mode; leftover points at Termux writing |
| requirement-bootstrap-chain | architecture | TP-CLI-04, TP-CLI-10 · TP-ONL-* | Channel + checkout; selfmanaged hop |
| requirement-project-folder | architecture | TP-LC-01, TP-GROK-CLI-07, TP-VCLI-15 | src ship unit; `/var/grok-cli` store; Termux `PREFIX` / `~/.grok/downloads` |
| requirement-three-layer-privilege-model | architecture | TP-GROK-CLI-01, 01b, 02, 12, 14, 15, 15b, 19, 20, 21, 21b, 22e, 23, 23b, 23c, 24* | Trust tiers; submit; independent generate; inbound; host-probe add/update |
| requirement-sudoer-json-file | architecture | TP-GROK-CLI-22* · 24* | JSON grant is `grok-cli backup` only |
| requirement-grok-auth-backup | backup | TP-GROK-CLI-03..10, 12 · 30..45 · 47 · 48 | Live `grok -p hello` session gate (before `auth.json`); always bounded; `proot` on PATH → reaper else simple `-p`; elevated probe uses `SUDO_USER` home; grant-present child fail is not missing sudoers; deposit; sync-auth; sync-auth-from-remote; skip sync when already logged in; preferred SPEC in persistence; TTY menu SPEC prompt; production dest fail-closed |
| requirement-grok-setup | domain | TP-VCLI-01..09 · 11..30 · TP-CLI-04 · TP-CLI-13 · TP-GROK-CLI-46 | Peer grok channel + artifact; Android ET_EXEC wrapper; Termux proot `--kill-on-exit` + `proot-exit-reaper`; heal stale wrapper on skip; `run` starts grok without auto-update |
| requirement-grok-crontab | domain | TP-GROK-CLI-26..29 · TP-CLI-04 · TP-CLI-13 | Per-login crontab jobs; grant gate is this `id -un` |
| requirement-shell-cli-interface | shell | TP-CLI-* · TP-VCLI-01 · TP-ONL-* · TP-GROK-CLI-46 | Commands, flags, dispatch; `setup`; `run`; online verbs; TP-CLI-18 no frozen login in Active REQ samples; `--debug` dual mention TP-CLI-25..28 |
| requirement-shell-cli-zero-arguments | shell | TP-CLI-07 · TP-CLI-13 · TP-CLI-29 · TP-ONL-01 | TTY numbered menu; off-TTY Type O ensure; overlay `--debug` / `--quiet` follow empty argv |
| requirement-shell-cli-default-interaction | shell | TP-CLI-13 · TP-CLI-07 · TP-CLI-17 · TP-CLI-19 · TP-CLI-20 · TP-CLI-21 · TP-CLI-22 · TP-CLI-23 · TP-CLI-25 · TP-CLI-26 · TP-CLI-29 | Case 3 `menu`/`main` + TTY empty argv (including overlay `--debug`); this-login-only lists `run` first; session line from `grok -p hello`; hide backup/sync-auth/sudoers on that class; logged-in hide; Termux menu does not freeze |
| requirement-shell-local-self-management | shell | TP-LC-* | checkout install/uninstall/where-is-me; 0755; Termux dest is `USER_BIN` |
| requirement-shell-online-install | shell | TP-ONL-01 · TP-CLI-07 | Channel `SCRIPT_URL`; pipe place |
| requirement-shell-self-management | shell | TP-ONL-03 · 04 · TP-CLI-04 · 10 | version-check / self-update / self-uninstall |
| requirement-shell-automatic-checksum | shell | TP-ONL-02 | Companion mismatch abort |
| requirement-shell-output-requirements | shell | TP-CLI-03,05,08,09 · TP-CLI-17 | JSON / quiet / errors; `out_menu_choice` SGR 3+37 |
| requirement-operator-readable-error | shell | TP-GROK-CLI-25* · TP-GROK-CLI-40 · TP-VCLI-16 · TP-VCLI-19 | Operator-facing `[ERROR]` |
| requirement-shell-modular-function-design | shell | TP-CLI-01 | `gc_*` prefix |
| requirement-shell-script-coding | shell | TP-CLI-01, TP-CLI-11, TP-CLI-15 · TP-VCLI-15, 19..25 | posix-sh `set -u`; no `$()` of `read` helpers; Termux slice pointed |
| requirement-shell-termux-coding | shell | TP-VCLI-15..30 · TP-LC-01 · TP-CLI-01 · TP-GROK-CLI-35..38 · 44 · 45 · 47 · 48 · TP-CLI-21 | `PREFIX`/`pkg`/`noexec`; Android ET_EXEC; wrapper `--kill-on-exit` / `proot-exit-reaper`; probe dispatch `proot` → reaper else simple `-p`; grok-cli dest stays `USER_BIN` |
| requirement-shell-idempotency | shell | TP-LC-03,07 · TP-GROK-CLI-08 · 29 | Re-install; auth overwrite; crontab no-duplicate |
| requirement-shell-interactive-vs-noninteractive | shell | TP-LC-05 · TP-GROK-CLI-15 · 15b · 34 · TP-CLI-15 | Confirm fail-closed; no `$()` of `prompt_ask` |
| requirement-shell-cli-storage | shell | TP-CLI-**06**, **12** · TP-GROK-CLI-41 · TP-VCLI-15 | Cache `/dev/shm/cache/cache-${APP_NAME}` + persistence `${HOME}/.local/${APP_NAME}` (preferred-remote leaf); Termux cache may be `noexec` |
| requirement-shell-internal-volatile-timer | shell | TP-CLI-25 · 26 · 27 · 28 | Named volatile `util_int_timer_*`; `--debug menu` elapsed of each paint step; JSON stdout stays pure |
| requirement-domain-grok-cli | domain | TP-GROK-CLI-01,02,11,14,15,19,20,21*,23*,24* · 26..29 · 46..48 · TP-CLI-04,06 · TP-VCLI-02 | Surface verbs/help/about including `setup`, `run`, `check-session` (PRoot-aware `-p`) |
| requirement-domain-folder-backup | superseded | n/a | Retired |
| requirement-folder-archive-backup* | superseded | n/a | Retired (TP-GROK-CLI-11 proves restore unknown) |

**Absent by design (no TP Core):** Type O-P payload installer; dest fence-test (no dest approval machine).
