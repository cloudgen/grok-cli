**file**: docs/requirements/requirement-shell-cli-zero-arguments.md  
**Status**: Active (Version 2.2.0)  
**Area**: shell  
**Key**: `requirement-shell-cli-zero-arguments`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **zero-argument (empty argv) dispatcher behavior** of grok-cli.

### 1.0 Product type

| Field | Value for grok-cli |
|-------|-------------------------|
| **Empty-argv type** | **Type O-S — Online script-alone** (off-TTY) **plus** TTY numbered menu |
| **Rationale** | Product advertises `curl \| sh`; pipe empty argv is install-ensure. A real terminal keeps the daily-work menu. |

**Empty argv** means **no command token** after global-flag parse. Overlay switches (`--debug`, `--quiet`/`-q`, `--force`, `--global`) **do not** disqualify empty argv. `grok-cli --debug` **MUST** follow the same empty-argv law as `grok-cli` and as `DEBUG=1 grok-cli`. `$# -eq 0` at entry is **sufficient** but **not necessary**.

Off-TTY empty argv **MUST NOT** route to help. That path is how `curl -fsSL ${SCRIPT_URL} | sh` first-shot install works.

On a **real terminal**, empty argv **MUST** open the numbered start list owned by `requirement-shell-cli-default-interaction` (same handler as `menu` / `main`). Explicit `menu` / `main` remain live.

**`--json` special case (still empty argv):** `grok-cli --json` with no command token **is** empty argv. Outcome **MUST** be **JSON help** — on a TTY **and** off-TTY. **MUST NOT** the numbered list. **MUST NOT** Type O ensure. Distinct from `grok-cli menu --json` on a TTY, which still ignores `--json` and draws the list.

---

### 1.1 Human-facing

Typing only `grok-cli` at a prompt shows the numbered start list. The same list appears for `grok-cli --debug` (debug overlay on). Piping the script (`curl | sh`) or running it with no command in a script installs grok-cli or reports that it is already installed. It does not print the help dump. `grok-cli --json` at a prompt is still empty argv, but a **special case**: JSON help, not the list. `grok-cli menu` still opens the list (TTY) or help (script).

| You | Another role | Not this |
|-----|--------------|----------|
| Type `grok-cli` or `grok-cli --debug` at a prompt | `curl \| sh` / a script with no command installs or no-ops | Help on a pipe; a hanging menu in a script; help because `--debug` was present |

**Includes:** TTY empty argv (including overlay switches) = numbered list; off-TTY empty argv (including overlay switches) = install-ensure (not help). **Excludes:** domain verb meaning; menu row labels.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Start daily work at a prompt | Numbered list; on a multi-user host **backup** is **1** (Termux / Git Bash / Windows cmd hide backup / sync-auth / sudoers — `requirement-shell-cli-default-interaction`); login status is under the title | `grok-cli` then `1` |
| Start daily work with diagnostics | Same list; `[DEBUG]` on stderr; menu paint elapsed | `grok-cli --debug` |
| First install from the channel | Pipe places `~/.local/bin/grok-cli` | `curl -fsSL https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli \| sh` |
| Ask for machine-readable usage (even at a prompt) | JSON help (empty argv **special case**) | `grok-cli --json` |
| Open the numbered list by name | Same list as empty argv on a TTY | `grok-cli menu` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Split meaning of empty argv

1. **Empty argv** is: after global-flag parse, **no command token** was present. `$# -eq 0` at entry to `app_main` is one form. Flags-only overlay argv (`grok-cli --debug`, `grok-cli --quiet`, `grok-cli --force`) is the same form.  
2. **Interactive** (`TTY=1`): route to `app_default` (numbered start list). **MUST NOT** install-ensure. **MUST NOT** print the help dump.  
3. **Not interactive** (`TTY=0`): **Type O install-ensure** (`inst_channel_ensure`). **MUST NOT** print help. **MUST NOT** draw the numbered list. **MUST NOT** prompt. Not installed → download from `SCRIPT_URL` and place. Already installed → success no-op (no `--force` required). `--force` re-downloads.  
4. Overlay switches with no command token **MUST** follow rules 2–3 (they **are** empty argv). `grok-cli --debug` **MUST** match `DEBUG=1 grok-cli`. `--quiet` / `-q`, `--force`, and `--global` with no command token **MUST** likewise follow empty argv (quiet / force / global overlay on that path).  
5. **`--json` special case:** `--json` with no command token **is** empty argv. Outcome **MUST** be JSON help on **TTY and off-TTY**. **MUST NOT** the numbered list. **MUST NOT** Type O ensure. `grok-cli menu --json` on a TTY remains the list (`requirement-shell-cli-default-interaction`).  
6. Explicit `grok-cli help` remains full usage.  
7. Explicit `grok-cli install` remains the **checkout copy** path (offline).  
8. Explicit `grok-cli menu` / `main` remain the numbered list (TTY) / help (off-TTY).  
9. Script entry **MUST** always call `app_main "$@"` (no basename gate). Pipe-safe.  
10. The dispatcher **MUST** decide empty argv **after** flag parse. **MUST NOT** use only `$# -eq 0` before parse so overlay flags fall through to default `COMMAND=help`.

### 2.2 Normative matrix

| Invocation | Behavior |
|------------|----------|
| `grok-cli` (no args, TTY) | Numbered start list; **MUST NOT** install |
| `grok-cli` (no args, not TTY) | Install-ensure; **MUST NOT** help; **MUST NOT** menu |
| `grok-cli --debug` (no command, TTY) | Same numbered start list as empty argv; debug overlay on |
| `grok-cli --debug` (no command, not TTY) | Install-ensure with debug overlay; **MUST NOT** help; **MUST NOT** menu |
| `grok-cli --quiet` (no command) | Same empty-argv path as `grok-cli` (quiet) |
| `curl -fsSL ${SCRIPT_URL} \| sh` | Same as off-TTY empty argv |
| `grok-cli --json` (no command, TTY) | Empty argv **special case**: JSON help; **MUST NOT** numbered list; **MUST NOT** prompt |
| `grok-cli --json` (no command, not TTY) | Same special case: JSON help; **MUST NOT** install-ensure |
| `grok-cli help` | Show help |
| `grok-cli install` | Local copy from the running ship unit |
| `grok-cli menu` / `main` | TTY list / off-TTY help |

### 2.3 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product** | `grok-cli` |
| **Type** | **Type O-S** off-TTY; TTY menu (case 3) |
| **Channel** | `SCRIPT_URL` default `https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main/src/${APP_NAME}` (`REPO_USER=cloudgen`, `REPO_NAME=grok-cli`) |
| **Default COMMAND** | TTY no-command → `menu`; off-TTY no-command → `ensure` (`inst_channel_ensure`); `--json` no-command (0-argv special case, TTY or not) → `help` |
| **Online bootstrap origin** | sibling `selfmanaged` (A→B specialize of the online package only; do not reverse-copy) |
| **Dual-mode** | Primary = channel pipe; secondary = checkout `install` (see `requirement-shell-online-install`) |

### 2.4 Why This Requirement Exists (CIAO)

- **Principle 2 – Intentional**: Pipe empty argv is install; a prompt is the daily list. Overlay switches do not change that meaning.  
- **Principle 1 – Caution**: Off-TTY must not hang on a menu. `--json` with no command must not install.  
- **Principle 16 – Interactive**: Numbered list only when `TTY=1`.

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

**This requirement:** off-TTY install-ensure stays this-login place. It **MUST NOT** become a sudo/apt install path.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: No menu on a pipe. Failed download is non-zero.  
- **Intentional**: Help is `help` / `--json` with no command, not off-TTY empty argv, not `--debug` with no command.  
- **Anti-fragile**: Already-installed pipe re-run is success. Overlay flags still reach the same path as `DEBUG=1` / `QUIET=1`.  
- **Over-protect**: Do not send TTY empty argv to install-ensure. Do not treat overlay flags-only as help.

---

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Route off-TTY empty argv to `app_help`.  
2. Draw the numbered menu on off-TTY empty argv, or hang a pipe.  
3. Replace TTY empty argv with help or with install-ensure.  
4. Gate `app_main` on `${0##*/}` so `curl \| sh` never runs.  
5. Treat flags-only `--json` as Type O install-ensure, or as the TTY numbered list. It **is** empty argv; the special-case outcome is JSON help (TTY and off-TTY).  
6. Treat overlay flags-only (`--debug`, `--quiet`/`-q`, `--force`, `--global`) as help or as a third meaning. `grok-cli --debug` **MUST** be empty argv.  
7. Use only `$# -eq 0` before flag parse so overlay flags fall through to default `COMMAND=help`.  

8. Strip the **Under command line for normal user only** section, or enable admin privilege / a dedicated system user on Termux / Git Bash / Windows cmd.  

**Violating this rule is a critical dispatcher / channel regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | TTY empty argv draws the numbered start list |
| AC-2 | Off-TTY empty argv is install-ensure, not help |
| AC-3 | Flags-only `--json` is empty argv special case: JSON help on TTY **and** off-TTY (not the numbered list, not install-ensure) |
| AC-4 | `install` remains an explicit checkout-copy command |
| AC-5 | Pipe entry always reaches `app_main` |
| AC-6 | TTY `grok-cli --debug` (no command) draws the numbered start list (same as empty argv) |
| AC-7 | Off-TTY `grok-cli --debug` (no command) is install-ensure, not help |

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | TTY menu body; off-TTY `menu` help |
| `docs/requirements/requirement-shell-online-install.md` | Channel / pipe place |
| `docs/requirements/requirement-shell-local-self-management.md` | Checkout `install` |
| `./src/grok-cli` | Implementation |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-07** | `tests/test_cli.sh` | have (TTY `--json` no command is JSON help, not the list) |
| **TP-CLI-13** | `tests/test_cli.sh` | have |
| **TP-CLI-29** | `tests/test_cli.sh` | have (overlay flags-only `--debug` / `--quiet` follow empty argv; `--json` stays JSON help) |
| **TP-ONL-01** | `tests/test_online_install.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-23 | Active 1.3.0 | TTY menu; off-TTY Type N help |
| 2026-09-02 | Active 2.0.0 | Off-TTY empty argv unrouted from help → Type O install-ensure; TTY menu kept |
| 2026-09-07 | Active 2.1.0 | Empty argv = no command token; overlay switches (`--debug`) follow empty argv; `--json` no-command stays JSON help |
| 2026-09-07 | Active 2.2.0 | `--json` with no command **is** empty argv; special case = JSON help even on a TTY |

---

**Last Updated**: 2026-09-07  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
