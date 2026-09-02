**file**: docs/requirements/requirement-grok-auth-backup.md  
**Status**: Active (Version 1.1.2)  
**Area**: backup  
**Key**: `requirement-grok-auth-backup`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **operations Single Source of Truth** for grok-cli auth handling: how the product **detects a valid grok login**, **copies `~/.grok/auth.*` into `/var/grok-cli`**, **chowns/chmods** that store, how a **normal login syncs those files back** without sudo, and how a login **pulls the same store from another host** over `scp`.

It supersedes folder-archive backup/retention law for this product.

### 1.1 Human-facing

This file says: do not copy grok auth until the login is real; only an approved passwordless `sudo grok-cli backup` may write `/var/grok-cli`; any login may then `sync-auth` from that folder.

| You | Another role | Not this |
|-----|--------------|----------|
| `grok login`, then `grok-cli backup` / `sync-auth` / `sync-auth-from-remote SPEC` | sudoer-adm approves the JSON grant; root via that grant chowns the store | tar.gz of a project folder; granting `cp`/`chmod` as extra sudoers tools |

**Includes:** session gate, auth.* glob, deposit dest, ownership/mode, sync-auth dest mode, fail-closed errors.  
**Excludes:** sudoers JSON schema; help catalog (domain file).

| Surface | What you open | What for |
|---------|---------------|----------|
| `~/.grok/auth.json` | grok credential file | session check (never print tokens) |
| `/var/grok-cli/` | durable store | backup dest / sync-auth source |
| `grok-cli backup` | command | elevated push |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Prove login | grok-cli reads `auth.json` and refuses expired/empty credentials | `grok-cli check-session` |
| Share the login | grok-cli copies `auth.*` to `/var/grok-cli` as root:root mode 0644 | `grok-cli backup` |
| Use the shared login | grok-cli copies those files into your `~/.grok` as 0600, no sudo | `grok-cli sync-auth` |
| Pull from another host | grok-cli `scp`s that host’s `/var/grok-cli/auth.*` into your `~/.grok` | `grok-cli sync-auth-from-remote user@192.0.2.10` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Session gate (mandatory before backup)

1. **MUST** treat a valid grok session as: `auth.json` exists under the invoking login’s grok home **and** at least one credential is usable (non-empty `refresh_token`, or `expires_at` still in the future, or a present access `key` when no expiry is recorded).  
2. **MUST** resolve grok home as `GROK_HOME` when set, else `{{invoking-home}}/.grok`. When running as root via sudo, invoking-home **MUST** be `SUDO_USER`’s passwd home (not `/root`) unless `GROK_HOME` is explicit.  
3. **MUST NOT** print token, refresh_token, or JWT values.  
4. `check-session` **MUST** fail closed with an operator-readable next step (`grok login`) when missing or invalid.  
5. `backup` **MUST** run the same gate before any copy or elev.

### 2.2 Source files

1. Source set is regular files matching `auth.*` under grok home (including `auth.json` and `auth.json.lock` when present).  
2. **MUST** fail closed if no `auth.*` files exist after a valid session check.  
3. **MUST NOT** copy directories or follow a symlink dest for deposit.

### 2.3 Durable store

| Item | Value |
|------|--------|
| Default dest | `/var/grok-cli` |
| Override | `GROK_CLI_ROOT` (tests / non-production) |
| Directory mode (root deposit) | `0755` |
| File mode (store) | `0644` (world-readable so `sync-auth` needs no sudo) |
| Ownership (root deposit) | `root:root` |

1. Writing the **production** dest (`/var/grok-cli` or a path under it) as a non-root login **MUST** re-exec `sudo -n {{GLOBAL_BIN}}/grok-cli backup` (exact grant; no extra flags on the sudo command line).  
2. If that sudo is refused, **MUST** fail closed and tell the operator to generate/submit a JSON grant for sudoer-adm.  
3. As root, the ship unit **MUST** `mkdir` the dest if needed, copy each `auth.*`, `chown root:root`, `chmod 0644` files and `0755` dest.  
4. **MUST NOT** grant OS tools (`cp`, `mkdir`, `chmod`, `chown`) in sudoers; those run **inside** the elevated product command.  
5. A writable `GROK_CLI_ROOT` **outside** `/var/grok-cli` **MAY** accept Type 0 deposit for tests (no chown). Production dest **MUST NOT** skip elev just because it happens to be writable.  
6. Re-running backup **MUST** overwrite the same basenames (idempotent snapshot, no dated tar retention).

### 2.4 sync-auth (no sudo)

1. `sync-auth` **MUST NOT** call `sudo`.  
2. Source is `GROK_CLI_ROOT` (default `/var/grok-cli`). Dest is the invoking login’s grok home.  
3. **MUST** fail closed if the store is missing, empty, or unreadable without sudo.  
4. **MUST** create dest grok home if needed (dir mode `0700` when possible).  
5. Dest `auth.json` **MUST** be mode `0600` after copy.

### 2.4b sync-auth-from-remote (no sudo)

1. **MUST** route **`sync-auth-from-remote`**. Dual mention: this file **and** `requirement-shell-cli-interface`.  
2. **MUST** be Type 0. **MUST NOT** call `sudo`.  
3. Operand **SPEC** **MUST** be exactly one of:
   - `{{user}}@{{ipv4}}` (example shape `user@192.0.2.10`)
   - `{{ipv4}}` (example shape `192.0.2.10`)
   - `{{domain-name}}` (example shape `host.example.com`)
   - `{{user}}@{{domain-name}}` (example shape `user@host.example.com`)
4. When SPEC has no `user@`, SSH **MUST** use the invoking login / ssh config (do not invent a Unix login).  
5. **MUST** reject empty SPEC, extra `@`, paths, and shell metacharacters. Off-TTY missing SPEC **MUST** fail closed with Next: `grok-cli sync-auth-from-remote USER@HOST`. On TTY with no operand, **MAY** prompt for SPEC via current-shell `prompt_ask` + `PROMPT_ASK_VALUE` (**MUST NOT** `_spec=$(prompt_ask …)` — INC-20260902-001).  
6. Transport **MUST** be `scp` in **BatchMode** (no password hang). Override `GROK_CLI_SCP` for tests. Missing `scp` **MUST** fail closed.  
7. Remote source **MUST** be `{{GROK_CLI_REMOTE_ROOT}}/auth.json` (default `/var/grok-cli`). Optional `auth.json.lock` when present.  
8. Dest is this login’s grok home. Dest `auth.json` **MUST** be mode `0600`. Dest dir mode `0700` when created.  
9. **MUST NOT** print token values. JSON **MAY** name host/user/count/paths only.  
10. Core tests **MUST NOT** open a real SSH session.

### 2.5 Invocation samples (dual mention)

```text
grok-cli check-session
grok-cli backup
grok-cli sync-auth
grok-cli sync-auth-from-remote user@192.0.2.10
grok-cli sync-auth-from-remote 192.0.2.10
grok-cli sync-auth-from-remote host.example.com
grok-cli sync-auth-from-remote user@host.example.com
```

### 2.6 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Product | `grok-cli` |
| Handlers | `gc_check_session`, `gc_backup`, `gc_sync_auth`, `gc_sync_auth_from_remote` |
| Remote pull | `scp -o BatchMode=yes`; `GROK_CLI_SCP` / `GROK_CLI_REMOTE_ROOT` for tests |
| Default grok home | `~/.grok` |
| Default store | `/var/grok-cli` |
| Elevated grant | `NOPASSWD: /usr/local/bin/grok-cli backup` |
| Approver | sibling sudoer-cli inbound; sudoer-adm |
| Retention | none (single snapshot overwrite) |

### 2.7 Why This Requirement Exists (CIAO)

- **Principle 1 – Caution**: Fail closed without a valid session or without an approved elev.  
- **Principle 10 – Least privilege**: Only the product command is elevated; sync-auth stays a normal login.  
- **Principle 22 – File modes**: Store is world-readable by design; home copies return to `0600`.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Never print secrets; never skip the session gate.  
- **Intentional:** Push (elevated) and pull (unprivileged) are different verbs.  
- **Anti-fragile:** `GROK_HOME` / `GROK_CLI_ROOT` overrides keep tests off `/var`.  
- **Over-protect:** Production dest always requires the grant; OS-tool sudoers are forbidden.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Elevate `sync-auth` or `sync-auth-from-remote`, or grant `chmod`/`cp` as sudoers Cmnds.  
2. Skip the session gate on backup.  
3. Leave store files owner-only (`0600`) so other logins cannot sync-auth.  
4. Copy tokens into help/about/JSON logs.  
5. Restore folder-archive tar.gz behavior as this product’s backup.

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Missing/expired auth.json → check-session and backup fail closed with `grok login` next step |
| AC-2 | Valid session + writable test `GROK_CLI_ROOT` → backup copies `auth.*` mode 0644 |
| AC-3 | sync-auth copies into grok home mode 0600 without sudo |
| AC-4 | Production `/var/grok-cli` as non-root uses `sudo -n /usr/local/bin/grok-cli backup` |
| AC-5 | JSON grant names backup only |
| AC-6 | `sync-auth-from-remote` accepts the four SPEC forms; dest `auth.json` is 0600; no sudo; Core tests use a fake `scp` |
| AC-7 | TTY menu pick 4 shows a visible SPEC prompt; SPEC is `PROMPT_ASK_VALUE` (not `$()`); TP-GROK-CLI-34 · TP-CLI-15 (INC-20260902-001) |

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-domain-grok-cli.md` | Domain surface |
| `docs/requirements/requirement-three-layer-privilege-model.md` | Elev workflow |
| `docs/requirements/requirement-sudoer-json-file.md` | Grant body |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention |
| `docs/requirements/requirement-grok-setup.md` | Peer `grok` installer (`setup`) before login |
| `./src/grok-cli` | Implementation |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-22 | Active (1.0.0) | Grok auth backup/sync ops; replaces folder-archive backup |
| 2026-09-02 | Active (1.1.0) | `sync-auth-from-remote` four SPEC forms; fake scp in Core tests |
| 2026-09-02 | Active (1.1.1) | TTY SPEC prompt must be visible (INC-20260902-001); AC-7; TP-GROK-CLI-34 |
| 2026-09-02 | Active (1.1.2) | TTY SPEC prompt uses `PROMPT_ASK_VALUE`; no `$()` of `prompt_ask` |

---


## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-GROK-CLI-03**–**10**, **12** | `tests/test_domain_grok_cli.sh` | have |
| **TP-GROK-CLI-30**–**34** | `tests/test_domain_grok_cli.sh` | have |
| **TP-CLI-06** | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-02  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
