**file**: docs/requirements/requirement-shell-online-install.md  
**Status**: Active (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-online-install`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **channel and place Single Source of Truth** for grok-cli **online install**: `curl | sh` (or wget) downloads the ship unit from `SCRIPT_URL`, verifies the companion digest when present, and atomically publishes it to `USER_BIN` or `GLOBAL_BIN`.

It is specialized from the selfmanaged online package onto grok-cli. Empty-argv routing is `requirement-shell-cli-zero-arguments`. Integrity UX is `requirement-shell-automatic-checksum`. Remote lifecycle is `requirement-shell-self-management`. Checkout copy remains `requirement-shell-local-self-management`.

### 1.1 Human-facing

**In one sentence:** you paste one curl line so this login gets `grok-cli` in `~/.local/bin` (or `/usr/local/bin` as root).

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Run the one-liner without sudo for a user install | `curl -fsSL https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli \| sh` |
| The other role | Root / elevated for a global binary | `sudo curl -fsSL … \| sudo sh` |
| Not this file | Checkout copy; session backup; executing xAI `install.sh` | `sh src/grok-cli install` · `grok-cli backup` |

| Includes | Excludes |
|----------|----------|
| Channel URL; pipe bootstrap; atomic place; dual-mode matrix | Menu labels; sudoers; peer `grok` setup |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/grok-cli` | ship unit | live install |
| README Install | one-liner | copy-paste |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| First machine | Pipe ensure | the curl one-liner |
| Already installed | success, no re-download | the same one-liner |
| Replace from channel | re-download | `grok-cli self-update` or the one-liner with `--force` via `sh -s -- --force` |

---

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** compose default `SCRIPT_URL` as `https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main/src/${APP_NAME}`.  
2. Pipe **MUST** call `app_main "$@"` (no basename gate).  
3. Off-TTY empty argv **MUST** run channel ensure (`inst_channel_ensure` → `inst_perform_channel_install` when a place is needed).  
4. Download to a unique temp under storage `TMPDIR`; verify; `chmod 0755`; `mv` onto `${USER_BIN}/grok-cli` or `${GLOBAL_BIN}/grok-cli`.  
5. Missing `curl` and `wget` → fail closed.  
6. Core tests **MUST** fake the channel (no public network).  
7. **MUST NOT** print tokens.

### 2.1 Dual-mode matrix (explicit — user ordered)

| Field | Must state |
|-------|------------|
| Primary install path | online channel `curl -fsSL ${SCRIPT_URL} \| sh` |
| Secondary path | checkout `sh src/grok-cli install` copies the running ship unit (offline) |
| Empty argv | TTY numbered menu; off-TTY Type O channel ensure |
| Place commands | pipe / off-TTY empty argv = channel; explicit `install` = local copy |
| Remove commands | **`self-uninstall`** (channel name) **and** **`uninstall`** (local name) — both remove the managed binary |
| Refresh | `self-update` from channel; `install --force` from checkout |
| Help honesty | both paths listed |

### 2.2 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Product | `grok-cli` |
| Handler | `inst_channel_ensure` / `inst_perform_channel_install` |
| `SCRIPT_URL` | `https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli` |
| Companion | `${SCRIPT_URL}.sha256` (file `src/grok-cli.sha256`) |
| Privilege | Type 0 |
| Online origin | selfmanaged (specialize A→B; do not reverse-copy) |

### 2.3 Why This Requirement Exists (CIAO)

- **Principle 1 – Caution**: Atomic place; fail loud on download.  
- **Principle 2 – Intentional**: Channel vs checkout are named.  
- **Principle 10 – Least privilege**: User bin without sudo.

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

**This requirement:** user `curl | sh` places this-login `USER_BIN`. Never `sudo curl | sh` on this class.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fake curl in Core tests.  
- **Intentional:** Dual-mode matrix filled.  
- **Anti-fragile:** Already-installed pipe is success.  
- **Over-protect:** No toy hosts in README.

---

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Leave `SCRIPT_URL` empty while advertising `curl \| sh`.  
2. Use a toy host in product Install.  
3. Skip the dual-mode matrix while both channel and checkout `install` stay Active.  
4. Reverse-copy grok-cli onto selfmanaged.  
5. Hang a pipe on a confirm.

---
6. Strip the **Under command line for normal user only** section, or enable admin privilege / a dedicated system user on Termux / Git Bash / Windows cmd.  


## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Default `SCRIPT_URL` is the github raw `src/grok-cli` URL |
| AC-2 | Off-TTY empty argv places or no-ops without help |
| AC-3 | Explicit `install` still copies the running file offline |
| AC-4 | README shows a literal curl one-liner using that URL |

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv split |
| `docs/requirements/requirement-shell-automatic-checksum.md` | Companion digest |
| `docs/requirements/requirement-shell-self-management.md` | version-check / self-update / self-uninstall |
| `docs/requirements/requirement-shell-local-self-management.md` | Checkout copy |
| `./src/grok-cli` | Implementation |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-ONL-01**–**04** | `tests/test_online_install.sh` | have |
| **TP-CLI-07** | `tests/test_cli.sh` | have |

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-09-02 | Active (1.0.0) | Channel + dual-mode; specialize from selfmanaged |

**Last Updated**: 2026-09-06  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
