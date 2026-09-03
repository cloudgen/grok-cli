**file**: docs/requirements/requirement-shell-cli-zero-arguments.md  
**Status**: Active (Version 2.0.0)  
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

Off-TTY empty argv **MUST NOT** route to help. That path is how `curl -fsSL ${SCRIPT_URL} | sh` first-shot install works.

On a **real terminal**, empty argv **MUST** open the numbered start list owned by `requirement-shell-cli-default-interaction` (same handler as `menu` / `main`). Explicit `menu` / `main` remain live. Flags-only (`--json` with no command) stay help.

---

### 1.1 Human-facing

Typing only `grok-cli` at a prompt shows the numbered start list. Piping the script (`curl | sh`) or running it with no arguments in a script installs grok-cli or reports that it is already installed. It does not print the help dump. `grok-cli --json` with no command still prints JSON help. `grok-cli menu` still opens the list (TTY) or help (script).

| You | Another role | Not this |
|-----|--------------|----------|
| Type `grok-cli` at a prompt | `curl \| sh` / a script with no args installs or no-ops | Help on a pipe; a hanging menu in a script |

**Includes:** TTY empty argv = numbered list; off-TTY empty argv = install-ensure (not help). **Excludes:** domain verb meaning; menu row labels.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Start daily work at a prompt | Numbered list; **backup** is **1**; login status is under the title | `grok-cli` then `1` |
| First install from the channel | Pipe places `~/.local/bin/grok-cli` | `curl -fsSL https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli \| sh` |
| Ask for usage in a script | Help screen | `grok-cli help` or `grok-cli --json` |
| Open the numbered list by name | Same list as empty argv on a TTY | `grok-cli menu` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Split meaning of empty argv

1. **Empty argv** is `$# -eq 0` at entry to `app_main`.  
2. **Interactive** (`TTY=1`): route to `app_default` (numbered start list). **MUST NOT** install-ensure. **MUST NOT** print the help dump.  
3. **Not interactive** (`TTY=0`): **Type O install-ensure** (`inst_channel_ensure`). **MUST NOT** print help. **MUST NOT** draw the numbered list. **MUST NOT** prompt. Not installed → download from `SCRIPT_URL` and place. Already installed → success no-op (no `--force` required). `--force` re-downloads.  
4. Flags with no command token (`grok-cli --json`, `grok-cli --quiet`) are **not** empty argv. They **MUST** keep defaulting to `help`.  
5. Explicit `grok-cli help` remains full usage.  
6. Explicit `grok-cli install` remains the **checkout copy** path (offline).  
7. Explicit `grok-cli menu` / `main` remain the numbered list (TTY) / help (off-TTY).  
8. Script entry **MUST** always call `app_main "$@"` (no basename gate). Pipe-safe.

### 2.2 Normative matrix

| Invocation | Behavior |
|------------|----------|
| `grok-cli` (no args, TTY) | Numbered start list; **MUST NOT** install |
| `grok-cli` (no args, not TTY) | Install-ensure; **MUST NOT** help; **MUST NOT** menu |
| `curl -fsSL ${SCRIPT_URL} \| sh` | Same as off-TTY empty argv |
| `grok-cli --json` (no command) | JSON help; **MUST NOT** prompt |
| `grok-cli help` | Show help |
| `grok-cli install` | Local copy from the running ship unit |
| `grok-cli menu` / `main` | TTY list / off-TTY help |

### 2.3 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product** | `grok-cli` |
| **Type** | **Type O-S** off-TTY; TTY menu (case 3) |
| **Channel** | `SCRIPT_URL` default `https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main/src/${APP_NAME}` (`REPO_USER=cloudgen`, `REPO_NAME=grok-cli`) |
| **Default COMMAND** | TTY empty argv → `menu`; off-TTY empty argv → `ensure` (`inst_channel_ensure`); flags-only → `help` |
| **Online bootstrap origin** | sibling `selfmanaged` (A→B specialize of the online package only; do not reverse-copy) |
| **Dual-mode** | Primary = channel pipe; secondary = checkout `install` (see `requirement-shell-online-install`) |

### 2.4 Why This Requirement Exists (CIAO)

- **Principle 2 – Intentional**: Pipe empty argv is install; a prompt is the daily list.  
- **Principle 1 – Caution**: Off-TTY must not hang on a menu.  
- **Principle 16 – Interactive**: Numbered list only when `TTY=1`.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: No menu on a pipe. Failed download is non-zero.  
- **Intentional**: Help is `help` / flags-only, not off-TTY empty argv.  
- **Anti-fragile**: Already-installed pipe re-run is success.  
- **Over-protect**: Do not send TTY empty argv to install-ensure.

---

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Route off-TTY empty argv to `app_help`.  
2. Draw the numbered menu on off-TTY empty argv, or hang a pipe.  
3. Replace TTY empty argv with help or with install-ensure.  
4. Gate `app_main` on `${0##*/}` so `curl \| sh` never runs.  
5. Treat flags-only `--json` as empty argv install-ensure.

**Violating this rule is a critical dispatcher / channel regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | TTY empty argv draws the numbered start list |
| AC-2 | Off-TTY empty argv is install-ensure, not help |
| AC-3 | Flags-only `--json` stays JSON help |
| AC-4 | `install` remains an explicit checkout-copy command |
| AC-5 | Pipe entry always reaches `app_main` |

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
| **TP-CLI-07** | `tests/test_cli.sh` | have |
| **TP-CLI-13** | `tests/test_cli.sh` | have |
| **TP-ONL-01** | `tests/test_online_install.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-23 | Active 1.3.0 | TTY menu; off-TTY Type N help |
| 2026-09-02 | Active 2.0.0 | Off-TTY empty argv unrouted from help → Type O install-ensure; TTY menu kept |

---

**Last Updated**: 2026-09-02  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
