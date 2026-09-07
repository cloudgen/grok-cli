**file**: docs/requirements/requirement-grok-auth-backup.md  
**Status**: Active (Version 1.5.0)  
**Area**: backup  
**Key**: `requirement-grok-auth-backup`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **operations Single Source of Truth** for grok-cli auth handling: how the product **detects a valid grok login**, **copies `~/.grok/auth.*` into `/var/grok-cli`**, **chowns/chmods** that store, how a **normal login syncs those files back** without sudo, and how a login **pulls the same store from another host** over `scp`.

It supersedes folder-archive backup/retention law for this product.

### 1.1 Human-facing

**In one sentence:** do not trust a credential file that only *looks* valid — first ask the installed `grok` program a one-line question (`grok -p hello`); only if grok answers do you treat the login as real, then (for backup) copy `auth.*` into `/var/grok-cli`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Sign in with grok, then check or share the files | `grok login` then `grok-cli check-session` |
| The other role | xAI grok answers `grok -p hello`; sudoer-adm approves passwordless `sudo grok-cli backup` | peer `grok` under `~/.grok/bin` |
| Not this file | How `setup` downloads grok; JSON sudoers schema; help catalog | `requirement-grok-setup` · domain file |

| Includes | Excludes |
|----------|----------|
| Live session probe (`grok -p hello` first); then auth.* glob; deposit dest; ownership/mode; sync-auth dest mode; fail-closed errors | Parsing `auth.json` alone as “logged in”; printing tokens; sudoers JSON schema; help catalog |

| Surface | What you open | What for |
|---------|---------------|----------|
| `grok` | peer program | live `grok -p hello` (never print the answer) |
| `~/.grok/auth.json` | grok credential file | files to copy after the probe (never print tokens) |
| `/var/grok-cli/` | durable store | backup dest / sync-auth source |
| `grok-cli backup` | command | elevated push |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Prove login | grok-cli runs `grok -p hello` first. A file with a future `expires_at` is **not** enough — grok must actually answer. If grok is missing, install it first. | `grok-cli check-session` |
| Share the login | Same live probe, then grok-cli copies `auth.*` to `/var/grok-cli` as root:root mode 0644 | `grok-cli backup` |
| Use the shared login | If grok is **not** already logged in, grok-cli copies those files into your `~/.grok` as 0600, no sudo. If grok **is** logged in, it does not copy | `grok-cli sync-auth` |
| Pull from another host | Same login check; then `scp` that host’s store into your `~/.grok` | `grok-cli sync-auth-from-remote user@192.0.2.10` |

Jargon: you run these commands **as yourself**. The live question is `grok -p hello` (one prompt, then grok exits). grok-cli does **not** print grok’s answer.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Session gate (mandatory before backup)

A file under grok home can look valid while grok cannot talk to xAI (revoked refresh, Termux DNS, wrapper missing, wrong ELF). **MUST NOT** treat `auth.json` parse as logged-in.

1. **MUST** run **`grok -p hello`** **before** any `auth.json` parse, copy, or elev. That live prompt **is** the session check. Operand **MUST** be exactly `-p` then `hello` (one non-interactive prompt).  
2. Peer path **MUST** use the same resolve as `setup` (`GROK_BIN` when set and executable, else `command -v grok`, else `{{GROK_HOME}}/bin/grok`, else `{{USER_BIN}}/grok`). Missing peer **MUST** fail closed. Next: `{{APP_NAME}} setup`, then `grok login`, then `{{APP_NAME}} check-session`.  
3. The probe **MUST** close stdin (`</dev/null`). **MUST NOT** hang under `--json` / off-TTY / the numbered menu waiting for `grok login` or for a child that ignores SIGTERM (Termux `proot` wrapper). **MUST** bound the probe to `GROK_PROMPT_TIMEOUT` seconds (default **20**) even when `timeout` is missing from PATH. When GNU `timeout` is on PATH, **MUST** use kill-after (`timeout -k`; `GROK_PROMPT_KILL_AFTER` seconds; default **2**) so SIGKILL follows SIGTERM. When that `timeout` is missing or does not support kill-after, **MUST** still bound with a POSIX watchdog (background, wait, `kill` then `kill -9`). Timeout or non-zero exit **MUST** fail closed. Next: `grok login`, then `{{APP_NAME}} check-session` (backup: then `{{APP_NAME}} backup`).  
4. **MUST NOT** print grok’s answer, stdout, or stderr to the operator (may contain model text). **MUST NOT** print token, refresh_token, or JWT values. A blocking error **MAY** name `exit N` and a short class (`dns error`, `login required`) without dumping grok output.  
5. Probe success (exit 0) **MUST** mean session **valid** — even if `auth.json` is missing or `expires_at` looks past. Probe failure **MUST** mean **invalid** — even if `auth.json` has a refresh_token and a future `expires_at`.  
6. **MUST** resolve grok home as `GROK_HOME` when set, else `{{invoking-home}}/.grok`. When running as root via sudo, invoking-home **MUST** be `SUDO_USER`’s passwd home (not `/root`) unless `GROK_HOME` is explicit.  
6b. The live probe **MUST** exec `grok -p hello` with **`HOME={{invoking-home}}`** and **`GROK_HOME={{resolved grok home}}`** on that command (not inherited sudo env). `sudo` `env_reset` **MUST NOT** make grok read `/root/.grok` after the unprivileged probe already succeeded. Peer resolve **MUST** still find this login’s `{{invoking-home}}/.local/bin/grok` when root’s `USER_BIN` is `/root/.local/bin`.  
7. `check-session` **MUST** fail closed with an operator-readable next step when the peer is missing (rule 2) or the probe fails (rule 3).  
8. `backup` **MUST** run the same live probe before any copy or elev. After a successful probe, `auth.*` files **MUST** still exist (grok may have refreshed them). Probe success with no `auth.*` **MUST** fail closed. Next: `grok login` so grok writes `auth.json`, then `{{APP_NAME}} backup`.  
9. Menu **logged in** / **logged out** and `about` session **MUST** use this same probe (`gc_session_status_word`: `valid` / `invalid` / `missing` peer). **MUST NOT** hang the menu: same stdin-closed + always-bounded + kill-after rules. A TTY menu reprint after a bad pick **MUST NOT** run a second probe (reuse `GC_SESSION_STATUS_CACHE`).  
10. Core tests **MUST** inject a fake `grok` (`GROK_BIN`) that handles `-p` without the public network. **MUST NOT** run real `grok -p hello` against xAI from Core tests.  
11. Termux writing for this exec (stdin closed, no hang, exec the resolved peer wrapper — not cache/`/tmp`) is **`requirement-shell-termux-coding`**. This file keeps the **session procedure**.

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
2. If that sudo is refused (no passwordless grant), **MUST** fail closed and tell the operator to generate/submit a JSON grant for sudoer-adm. If sudo **did** run the product command and the child failed (for example grok said login required), **MUST NOT** tell the operator the grant is missing. Next: `grok login`, then `{{APP_NAME}} backup`.  
3. As root, the ship unit **MUST** `mkdir` the dest if needed, copy each `auth.*`, `chown root:root`, `chmod 0644` files and `0755` dest.  
4. **MUST NOT** grant OS tools (`cp`, `mkdir`, `chmod`, `chown`) in sudoers; those run **inside** the elevated product command.  
5. A writable `GROK_CLI_ROOT` **outside** `/var/grok-cli` **MAY** accept Type 0 deposit for tests (no chown). Production dest **MUST NOT** skip elev just because it happens to be writable.  
6. Re-running backup **MUST** overwrite the same basenames (idempotent snapshot, no dated tar retention).

### 2.4 sync-auth (no sudo)

1. `sync-auth` **MUST NOT** call `sudo`.  
2. Source is `GROK_CLI_ROOT` (default `/var/grok-cli`). Dest is the invoking login’s grok home.  
2b. **Logged-in skip (mandatory):** **MUST** run the live session probe (`grok -p hello` / `gc_session_status_word`) **before** any copy from the store. When the session is **valid**, **MUST NOT** copy from `/var/grok-cli` (or `GROK_CLI_ROOT`). Print **`No sync-auth for logged-in environment.`** and return success (exit 0). JSON: type `sync-auth`, status `skipped`, `reason` `logged-in`. From the TTY main menu, **MAY** reuse the session word already printed under the title (`GC_SESSION_STATUS_CACHE`) instead of probing a second time. Direct CLI with no cache **MUST** probe. `--force` **MUST NOT** override this skip. The TTY main menu **MUST NOT** list this verb when the session is valid (`requirement-shell-cli-default-interaction` — hide + **append** not-available line).  
3. When the session is **not** valid (invalid / missing peer), **MUST** fail closed if the store is missing, empty, or unreadable without sudo.  
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
5b. Preferred SPEC **MUST** be stored in persistence storage (`requirement-shell-cli-storage`) as leaf **`preferred-remote`** (mode **0600**). After a successful pull, **MUST** save the SPEC that worked. On TTY with no operand, **MUST** load that leaf first (if present and still a valid SPEC). When a preferred value is stored, the prompt **MUST** show it at the **end** of the prompt as the default (`… [user@192.0.2.10]: `). Empty input (Enter) **MUST** use that default. No stored value → no default suffix; empty input still fail-closed. **MUST NOT** treat an invalid stored line as a default.  
6. Transport **MUST** be `scp` in **BatchMode** (no password hang). Override `GROK_CLI_SCP` for tests. Missing `scp` **MUST** fail closed.  
7. Remote source **MUST** be `{{GROK_CLI_REMOTE_ROOT}}/auth.json` (default `/var/grok-cli`). Optional `auth.json.lock` when present.  
8. Dest is this login’s grok home. Dest `auth.json` **MUST** be mode `0600`. Dest dir mode `0700` when created.  
9. **MUST NOT** print token values. JSON **MAY** name host/user/count/paths only.  
10. Core tests **MUST NOT** open a real SSH session.  
11. **Logged-in skip (mandatory):** same gate as §2.4 rule 2b. When the session is **valid**, **MUST NOT** prompt for SPEC, **MUST NOT** `scp`, **MUST NOT** write dest `auth.*`. Print **`No sync-auth for logged-in environment.`** and return success. JSON: type `sync-auth-from-remote`, status `skipped`, `reason` `logged-in`. Menu **MAY** reuse `GC_SESSION_STATUS_CACHE`. `--force` **MUST NOT** override. The TTY main menu **MUST NOT** list this verb when the session is valid (`requirement-shell-cli-default-interaction` — hide + **append** not-available line).

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
| Handlers | `gc_grok_prompt_hello`, `gc_session_status_word`, `gc_session_is_valid`, `gc_sync_skip_if_logged_in`, `gc_check_session`, `gc_backup`, `gc_sync_auth`, `gc_sync_auth_from_remote`, `gc_preferred_remote_load`, `gc_preferred_remote_save` |
| Menu session cache | `GC_SESSION_STATUS_CACHE` set by `app_default_print_menu` (`valid` / `invalid` / `missing`); sync verbs reuse it in the same process |
| Live probe | `grok -p hello` (stdin closed; always bounded; GNU `timeout -k` when it works; else POSIX watchdog; `HOME` + `GROK_HOME` pinned to invoking grok home) |
| Probe timeout | `GROK_PROMPT_TIMEOUT` default `20`; `GROK_PROMPT_KILL_AFTER` default `2` |
| Peer override | `GROK_BIN` (tests **MUST** fake this) |
| Remote pull | `scp -o BatchMode=yes`; `GROK_CLI_SCP` / `GROK_CLI_REMOTE_ROOT` for tests |
| Preferred remote | Persistence leaf `${HOME}/.local/${APP_NAME}/preferred-remote` (helpers `gc_preferred_remote_load` / `gc_preferred_remote_save`) |
| Default grok home | `~/.grok` |
| Default store | `/var/grok-cli` |
| Elevated grant | `NOPASSWD: /usr/local/bin/grok-cli backup` |
| Approver | sibling sudoer-cli inbound; sudoer-adm |
| Retention | none (single snapshot overwrite) |

### 2.7 Why This Requirement Exists (CIAO)

- **Principle 1 – Caution**: Fail closed unless `grok -p hello` succeeds; fail closed without an approved elev; never hang.  
- **Principle 10 – Least privilege**: Only the product command is elevated; sync-auth stays a normal login.  
- **Principle 16 – Interactive vs non-interactive**: Probe closes stdin; no login prompt under `--json` / pipes / menu.  
- **Principle 22 – File modes**: Store is world-readable by design; home copies return to `0600`.

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

**This requirement:** `/var/grok-cli` deposit stays **unused** on this class. `check-session` and `sync-auth-from-remote` (preferred SPEC in persistence) stay this-login work. Menu honesty for unused backup / sync-auth / sudoers is `requirement-shell-cli-default-interaction`.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Never print secrets; never skip the live `grok -p hello` gate; never hang.  
- **Intentional:** Push (elevated) and pull (unprivileged) are different verbs. File parse is not “logged in.”  
- **Anti-fragile:** `GROK_HOME` / `GROK_CLI_ROOT` / `GROK_BIN` / `GROK_PROMPT_TIMEOUT` overrides keep tests off `/var` and off xAI.  
- **Over-protect:** Production dest always requires the grant; OS-tool sudoers are forbidden.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Elevate `sync-auth` or `sync-auth-from-remote`, or grant `chmod`/`cp` as sudoers Cmnds.  
2. Skip the live `grok -p hello` session gate on backup or `check-session`.  
2b. Run the live probe as root against `/root/.grok` when `SUDO_USER` is a normal login (sudo `env_reset` / `HOME=/root`).  
3. Treat `auth.json` parse (refresh_token / `expires_at` / `key`) as logged-in without a successful `grok -p hello`.  
4. Print grok’s `-p hello` answer, tokens, refresh_token, or JWT values.  
5. Hang under `--json` / off-TTY / menu waiting for an interactive `grok login`, or freeze the menu because `timeout` is missing or the peer ignores SIGTERM (no kill-after / no watchdog).  
6. Hit xAI from Core tests (must fake `GROK_BIN`).  
7. Leave store files owner-only (`0600`) so other logins cannot sync-auth.  
8. Restore folder-archive tar.gz behavior as this product’s backup.

---
9. Strip the **Under command line for normal user only** section, or enable admin privilege / a dedicated system user on Termux / Git Bash / Windows cmd.  
10. Skip saving a successful `sync-auth-from-remote` SPEC to persistence `preferred-remote`, or prompt without showing a stored SPEC at the **end** of the prompt (empty Enter must use that default).  
11. Copy `sync-auth` / `sync-auth-from-remote` into a grok home whose live `grok -p hello` session is already **valid**, or omit the **`No sync-auth for logged-in environment.`** message on that skip.  


## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Missing peer grok → check-session and backup fail closed with Next `{{APP_NAME}} setup` then `grok login` |
| AC-2 | `grok -p hello` non-zero / timeout → check-session and backup fail closed with Next `grok login` (even if `auth.json` looks valid) |
| AC-3 | `grok -p hello` exit 0 → check-session exit 0 (live probe wins over `expires_at`) |
| AC-4 | Probe success + writable test `GROK_CLI_ROOT` + `auth.*` → backup copies `auth.*` mode 0644 |
| AC-5 | Probe runs **before** any `auth.json` parse; stdin closed; Core tests fake `GROK_BIN` (no public network) |
| AC-6 | Production `/var/grok-cli` as non-root uses `sudo -n /usr/local/bin/grok-cli backup` |
| AC-7 | JSON grant names backup only |
| AC-8 | sync-auth copies into grok home mode 0600 without sudo |
| AC-9 | `sync-auth-from-remote` accepts the four SPEC forms; dest `auth.json` is 0600; no sudo; Core tests use a fake `scp` |
| AC-10 | TTY menu `sync-auth-from-remote` row (main **3**) shows a visible SPEC prompt; SPEC is `PROMPT_ASK_VALUE` (not `$()`); TP-GROK-CLI-34 · TP-CLI-15 (INC-20260902-001) |
| AC-11 | Menu **logged in** only after probe success; **logged out** when peer missing or probe fails; MUST NOT hang |
| AC-17 | Peer that ignores SIGTERM still fail-closes within `GROK_PROMPT_TIMEOUT` + kill-after (no menu freeze); GNU `timeout -k` or POSIX watchdog (TP-GROK-CLI-44 · TP-GROK-CLI-45 · TP-CLI-21) |
| AC-12 | grok `-p hello` stdout/stderr is not printed (no token leak) |
| AC-13 | Elevated backup (`uid 0` + `SUDO_USER`) probe uses invoking grok home, not `/root/.grok` (TP-GROK-CLI-39) |
| AC-14 | When the passwordless grant already ran and the child failed, Next is `grok login` then backup — **MUST NOT** `generate-sudoer-request` (TP-GROK-CLI-40) |
| AC-15 | Successful `sync-auth-from-remote` saves SPEC to persistence `preferred-remote`; TTY prompt shows stored SPEC at the end of the prompt; Enter uses that default (TP-GROK-CLI-41) |
| AC-16 | Valid live session → `sync-auth` and `sync-auth-from-remote` do not copy; print **`No sync-auth for logged-in environment.`**; exit 0 (TP-GROK-CLI-42 · TP-GROK-CLI-43) |

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
| `docs/requirements/requirement-shell-termux-coding.md` | Termux host writing for the probe exec |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Menu **logged in** / **logged out** uses this probe |
| `./src/grok-cli` | Implementation |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-22 | Active (1.0.0) | Grok auth backup/sync ops; replaces folder-archive backup |
| 2026-09-02 | Active (1.1.0) | `sync-auth-from-remote` four SPEC forms; fake scp in Core tests |
| 2026-09-02 | Active (1.1.1) | TTY SPEC prompt must be visible (INC-20260902-001); AC-7; TP-GROK-CLI-34 |
| 2026-09-02 | Active (1.1.2) | TTY SPEC prompt uses `PROMPT_ASK_VALUE`; no `$()` of `prompt_ask` |
| 2026-09-03 | Active (1.1.3) | AC-7 locator is main-menu **3** (`sync-auth-from-remote`); pick **4** is `add-crontab` |
| 2026-09-05 | Active (1.2.0) | Session gate is live `grok -p hello` **before** any `auth.json` parse; file-only check is not logged-in |
| 2026-09-06 | Active (1.2.1) | Elevated probe pins `HOME`/`GROK_HOME` to `SUDO_USER` (not `/root`); grant-present child fail is not “sudo refused” |
| 2026-09-07 | Active (1.3.0) | Preferred remote SPEC in persistence; TTY prompt default at end of prompt; Enter uses stored value |
| 2026-09-07 | Active (1.4.0) | `sync-auth` / `sync-auth-from-remote` skip copy when grok is already logged in; reuse main-menu session cache |
| 2026-09-07 | Active (1.4.1) | Dual mention: TTY main menu hides these two verbs when logged in and appends the not-available line |
| 2026-09-07 | Active (1.5.0) | Probe always bounded; GNU `timeout -k` (SIGKILL follow-up) or POSIX watchdog; Termux menu must not freeze when grok/proot ignores SIGTERM |

---


## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-GROK-CLI-03**–**10**, **12** | `tests/test_domain_grok_cli.sh` | have |
| **TP-GROK-CLI-30**–**34** | `tests/test_domain_grok_cli.sh` | have |
| **TP-GROK-CLI-35**–**38** | `tests/test_domain_grok_cli.sh` | have (live `grok -p hello` gate; fake `GROK_BIN`; no token leak) |
| **TP-GROK-CLI-39** | `tests/test_domain_grok_cli.sh` | have (elevated probe uses `SUDO_USER` grok home, not `/root`) |
| **TP-GROK-CLI-40** | `tests/test_domain_grok_cli.sh` | have (grant present + child fail is not generate-sudoer-request) |
| **TP-GROK-CLI-41** | `tests/test_domain_grok_cli.sh` | have (preferred remote SPEC persisted; TTY prompt shows `[SPEC]` default; Enter uses it) |
| **TP-GROK-CLI-42** | `tests/test_domain_grok_cli.sh` | have (`sync-auth` skip when session valid; dest unchanged; menu hides the row) |
| **TP-GROK-CLI-43** | `tests/test_domain_grok_cli.sh` | have (`sync-auth-from-remote` skip when session valid; no scp) |
| **TP-GROK-CLI-44** | `tests/test_domain_grok_cli.sh` | have (SIGTERM-ignoring grok fail-closes; GNU `timeout -k`; no freeze) |
| **TP-GROK-CLI-45** | `tests/test_domain_grok_cli.sh` | have (same hang without GNU `timeout -k`; POSIX watchdog) |
| **TP-CLI-06**, **TP-CLI-17** | `tests/test_cli.sh` | have (about session; menu logged in/out uses probe) |
| **TP-CLI-21** | `tests/test_cli.sh` | have (Termux menu with hanging grok still prints the list and accepts Exit) |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-07 (1.5.0 — always-bounded probe; `timeout -k` / watchdog)  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
