**file**: docs/requirements/requirement-project-folder.md  
**Status**: Active (Version 1.1.2)  
**Area**: architecture  
**Key**: `requirement-project-folder`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

Define **project folder structure** and path ownership for the grok-cli CLI: source layout, install locations, staging/scratch, and the privileged durable grok-auth deposit root.

**Critical distinction:** CLI tool own paths vs target folders being archived vs host durable backup deposit.

---

### 1.1 Human-facing

This file says where grok-cli lives: `src/grok-cli`, user/global bins, and `/var/grok-cli` for shared auth.

| You | Another role | Not this |
|-----|--------------|----------|
| Install to `~/.local/bin` or `/usr/local/bin` | Root writes `/var/grok-cli` via `grok-cli backup` | Archiving arbitrary project folders |

**Includes:** ship path, bins, store root. **Excludes:** session parsing.

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

Rules:

1. Non-root **install** **MUST** target user bin.  
2. Root **install** **MAY** (and for production elevation **SHOULD**) target global bin.  
3. **Primary product story** for this project: **user bin** (`~/.local/bin`) for Type 0 day-to-day; **global bin** for multi-user / durable sudoers trust.  
4. Uninstall **MUST** remove only the managed binary path for the install mode used.  
5. Managed binary mode **MUST** be **`0755`** after install (shell ship unit: non-owners need **read+execute**; see `requirement-shell-local-self-management` §2.3.1). Global install **MUST** leave a path runnable by normal users and root, not owner-only (`0700`) or execute-without-read (`0711`).

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

### 2.6 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **APP_NAME** | `grok-cli` |
| **Ship unit path** | `src/grok-cli` |
| **USER_BIN default** | `${HOME}/.local/bin` |
| **GLOBAL_BIN default** | `/usr/local/bin` |
| **GROK_CLI_ROOT** | `/var/grok-cli` |
| **BACKUP_NOTATION default** | `grok-cli` |
| **Persistence storage** | `${HOME}/.local/grok-cli` |
| **Config dir (optional)** | `${HOME}/.config/grok-cli/` for generated sudoers drafts |
| **No Type 2 app data tree** | No dedicated system app user for routine ops |

### 2.7 Why This Requirement Exists (CIAO)

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

**Violating this rule is a critical path/privilege regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Ship unit lives at `src/grok-cli` |
| AC-2 | Default user install path is `~/.local/bin/grok-cli` |
| AC-3 | Durable deposit is under `/var/backup/${BACKUP_NOTATION}/` |
| AC-4 | Archive naming pattern documented and owned with domain law |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-local-self-management` | Place/remove binary |
| `requirement-shell-cli-storage` | Scratch resolve |
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

---

**Last Updated**: 2026-08-30  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
