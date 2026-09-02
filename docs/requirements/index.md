# Requirements index

**Product:** grok-cli (POSIX `/bin/sh` local self-managed CLI — grok auth backup to `/var/grok-cli` with narrow sudo deposit + unprivileged sync-auth)  
**Workspace state:** Specialized product law (left genesis); **software-development** class; bootstrap **cli-template → folder-backup → grok-cli** (domain retarget; online install **intentionally absent**).  
**Updated:** 2026-09-02 (20 Active + 4 superseded)

| ID / key | Title | Area | Status | Path | Updated |
|----------|-------|------|--------|------|---------|
| requirement-class-software-dev | Software-development class law + residual stack (posix-sh, local-only); residual no dest approver / no dest fence; §1.1 | class | Active (1.2.1) | `requirement-class-software-dev.md` | 2026-08-23 |
| requirement-bootstrap-chain | Bootstrap chain cli-template → folder-backup → grok-cli (domain retarget) | architecture | Active (3.0.1) | `requirement-bootstrap-chain.md` | 2026-08-23 |
| requirement-project-folder | Project layout (`src/`), install bins, `/var/grok-cli` deposit; preferred cache `/dev/shm/cache/cache-${APP_NAME}`; persistence `${HOME}/.local/${APP_NAME}` | architecture | Active (1.1.2) | `requirement-project-folder.md` | 2026-08-30 |
| requirement-three-layer-privilege-model | Type 0 + narrow Type 1 `grok-cli backup`; sudoers emit + install-script; per-user fragments; submit workflow; grant is backup only | architecture | Active (2.0.1) | `requirement-three-layer-privilege-model.md` | 2026-08-30 |
| requirement-sudoer-json-file | JSON sudoer file SSOT: `{{PRJ_NAME}}` only; args `["backup"]` only; independent generate dest readable | architecture | Active (2.0.0) | `requirement-sudoer-json-file.md` | 2026-08-22 |
| requirement-grok-auth-backup | **Auth ops SSOT**: session gate + deposit `auth.*` to `/var/grok-cli` (root:root 0644) + unprivileged `sync-auth` / `sync-auth-from-remote` | backup | Active (1.1.0) | `requirement-grok-auth-backup.md` | 2026-09-02 |
| requirement-grok-setup | Type 0 `setup`: curl xAI `https://x.ai/cli/install.sh` and run it so peer `grok` is installed (stale session PATH is not an error) | domain | Active (1.1.0) | `requirement-grok-setup.md` | 2026-08-30 |
| requirement-grok-crontab | Cron-job law: Type 0 `add-crontab` — this login’s crontab jobs (backup every 30 min; sync-auth at :45) after **this** login’s backup grant | domain | Active (1.1.0) | `requirement-grok-crontab.md` | 2026-09-02 |
| requirement-shell-cli-interface | Shell CLI interface (commands, flags, dispatch, modes); generate-sudoer-request; check-session / backup / sync-auth / sync-auth-from-remote / add-crontab; empty argv → `app_default`; about Cache folder + Persistence storage | shell | Active (2.5.0) | `requirement-shell-cli-interface.md` | 2026-09-02 |
| requirement-shell-cli-zero-arguments | Empty argv Type N (local-only): TTY numbered menu; off-TTY help; not install | shell | Active (1.3.0) | `requirement-shell-cli-zero-arguments.md` | 2026-08-23 |
| requirement-shell-cli-default-interaction | Case 3: TTY empty argv + `menu`/`main` numbered list (check-session/backup/sync-auth/sync-auth-from-remote/add-crontab + sudoers family; Exit 9; Back 8); **Implemented** | shell | Active (1.9.0) | `requirement-shell-cli-default-interaction.md` | 2026-09-02 |
| requirement-shell-local-self-management | Local install / uninstall / where-is-me; **mode 0755** multi-user | shell | Active (1.2.0) | `requirement-shell-local-self-management.md` | 2026-08-09 |
| requirement-shell-output-requirements | Central `out_*` output SSOT | shell | Active | `requirement-shell-output-requirements.md` | 2026-08-03 |
| requirement-operator-readable-error | Operator-facing error **wording** (human-intro style: what happened / next step) | shell | Active (1.0.0) | `requirement-operator-readable-error.md` | 2026-08-17 |
| requirement-shell-modular-function-design | Single-file modular prefixes (`out_`/`inst_`/`app_`/`gc_`) | shell | Active (1.1.0) | `requirement-shell-modular-function-design.md` | 2026-08-22 |
| requirement-shell-script-coding | POSIX sh coding style (`set -u`, `out_*`, `gc_*`, fail-closed elev) | shell | Active (1.0.1) | `requirement-shell-script-coding.md` | 2026-08-23 |
| requirement-shell-idempotency | Re-run safety; backup overwrite of same auth.* basenames | shell | Active | `requirement-shell-idempotency.md` | 2026-08-03 |
| requirement-shell-interactive-vs-noninteractive | Interactive vs non-interactive / confirm policy | shell | Active (1.0.1) | `requirement-shell-interactive-vs-noninteractive.md` | 2026-08-23 |
| requirement-shell-cli-storage | Storage = cache folder **and** persistence `${HOME}/.local/${APP_NAME}`; about Cache folder + Persistence storage | shell | Active (1.2.0) | `requirement-shell-cli-storage.md` | 2026-08-30 |
| requirement-domain-grok-cli | Domain **surface** SSOT (four pillars); ops defer to grok-auth-backup / grok-crontab | domain | Active (1.3.0) | `requirement-domain-grok-cli.md` | 2026-09-02 |
| requirement-domain-folder-backup | Retired folder-archive domain surface | domain | superseded | `requirement-domain-folder-backup.md` | 2026-08-22 |
| requirement-folder-archive-backup | Retired folder tar.gz backup/restore ops | backup | superseded | `requirement-folder-archive-backup.md` | 2026-08-22 |
| requirement-folder-archive-backup-retention-total | Retired total retention | backup | superseded | `requirement-folder-archive-backup-retention-total.md` | 2026-08-22 |
| requirement-folder-archive-backup-retention-daily | Retired daily retention | backup | superseded | `requirement-folder-archive-backup-retention-daily.md` | 2026-08-22 |

## Intentionally absent (by design — inherited from cli-template)

| Parent (cli-template) surface | Status on grok-cli |
|-------------------------------|---------------------|
| Online install / `SCRIPT_URL` / Type O empty-argv install-ensure | **Absent** |
| `version-check` / `self-update` / `self-uninstall` | **Absent** |
| Automatic companion `.sha256` channel integrity law | **Absent** |

**Install mode:** **local-only** (`install` + `uninstall` + `where-is-me`). Not dual-mode.

**Rules for agents:**

1. Treat Active rows above as the **live product-law inventory** for grok-cli.  
2. **Do not invent** additional `requirement-*.md` paths — verify on disk and add a registry row in the same change when creating one.  
3. Product source comments cite **only** these live requirement files — never templates/skills as behavioral authority.  
4. This versioned surface lists **requirement rows only**.  
5. Keep Status and Path in sync with each file’s header when status changes.  
6. **Class gate:** software-development requires exactly one Active `requirement-class-software-dev.md`.  
7. **Domain SSOT:** exactly one Active `requirement-domain-*` (`requirement-domain-grok-cli`).  
8. **Do not reintroduce** online install package without explicit user order and registry update.

When adding a requirement: append a row, create the file under `docs/requirements/`, keep Status in sync with the file header.
