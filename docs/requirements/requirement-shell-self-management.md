**file**: docs/requirements/requirement-shell-self-management.md  
**Status**: Active (Version 1.3.0)  
**Area**: shell  
**Key**: `requirement-shell-self-management`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **remote lifecycle Single Source of Truth** for grok-cli after channel install: `version-check`, `self-update`, and `self-uninstall`. `about` stays on the CLI interface; it **MUST** show the channel URL. Channel place is `requirement-shell-online-install`. Checkout remove `uninstall` stays on `requirement-shell-local-self-management` (dual-mode: both remove the managed binary).

### 1.1 Human-facing

**In one sentence:** after curl install you can ask whether a newer grok-cli exists, pull it, or remove the managed binary.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Type the lifecycle verbs | `grok-cli version-check` |
| The other role | Channel hosts `src/grok-cli` | github raw |
| Not this file | Daily auth backup; TTY menu | `grok-cli backup` |

| Includes | Excludes |
|----------|----------|
| version-check; self-update; self-uninstall | Menu rows; sudoers |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| See local vs remote | Compare VERSION strings | `grok-cli version-check` |
| Pull a newer build | Re-download `SCRIPT_URL` | `grok-cli self-update` |
| Remove the binary | Same as `uninstall` | `grok-cli self-uninstall --force` |

---

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** route `version-check`, `self-update`, `self-uninstall` from `app_main`. Dual mention: this file **and** `requirement-shell-cli-interface`.  
2. `version-check` **MUST** fetch remote `VERSION=` from `SCRIPT_URL` and compare with `inst_get_version`. Unreachable channel **MUST NOT** say “already latest.”  
3. `self-update` **MUST** reuse `inst_perform_channel_install` with force when remote is newer, or when `--force`. **MUST NOT** downgrade without `--force`.  
3b. The first human INFO line of a **proceeding** `self-update` **MUST** name both versions, after remote `VERSION=` is known: `Starting the self-update of {{APP_NAME}}({{local}}) to new version:{{remote}}...` (`{{local}}` = `inst_get_version`; `{{remote}}` = channel `VERSION=`). **MUST** fetch remote first. **MUST NOT** print a version-less start line (`Starting self-update of {{APP_NAME}}...`). Fetch fail **MUST** fail closed with Next (no start line). Already-at-remote without `--force` **MUST NOT** print that start line. Dual mention: `requirement-shell-cli-interface`.  
3c. After a **proceeding** `self-update` **and** on the already-at-remote success path, **MUST** rewrite a stale Android `bin/grok` wrapper (`gc_setup_heal_android_wrapper`) with no vendor re-download. Dual mention: `requirement-grok-setup` 18e. **MUST NOT** require the operator to type `setup` to receive wrapper hang fixes after `self-update`.  
4. `self-uninstall` **MUST** remove the managed binary (same dest as `uninstall`). Interactive confirm unless `--force` / off-TTY. Already absent → success. User-bin: PATH cleanup call `inst_self_uninstall_cleanup_path` — **what** may be edited in rc is `requirement-shell-path-and-shell-support`.
5. **MUST NOT** appear on the TTY numbered main menu.  
6. Core tests fake the channel.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Handlers | `ver_check` · `inst_self_update` · `inst_self_uninstall` |
| Channel | `SCRIPT_URL` as in online-install |
| Compare | `ver_gt` POSIX |
| **PATH / login rc** | **Call site only:** `self-update` reuses channel place (companion). `self-uninstall` PATH cleanup: `requirement-shell-path-and-shell-support` |

### 2.2 Why This Requirement Exists (CIAO)

- **Principle 2 – Intentional**: Named verbs, not empty-argv domain work.  
- **Principle 1 – Caution**: No silent “latest” on network fail.

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

**This requirement:** `version-check` / `self-update` / `self-uninstall` stay this-login `USER_BIN`. No `sudo curl`.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail loud.  
- **Intentional:** Reuse channel install primitives.  
- **Anti-fragile:** Idempotent uninstall.  
- **Over-protect:** No downgrade without `--force`.

---

## 4. Protection Rule (Sacred)

**MUST NOT**: bury lifecycle under `gc_*`; skip dual mention; hang off-TTY uninstall without `--force`; strip the **Under command line for normal user only** section, or recommend `sudo curl | sh` on Termux / Git Bash / Windows cmd.

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Three verbs routed and listed in help |
| AC-2 | version-check fails loud when the channel is unreachable |
| AC-3 | self-update reuses channel install |
| AC-5 | Proceeding `self-update` first INFO names `{{APP_NAME}}({{local}}) to new version:{{remote}}` (TP-ONL-05) |
| AC-4 | self-uninstall removes the managed binary |
| AC-6 | `self-update` (including already-at-remote) heals a stale Android `bin/grok` wrapper (TP-VCLI-32 · TP-GROK-CLI-49) |

### 2.6 Invocation samples (dual mention)

```text
grok-cli version-check
grok-cli self-update
grok-cli self-uninstall --force
```

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention |
| `docs/requirements/requirement-shell-online-install.md` | Place primitives |
| `docs/requirements/requirement-shell-path-and-shell-support.md` | PATH / profile; uninstall cleanup **call site** |
| `./src/grok-cli` | Implementation |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-ONL-03** · **TP-ONL-04** · **TP-ONL-05** | `tests/test_online_install.sh` | have |
| **TP-CLI-04** · **TP-CLI-10** | `tests/test_cli.sh` | have |

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-09-02 | Active (1.0.0) | Specialized from selfmanaged lifecycle |
| 2026-09-07 | Active (1.1.0) | `self-update` first INFO names local and remote VERSION |
| 2026-09-07 | Active (1.2.0) | `self-update` heals stale Android `bin/grok` (already-at-remote too) |
| 2026-09-09 | Active (1.3.0) | PATH cleanup call site → `requirement-shell-path-and-shell-support` |

**Last Updated**: 2026-09-09 (1.3.0 — PATH cleanup call site)
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
