**file**: docs/requirements/requirement-shell-local-self-management.md  
**Status**: Active (Version 1.3.1)  
**Area**: shell  
**Key**: `requirement-shell-local-self-management`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **local self-managed lifecycle** of the grok-cli POSIX shell CLI: **`install`**, **`uninstall`**, and **`where-is-me`**, plus the local diagnostics package contract for **`version`**, **`about`**, and **`help`** (wiring owned with CLI interface).

**Install mode:** **dual-mode secondary**. This file owns **checkout copy** `install` / `uninstall` / `where-is-me` (offline, no network). Channel pipe, `self-update`, `version-check`, and `self-uninstall` are owned by `requirement-shell-online-install` and `requirement-shell-self-management`.

---

### 1.1 Human-facing

Install copies grok-cli into your bin; uninstall removes that copy. It does not remove `/etc` sudoers.

| You | Another role | Not this |
|-----|--------------|----------|
| `grok-cli install` / `uninstall` from a checkout | Admin installs the sudoers fragment | The curl one-liner (online-install) |

**Includes:** place/remove binary, mode 0755. **Excludes:** `/var/grok-cli` content.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Place locally | Copy ship unit to `~/.local/bin` | `grok-cli install` |


## 2. Core Rules (Mandatory)

### 2.1 Local lifecycle command pair

| Feature | Command | Meaning |
|---------|---------|---------|
| Local install | **`install`** | Copy **running** ship unit → privilege-correct bin; **no** network |
| Local uninstall | **`uninstall`** | Remove **managed** binary only; confirm / `--force` |
| Local refresh | **`install --force`** | Replace managed binary from **this** running ship unit |
| Where-is-me | **`where-is-me`** | Report running path + managed install path + installed flag |

**This file does not own** `self-uninstall`, `self-update`, `version-check` (peer self-management). `install` here is checkout copy, not channel download.

### 2.2 Local diagnostics (required companions)

| Feature | Command | Network |
|---------|---------|---------|
| **Local version** | `version` | **MUST NOT** fetch remote |
| About | `about` | Local diagnostics **plus** channel URL (`SCRIPT_URL`) |
| Help | `help` | Lists local lifecycle + domain commands |

### 2.3 Local install rules

1. Source **MUST** be the currently executing ship unit when resolvable — **not** a URL.  
2. Target **MUST** be root → `${GLOBAL_BIN}/${APP_NAME}`; non-root → `${USER_BIN}/${APP_NAME}` unless **`--global`** / `FORCE_GLOBAL=1` is set.  
3. Defaults: `GLOBAL_BIN=/usr/local/bin`; `USER_BIN=${HOME}/.local/bin`.  
3b. On Termux, missing `${GLOBAL_BIN}` **MUST NOT** fail a non-root `install` to `${USER_BIN}`. **MUST NOT** place grok-cli into `${PREFIX}/bin` as a Termux package (`requirement-shell-termux-coding` / `requirement-project-folder`). `${PREFIX}/bin` is a PATH candidate for peer `grok` only (`requirement-grok-setup`).  
4. Create target bin dir when missing; fail loud if not writable.  
5. Atomic place: stage → set mode → `mv` onto final path (or equivalent `install -m`).  
6. Idempotent: already installed + force off → success no-op **for content**; mode **MUST** still be healed to the required mode when the installer can write the target (see §2.3.1).  
7. **MUST NOT** require network for install.  
8. **`install --global`** (or `FORCE_GLOBAL=1`): target **`${GLOBAL_BIN}/${APP_NAME}`**; if not writable, fail with clear root/sudo guidance.  
9. For hosts that will admin-install **sudoers**, operators **SHOULD** use global install (root). Local install alone is **not** production-secure for elevation (see `requirement-three-layer-privilege-model` §2.3.1a).

### 2.3.1 Installed binary mode (multi-user runnable) — mandatory

This product ships as a **POSIX shell script** (interpreted). Execution by any non-owner requires the **read** bit for that class, not execute alone.

| Rule | Requirement |
|------|-------------|
| **Final mode** | Managed install **MUST** set absolute mode **`0755`** (`rwxr-xr-x`) on the installed binary |
| **Forbidden weak form** | **MUST NOT** rely on `chmod +x` alone after `mktemp`/`cp` — `0600 \| 0111 = 0711` yields `rwx--x--x`, which **breaks** non-owner runs of shell scripts |
| **Global multi-user** | After root/global install to `${GLOBAL_BIN}`, **any** host user (including root and unprivileged accounts) **MUST** be able to execute `${GLOBAL_BIN}/${APP_NAME}` (subject only to path/exec mount policy) |
| **User-bin** | Local install **MUST** also use **`0755`** so the owner always has a normal runnable script (and heal survives umask / prior bad modes) |
| **Not world-writable** | Mode **MUST NOT** grant group/other write (`o+w` / `g+w` forbidden for the managed binary) |
| **Mode heal** | If the managed path already exists and force is off, install **MUST** still attempt `chmod 0755` on that path when permitted (fix broken `0700`/`0711` installs without requiring `--force`) |
| **Verify** | After place (and after heal), the installer **SHOULD** confirm the path is readable and executable by the installing process; fail loud if place left a non-executable file |

**Rationale (CIAO):** Global install is the production trust path for elevation. A root-owned `0711` ship unit looks “installed” (`-x`) but denies normal users — anti-fragile install must leave a **usable multi-user CLI**, not merely an owner-only script.

### 2.4 Local uninstall rules

1. User command name **MUST** be **`uninstall`** only.  
2. Target **MUST** be the managed binary only.  
3. Absent → success no-op.  
4. Interactive confirm unless `--force`; non-interactive/json/quiet without force → **fail closed** (`confirm_required`).  
5. **MUST NOT** delete domain data, `/var/backup` archives, home trees, or unrelated binaries.  
6. After remove, human mode **SHOULD** warn that host sudoers fragments under **`/etc/sudoers.d/grok-cli-<user>`** (and any legacy `/etc/sudoers.d/grok-cli`) are **not** removed by uninstall; admin must remove or reinstall fragment separately when leaving test elevation.

### 2.5 Where-is-me rules

1. Report absolute running path when resolvable.  
2. Report expected managed install path and whether installed.  
3. Honest degradation when `$0` is not a file path.  
4. JSON at least: `running_path`, `install_path`, `installed`.  
5. Output via `out_*` / `out_json` only.

### 2.6 Config variables (local)

| Variable | Role | Default / note |
|----------|------|----------------|
| `APP_NAME` | Binary basename SSOT | hard-assign `grok-cli` |
| `VERSION` | Local version SSOT | hard-assign in ship unit (do not pin a stale number here) |
| `GLOBAL_BIN` | System-wide bin | `/usr/local/bin` |
| `USER_BIN` | Per-user bin | `${HOME}/.local/bin` |
| `FORCE` | Replace / skip confirm | `0` |
| `FORCE_GLOBAL` | Force install/operate on global path | `0` (`install --global`) |
| `ALLOW_TEST_LOCAL_SUDOERS` | Allow `print-sudoers` under test_local tier | `0` (see three-layer privilege) |
| `SCRIPT_URL` / `REPO_*` / `CHECKSUM` | **Not** checkout-install source | Channel owned by `requirement-shell-online-install` |

### 2.7 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product / binary** | `grok-cli` |
| **Ship unit** | `src/grok-cli` |
| **Primary install path story** | Type 0 day-to-day: `${HOME}/.local/bin/grok-cli`; production elevation: `/usr/local/bin/grok-cli` |
| **Handlers** | `inst_local_install`, `inst_local_uninstall`, `app_where_is_me`, `app_version` |
| **Detect** | `inst_is_installed` / privilege-correct path helpers |
| **Online package** | **Dual-mode secondary** — checkout copy here; channel owned by `requirement-shell-online-install` |

### 2.8 Why This Requirement Exists (CIAO)

- **Principle 9 – Command types**: Type 0 local lifecycle only for place/remove.  
- **Principle 10 – Least privilege**: User bin without root when possible.  
- **Principle 3 – Anti-fragile**: Works offline / air-gapped.  
- **Principle 16 – Interactive**: Uninstall confirm contract.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: No network in install path.  
- **Intentional**: Local verbs only (`install`/`uninstall`).  
- **Anti-fragile**: Idempotent place/remove.  
- **Over-protect**: Do not steal channel verbs (`self-update` / `version-check`) into checkout `install`.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Replace local `uninstall` with online `self-uninstall` as the primary remove verb.  
2. Require `SCRIPT_URL` for install.  
3. Steal empty argv from `requirement-shell-cli-zero-arguments` (TTY menu / off-TTY Type O).  
4. Delete user data or `/var/backup` content during uninstall.  
5. Fetch remote version inside `version`.  
6. Install the managed binary with execute-only group/other bits (`0711` / `chmod +x` after `0600` stage) — **must** keep absolute **`0755`** so global install remains multi-user runnable for a shell ship unit.  
7. Place grok-cli into `${PREFIX}/bin` as a Termux package, or fail a non-root Termux `install` because `/usr/local/bin` is missing.

**Violating this rule is a critical install-mode regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | `install` copies ship unit to user or global bin without network |
| AC-2 | `uninstall` removes managed binary only with confirm/`--force` contract |
| AC-3 | `where-is-me` reports paths + installed flag |
| AC-4 | `version` is local-only |
| AC-5 | Checkout `install` stays offline; channel verbs live on peer online/self-management REQs |
| AC-6 | Installed managed binary mode is **`0755`** (not `0711` / owner-only) after install |
| AC-7 | Global install is executable by a non-owner account (shell script remains readable) |
| AC-8 | Re-running `install` without `--force` heals a broken mode (`0700`/`0711` → `0755`) when writable |
| AC-9 | Non-root install dest is `USER_BIN`; `${PREFIX}/bin` is not grok-cli’s managed path |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-cli-interface` | Command table + flags |
| `requirement-shell-cli-zero-arguments` | TTY menu; off-TTY Type O (not checkout `install`) |
| `requirement-project-folder` | Path defaults including Termux `PREFIX` |
| `requirement-shell-termux-coding` | Termux: `USER_BIN` install; `PREFIX/bin` not grok-cli dest |
| `requirement-shell-idempotency` | Already installed / uninstalled |
| `requirement-bootstrap-chain` | Dual-mode: checkout keep; channel from selfmanaged |
| `requirement-shell-online-install` | Channel pipe primary |
| `docs/requirements/index.md` | Registry |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-LC-01..08** | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-09** mode `0755` after install | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-10** mode heal without `--force` | `tests/test_local_lifecycle.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active | Local-only lifecycle for folder-backup |
| 2026-08-09 | Active 1.2.0 | §2.3.1 mode **0755** multi-user; ban `chmod +x`→`0711` trap; AC-6..8; TP-LC-09/10 |
| 2026-09-02 | Active 1.3.0 | Dual-mode secondary: checkout `install` stays offline; channel owned by online-install |
| 2026-09-04 | Active 1.3.1 | Termux: missing `GLOBAL_BIN` does not fail user install; `PREFIX/bin` is not grok-cli dest |

---

**Last Updated**: 2026-09-04  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
