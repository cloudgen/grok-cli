**file**: docs/requirements/requirement-project-folder.md  
**Status**: Active (Version 1.2.0)  
**Area**: architecture  
**Key**: `requirement-project-folder`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

Define **project folder structure** and path ownership for the grok-cli CLI: source layout, install locations, staging/scratch, the privileged durable grok-auth deposit root, and the **Termux / Android prefix tree** (`PREFIX`, `~/.grok`, `noexec` tmp).

**Critical distinction:** CLI tool own paths vs target folders being archived vs host durable backup deposit vs Termux prefix (not FHS `/usr`).

**Termux writing rules** (detect, `pkg`, exec) are **`requirement-shell-termux-coding`**. This file owns **path classes**.

---

### 1.1 Human-facing

This file says where grok-cli lives: `src/grok-cli`, user/global bins, `/var/grok-cli` for shared auth, and on a Termux phone `$PREFIX` plus `~/.grok` for the peer grok program.

| You | Another role | Not this |
|-----|--------------|----------|
| Install to `~/.local/bin` or `/usr/local/bin`; on Termux also honor `$PREFIX` | Root writes `/var/grok-cli` via `grok-cli backup` | Archiving arbitrary project folders; Termux `pkg` procedure |

**Includes:** ship path, bins, store root, Termux PREFIX tree, `~/.grok` place classes. **Excludes:** session parsing; `pkg` / wrapper writing (`requirement-shell-termux-coding` / `requirement-grok-setup`).

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Place the program | Copy the ship unit into a bin | `grok-cli install` |


## 2. Core Rules (Mandatory)

### 2.1 Workspace source layout (developer tree)

| Path | Role |
|------|------|
| `src/grok-cli` | **Ship unit** — single POSIX shell executable source |
| `tests/` | CLI tests when present |
| `docs/requirements/` | Product law (this surface) |
| Product root README / CHANGELOG / LICENSE / SECURITY | Product user docs when specialized |

1. **MUST** keep the installable CLI under **`src/`** (not only repo root).  
2. **MUST** install the binary under a privilege-correct bin path (see §2.2).  
3. **MUST NOT** require online channel files (companion digest) for local install.

### 2.2 CLI tool install locations (Type 1a / 1b)

| Mode | Binary path | Default |
|------|-------------|---------|
| **Per-user (normal)** | `${USER_BIN}/${APP_NAME}` | `${HOME}/.local/bin/grok-cli` |
| **Global (root)** | `${GLOBAL_BIN}/${APP_NAME}` | `/usr/local/bin/grok-cli` |
| **Termux PATH candidate** | `${PREFIX}/bin` when `PREFIX` is set | **Not** a grok-cli install dest — peer `grok` link + `pkg` only |

Rules:

1. Non-root **install** **MUST** target user bin.  
2. Root **install** **MAY** (and for production elevation **SHOULD**) target global bin.  
3. **Primary product story** for this project: **user bin** (`~/.local/bin`) for Type 0 day-to-day; **global bin** for multi-user / durable sudoers trust.  
4. Uninstall **MUST** remove only the managed binary path for the install mode used.  
5. Managed binary mode **MUST** be **`0755`** after install (shell ship unit: non-owners need **read+execute**; see `requirement-shell-local-self-management` §2.3.1). Global install **MUST** leave a path runnable by normal users and root, not owner-only (`0700`) or execute-without-read (`0711`).  
6. On Termux, missing `${GLOBAL_BIN}` **MUST NOT** fail a non-root grok-cli `install` to `${USER_BIN}`. **MUST NOT** place grok-cli into `${PREFIX}/bin` as if it were a Termux package (`requirement-shell-termux-coding`).

### 2.3 Scratch / cache (CLI own volatile)

| Purpose | Pattern |
|---------|---------|
| Preferred cache | `/dev/shm/cache/cache-grok-cli` (`requirement-shell-cli-storage`) |
| Fallback cache | `${XDG_CACHE_HOME}/cache-grok-cli` |
| Live root | From `util_resolve_storage` |
| Archive staging | `${EFFECTIVE_STORAGE_DIR}/stage/` (or `mktemp` under that root) |
| Persistence storage | `${HOME}/.local/grok-cli` (`requirement-shell-cli-storage`) |
| Sudoers fragment draft | User-writable path under config: `…/sudoers.fragment-<user>` (legacy un-suffixed still discoverable; never auto-write `/etc/sudoers.d`) |

Rules:

1. Preferred cache **MUST** be `/dev/shm/cache/cache-${APP_NAME}` — **MUST NOT** `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` (those look like ram-drive project folders).  
2. Fallback **MUST** be under this login’s XDG cache as `cache-${APP_NAME}`.  
3. Persistence **MUST** be `${HOME}/.local/${APP_NAME}` — **MUST NOT** `${HOME}/.local/bin` (install) and **MUST NOT** `/var/grok-cli` (Type 1 deposit).  
4. Temps **MUST** clean up (`trap`) after success/failure of a backup run.  
5. Staging archives are **EPHEMERAL** until successfully deposited; do not leave world-writable archives.

### 2.4 Durable host grok-auth deposit (not CLI config)

| Item | Value |
|------|--------|
| **Store root** | `/var/grok-cli` |
| **Override** | `GROK_CLI_ROOT` |
| **Auth glob** | `auth.*` under grok home |

Rules:

1. Writing into `/var/grok-cli` **MUST** use the **narrow elevated path** (`sudo grok-cli backup`) — not unrestricted root shell and not OS-tool sudoers.  
2. Normal users **MUST NOT** be granted write to all of `/var` — only the approved product command may push.  
3. Session check and reading `~/.grok/auth.*` **MUST** run as the invoking login; only the **deposit copy + chown/chmod** is elevated.  
4. Store files **MUST** be world-readable after root deposit so `sync-auth` needs no sudo.

### 2.5 Target folders being backed up

1. Source folder is a **user-supplied path** (domain operand), not an app system-user tree.  
2. The tool **MUST** validate the source is a readable directory before archiving.  
3. The tool **MUST NOT** follow uncontrolled recursion into dangerous system roots without explicit user path input and validation.

### 2.6 Termux / Android path classes (mandatory when `PREFIX` is set or `uname` reports Android)

Termux is **not** FHS `/usr`. Path **classes** live here; how code **detects** Android, calls `pkg`, and execs ET_EXEC lives on **`requirement-shell-termux-coding`**. `setup` place/smoke procedure lives on **`requirement-grok-setup`**.

| Class | Path shape | Role |
|-------|------------|------|
| Prefix root | `${PREFIX}` when set | Termux userspace (`bin/`, `etc/`). **MUST NOT** hard-code `/data/data/com.termux/files/usr` |
| Package bin | `${PREFIX}/bin` | `pkg`, `proot`; PATH candidate for peer `grok` |
| Termux etc | `${PREFIX}/etc` | resolv source when `/etc/resolv.conf` has no `nameserver` |
| Peer grok home | `${HOME}/.grok` (`GROK_HOME`) | downloads, bin, auth.*, resolv bind file |
| Exec-capable download | `${GROK_HOME}/downloads` | chmod + smoke `--version` (cache/`/tmp`/`/dev/shm` may be `noexec`) |
| Peer grok bin | `${GROK_HOME}/bin/grok` | wrapper or relative symlink |
| grok-cli user bin | `${HOME}/.local/bin` | grok-cli `install` dest for this login |
| Cache / tmp | `/dev/shm/cache/…`, `/tmp/cache/…` | scratch **only** — **MUST NOT** be the smoke/exec path |
| Shared deposit | `/var/grok-cli` | often **absent** on unrooted Termux — no substitute here |

Rules:

1. **MUST** document `PREFIX` as an optional live env (Termux sets it).  
2. **MUST NOT** treat `${PREFIX}/bin` as grok-cli’s managed install path.  
3. **MUST NOT** use the cache folder, `/tmp`, or `/dev/shm` as the place where a downloaded executable is smoked (`requirement-grok-setup` / `requirement-shell-termux-coding`).  
4. **MUST NOT** invent a Termux-local `/var/grok-cli` under `${PREFIX}` or `${HOME}` without a new Active requirement.

### 2.7 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **APP_NAME** | `grok-cli` |
| **Ship unit path** | `src/grok-cli` |
| **USER_BIN default** | `${HOME}/.local/bin` |
| **GLOBAL_BIN default** | `/usr/local/bin` (often missing on Termux) |
| **PREFIX** | Termux prefix when set — `${PREFIX}/bin` PATH candidate; not grok-cli install dest |
| **GROK_HOME** | `${HOME}/.grok` |
| **GROK_CLI_ROOT** | `/var/grok-cli` |
| **BACKUP_NOTATION default** | `grok-cli` |
| **Persistence storage** | `${HOME}/.local/grok-cli` |
| **Config dir (optional)** | `${HOME}/.config/grok-cli/` for generated sudoers drafts |
| **No Type 2 app data tree** | No dedicated system app user for routine ops |

### 2.8 Why This Requirement Exists (CIAO)

- **Principle 1 – Caution**: Separate staging, install, and privileged deposit.  
- **Principle 10 – Least privilege**: User creates archive; elevation only for deposit.  
- **Principle 11 – Temps**: Staging is cleanup, not museum.  
- **Principle 17 – Defensive storage**: No assumed writable paths without resolve.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Fail loud if deposit root or staging is not usable under policy.  
- **Intentional**: Path classes are documented and not mixed.  
- **Anti-fragile**: Per-user isolation under multi-user hosts.  
- **Over-protect**: Do not “simplify” by writing archives straight into `/var/grok-cli` as a normal user or by running the whole CLI as root.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Move the ship unit out of `src/` without updating this requirement and install paths.  
2. Make online channel paths required for install.  
3. Grant the product unrestricted write under `/var` or `/etc`.  
4. Collapse staging and durable deposit into one world-writable directory.  
5. Restore `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` as the preferred cache.  
6. Use `${HOME}/.local/bin` or `/var/grok-cli` as Type 0 persistence storage.  
7. Hard-code `/data/data/com.termux/files/usr` as the product prefix, or treat `${PREFIX}/bin` as grok-cli’s managed install dest.  
8. Use cache/`/tmp`/`/dev/shm` as the peer-grok smoke directory.  
9. Invent a Termux-local `/var/grok-cli` under `${PREFIX}` or `${HOME}` without a new requirement.

**Violating this rule is a critical path/privilege regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Ship unit lives at `src/grok-cli` |
| AC-2 | Default user install path is `~/.local/bin/grok-cli` |
| AC-3 | Durable deposit is under `/var/grok-cli` (`GROK_CLI_ROOT`) |
| AC-4 | Termux path classes (`PREFIX`, `${GROK_HOME}/downloads`, `${PREFIX}/bin` not grok-cli dest) are documented here |
| AC-5 | Cache/`/tmp`/`/dev/shm` are not the peer-grok smoke directory |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-local-self-management` | Place/remove binary |
| `requirement-shell-cli-storage` | Scratch resolve |
| `requirement-shell-termux-coding` | Termux writing (detect/`pkg`/`noexec`) |
| `requirement-grok-setup` | `~/.grok` place + smoke procedure |
| `requirement-domain-grok-cli` | Archive + deposit behavior |
| `requirement-three-layer-privilege-model` | Elevation boundary |
| `docs/requirements/index.md` | Registry |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active | Specialized project folder law for folder-backup |
| 2026-08-30 | Active 1.1.1 | Preferred cache `/dev/shm/cache/cache-${APP_NAME}` |
| 2026-08-30 | Active 1.1.2 | Persistence storage `${HOME}/.local/${APP_NAME}` |
| 2026-09-04 | Active 1.2.0 | Termux/Android path classes (`PREFIX`, `~/.grok/downloads`, noexec tmp); AC-3 deposit is `/var/grok-cli` |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-LC-01** | `tests/test_local_lifecycle.sh` | have — grok-cli install → `USER_BIN` |
| **TP-GROK-CLI-07** | `tests/test_domain_grok_cli.sh` | have — deposit under `GROK_CLI_ROOT` |
| **TP-VCLI-15** | `tests/test_grok_setup.sh` | have — smoke under `~/.grok/downloads` |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

---

**Last Updated**: 2026-09-04  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
