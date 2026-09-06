**file**: docs/requirements/requirement-shell-cli-storage.md  
**Status**: Active (Version 1.2.1)  
**Area**: shell  
**Key**: `requirement-shell-cli-storage`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **shell CLI storage** of grok-cli. **Storage** means **two** classes:

| Class | Role | Survives reboot |
|-------|------|-----------------|
| **Cache folder** | Volatile scratch / temps / staging | No (shm/tmp) or maybe (XDG fallback) |
| **Persistence storage** | Type 0 durable per-user app data | Yes (under this login’s `$HOME`) |

It owns path **shapes**, central resolvers, `app_main` wire, and about diagnostics for both classes.

Used for **volatile temps** (mktemp, grant convert scratch) and **tar.gz staging** before elevated deposit into `/var/grok-cli`. Persistence is **not** that deposit.

The preferred cache is **not** a ram-drive **project** tree (`/dev/shm/<project>`). It lives under `/dev/shm/cache/` so `about` and the filesystem do not look like a grok-cli workspace.

---

### 1.1 Human-facing

Scratch goes in a cache folder. Durable app data for this login goes under persistence storage. `/var/grok-cli` is the shared host store, not your personal folder.

| You | Another role | Not this |
|-----|--------------|----------|
| Let the CLI pick cache + persistence | `/var/grok-cli` is the shared host store (passwordless `sudo grok-cli backup`) | Putting tokens in `/tmp` with a guessed name; treating `~/.local/bin` as data |

**Includes:** cache resolver, persistence resolver, about fields. **Excludes:** deposit chown; install binary placement.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Inspect storage | about shows Cache folder (preferred)/(fallback) **and** Persistence storage | `grok-cli about` / `grok-cli --json about` |


## 2. Core Rules / Requirements (Mandatory)

### 2.1 Two storage classes (mandatory split)

| Class | Path shape | Helper |
|-------|------------|--------|
| Cache folder (preferred) | `/dev/shm/cache/cache-${APP_NAME}` | `util_preferred_cache_dir` |
| Cache folder (tmp) | `/tmp/cache/cache-${APP_NAME}` | live resolve only |
| Cache folder (fallback) | `${XDG_CACHE_HOME:-${HOME}/.cache}/cache-${APP_NAME}` | `util_fallback_cache_dir` |
| Persistence storage | `${HOME}/.local/${APP_NAME}` | `util_persistent_storage_dir` |

Live chosen **cache** root: `util_resolve_storage` (stdout).  
Live **persistence** root: `util_resolve_persistent_storage` (stdout; create-before-return).

On Termux/Android, the chosen cache root (including `/tmp` and `/dev/shm`) **MAY** be **`noexec`**. Cache remains scratch **only**. **MUST NOT** smoke or `exec` a downloaded binary from the cache root — that writing rule is **`requirement-shell-termux-coding`**; the smoke directory is `{{GROK_HOME}}/downloads` (`requirement-grok-setup` / `requirement-project-folder`).

**MUST NOT** mix these with:

| Forbidden as this product’s storage | Why |
|-------------------------------------|-----|
| `${HOME}/.local/bin` / `USER_BIN` | Install binary dir |
| `/var/grok-cli` / `GROK_CLI_ROOT` | Type 1 durable deposit (privilege law) |
| `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` | Looks like a ram-drive project folder |
| `${HOME}/.local/share/${APP_NAME}` | Not this product’s persistence shape |

Config drafts stay under `${HOME}/.config/${APP_NAME}/` (sudoers fragment / JSON grant). That is **config**, not cache and not persistence.

### 2.2 Single cache resolver SSOT

1. **MUST** keep **one** authoritative cache-resolve helper: **`util_resolve_storage`**.  
2. New code that needs a product scratch/cache **root** **MUST** call `util_resolve_storage` (or `mktemp` under a path it returned).  
3. Resolver **MUST** print the chosen directory path on **stdout** for `$(util_resolve_storage)` capture.  
4. User-visible failure about cache **MUST** use Output SSOT.

Preferred and fallback **path shapes** **MUST** be `util_preferred_cache_dir` and `util_fallback_cache_dir` (or the same literals those helpers print).

### 2.3 Live cache resolve priority

First match that can be created **and** is writable:

| Order | Condition | Path shape |
|-------|-----------|------------|
| 1 (preferred) | `/dev/shm` exists and is writable | `/dev/shm/cache/cache-${APP_NAME}` |
| 2 | `/tmp` is writable | `/tmp/cache/cache-${APP_NAME}` |
| 3 (fallback) | User cache | `STORAGE_DIR` (`${XDG_CACHE_HOME:-${HOME}/.cache}/cache-${APP_NAME}`, env-overridable) |

**Parent:** for shm/tmp tiers the resolver **MUST** create `/dev/shm/cache` or `/tmp/cache` (prefer mode **1777** when creating) so other logins can add sibling `cache-<app>` directories.

**Create before return:** for the **chosen** leaf, the resolver **MUST** `mkdir -p` it, confirm it is **writable**, then print the path. If create/write fails → try the next tier. If none work → **MUST** fail closed. **MUST NOT** return a path without creating it.

**MUST NOT** use these as cache:

| Forbidden cache path | Why |
|----------------------|-----|
| `/dev/shm/${APP_NAME}` | Looks like a ram-drive project folder |
| `/dev/shm/${APP_NAME}-${USERNAME}` | Same confusion; username in the shm leaf is withdrawn |
| `/dev/shm` or `/tmp` as a dump | No app-named cache leaf |
| Persistence storage | Durable data is not scratch |

### 2.4 Cache isolation

1. Cache leaves **MUST** include **`cache-${APP_NAME}`** (app identity).  
2. Preferred shm path **MUST NOT** include `${USERNAME}` (that made the dest look like a ram-drive login folder). Isolation is: sticky `…/cache/` parent + this login’s leaf (if another owner holds the leaf, fall through) + fallback under this login’s `$HOME`.  
3. **MUST NOT** use a single shared world-writable directory for all apps.  
4. Live product **MUST** export `TMPDIR=${EFFECTIVE_STORAGE_DIR}` so `mktemp` inherits the isolated **cache** root.  
5. New scratch files **MUST** be created via **`util_mktemp`** (or `mktemp` under a path `util_resolve_storage` returned).  
6. **MUST NOT** use predictable `$$` names (forbidden: `/tmp/${APP_NAME}.$$`, `${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.$$`).

**Complete `util_mktemp` sample:**

```sh
util_mktemp() {
    : "${APP_NAME:=grok-cli}"
    : "${EFFECTIVE_STORAGE_DIR:=}"
    _suffix="${1:-tmp}"
    case "${_suffix}" in
        *\$\$*) out_die "util_mktemp: refuse predictable \$\$ name template" ;;
    esac
    if [ -z "${EFFECTIVE_STORAGE_DIR}" ]; then
        EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)
        export EFFECTIVE_STORAGE_DIR
    fi
    mktemp "${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.${_suffix}.XXXXXX" \
        || mktemp
}
```

**Forbidden:**

```sh
# MUST NOT
tmp="/tmp/${APP_NAME}.$$"
tmp="${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.$$"
```

### 2.5 Persistence storage

1. Persistence **MUST** be **`${HOME}/.local/${APP_NAME}`** (this login’s home + app name).  
2. Helper **`util_persistent_storage_dir`** **MUST** print that path. **`util_resolve_persistent_storage`** **MUST** `mkdir -p` it, confirm it is writable, then print it (fail closed).  
3. **MUST NOT** use `${HOME}/.local/bin` as persistence (that is `USER_BIN`).  
4. **MUST NOT** use `/var/grok-cli` as Type 0 persistence.  
5. **MUST NOT** store scratch/temps in persistence when a cache root is available.  
6. Persistence **MUST** be under the invoking login’s `$HOME` (per-user). **MUST** include `${APP_NAME}`.

### 2.6 Wire and diagnostics

| Surface | Requirement |
|---------|-------------|
| `app_main` | Resolve once early: `EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)`; `PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)`; export `EFFECTIVE_STORAGE_DIR`, `STORAGE_DIR`, `PERSISTENT_STORAGE_DIR`, `TMPDIR` (`TMPDIR` = cache root) |
| `app_about` human | **MUST** print **`Cache folder (preferred):`** then `/dev/shm/cache/cache-${APP_NAME}`; **MUST** print **`Cache folder (fallback):`** then the XDG `cache-${APP_NAME}` path; **MUST** print **`Persistence storage:`** then `${HOME}/.local/${APP_NAME}`. **MUST NOT** label cache lines **Storage (effective)** or **Storage (fallback)** |
| `app_about` JSON | **MUST** include `cache_preferred`, `cache_fallback`, `persistence_storage`, and the live chosen cache root as `effective_storage` (plus `storage_dir` = cache fallback). **MUST NOT** include `CHECKSUM` |
| Domain `backup` | Stage archives under effective **cache**; clean up on exit |

### 2.7 Staging rules for backups

1. Create archives in a stage directory under `EFFECTIVE_STORAGE_DIR` (e.g. `.../stage/`).  
2. Use restrictive modes appropriate for user data (prefer not world-readable when content may be sensitive).  
3. **MUST** remove staging artifacts via `trap` on success and failure after deposit attempt completes (or fails closed with path logged).  
4. Durable deposit path `/var/grok-cli` is **not** the cache or persistence resolver’s job (privilege + domain law).

### 2.8 Implementation Notes (this project)

| Item | Live value |
|------|------------|
| **Product / binary** | `grok-cli` |
| **Cache resolver** | `util_resolve_storage` in `src/grok-cli` |
| **Preferred cache** | `/dev/shm/cache/cache-grok-cli` |
| **Fallback cache** | `${XDG_CACHE_HOME}/cache-grok-cli` |
| **Persistence** | `${HOME}/.local/grok-cli` |
| **Persistence resolver** | `util_resolve_persistent_storage` |
| **Call sites** | `app_main`, `app_about`, domain staging (cache) |
| **Not used for** | Durable `/var/grok-cli` deposit; install `~/.local/bin`; ram-drive project dests |

### 2.9 Why This Requirement Exists (CIAO)

- **Caution:** Multi-user isolation without looking like a project tree on tmpfs; durable Type 0 data is not mixed with bins or Type 1 deposit.  
- **Intentional:** Storage = cache folder **and** persistence storage; about says both.  
- **Anti-fragile:** Missing `/dev/shm` still works.  
- **Principle 11 – Temps:** Cleanup, not museum copies of staging.

---

## Under command line for normal user only

When grok-cli runs on Termux, Git Bash, Windows cmd, or the same class (this login only — no root, no dedicated system account):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** only | Enable **admin privilege** (`sudo`, write `/etc`) or a **dedicated system user** |
| Treat admin-privilege and dedicated-account work as **unused** | Wrap `apt` / `dnf` / `yum`; `useradd`; recommend `sudo curl \| sh` |
| Termux: `pkg` as this login stays ordinary-user work | Recommend `sudo curl \| sh` as the install path |
| Git Bash and Windows cmd: same ceiling | Invoke Termux `pkg` because those hosts were detected |

Detect: Termux — `uname` contains Android, or `PREFIX` / `TERMUX_VERSION` is set. Git Bash — `MSYSTEM` or `uname -s` is MINGW*/MSYS*. Windows cmd — `OS=Windows_NT` after excluding Git Bash, Cygwin, and WSL.

**This requirement:** cache and persistence stay under this login. Do not resolve scratch into `/etc`.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- Volatile cache first, user cache last for scratch.  
- Persistence is under `$HOME/.local/${APP_NAME}`, not under `bin` or `/var`.  
- Isolation before convenience.  
- Create fail-closed in the resolvers.  
- Cache path family is distinct from ram-drive **project** folders.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Restore `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` as the preferred cache.  
2. Label about cache lines **Storage (effective)** / **Storage (fallback)** instead of **Cache folder (preferred)** / **Cache folder (fallback)**.  
3. Drop persistence storage from this requirement or from `about`.  
4. Use `${HOME}/.local/bin` or `/var/grok-cli` as Type 0 persistence.  
5. Replace the cache fallback chain with a shared world-writable dump.  
6. Scatter hard-coded `/tmp/grok-cli` roots outside the cache resolver.  
7. Leave the resolvers dead with no call sites while claiming storage is product law.  
8. Echo a tier path without creating it.  
9. Stage durable deposits only in world-writable shared paths by design.  
10. Use predictable `$$` scratch names instead of `util_mktemp` / `mktemp` XXXXXX.  
11. Smoke or `exec` a downloaded binary from the cache folder, `/tmp`, or `/dev/shm` on Termux (`requirement-shell-termux-coding`).

12. Strip the **Under command line for normal user only** section, or enable admin privilege / a dedicated system user on Termux / Git Bash / Windows cmd.  

**Violating this rule is a critical cache isolation / honesty regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Exactly one authoritative cache resolver creates and returns the cache root |
| AC-2 | Preferred cache leaf is `/dev/shm/cache/cache-${APP_NAME}` when shm is usable |
| AC-3 | `app_main` sets `EFFECTIVE_STORAGE_DIR` / `TMPDIR` / `PERSISTENT_STORAGE_DIR` early |
| AC-4 | `about` human uses Cache folder (preferred)/(fallback) and Persistence storage; JSON has `cache_preferred` / `cache_fallback` / `persistence_storage` |
| AC-5 | Scratch files use `util_mktemp` / `mktemp` XXXXXX; no `$$` names |
| AC-6 | Live cache path is not `/dev/shm/${APP_NAME}-${USERNAME}` |
| AC-7 | Persistence path is `${HOME}/.local/${APP_NAME}` and the directory exists after resolve |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-project-folder` | Path classes; install bin vs persistence vs deposit |
| `requirement-shell-termux-coding` | Cache/`tmp`/`shm` are not exec paths on Termux |
| `requirement-domain-grok-cli` | Staging use |
| `requirement-shell-cli-interface` | About fields |
| `requirement-shell-local-self-management` | `USER_BIN` is not persistence |
| `docs/requirements/index.md` | Registry |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-06** | `tests/test_cli.sh` | **have** — about JSON cache + persistence fields + human labels |
| **TP-CLI-12** | same | **have** — preferred cache `/dev/shm/cache/cache-${APP_NAME}`; persistence `${HOME}/.local/${APP_NAME}`; live dirs exist; cache not APP-USERNAME shape |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active | Storage resolve for folder-backup staging |
| 2026-08-15 | Active | `util_mktemp` sample; forbid `$$` scratch names |
| 2026-08-30 | Active 1.1.0 | Preferred `/dev/shm/cache/cache-${APP_NAME}`; about Cache folder labels |
| 2026-08-30 | Active 1.2.0 | Storage = cache folder **and** persistence `${HOME}/.local/${APP_NAME}` |
| 2026-09-04 | Active 1.2.1 | Termux: cache/`tmp`/`shm` may be `noexec` — not a smoke path (point `requirement-shell-termux-coding`) |

---

**Last Updated**: 2026-09-06  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
