**file**: docs/requirements/requirement-shell-cli-zero-arguments.md  
**Status**: Active (Version 1.3.0)  
**Area**: shell  
**Key**: `requirement-shell-cli-zero-arguments`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **zero-argument (empty argv) dispatcher behavior** of the grok-cli POSIX shell CLI.

### 1.0 Product type

| Field | Value for grok-cli |
|-------|-------------------------|
| **Empty-argv type** | **Type N — Non-online-install** |
| **Rationale** | Product is **local-only**; no `curl \| sh` channel; empty argv **MUST NOT** install-ensure |

Type O (online-install empty-argv = install-ensure) does **not** apply.

Empty argv **owns** whether the process installs. On a **real terminal**, empty argv **MUST** open the numbered start list owned by `requirement-shell-cli-default-interaction` (same handler as `menu` / `main`). Off-TTY, empty argv **MUST** stay **help**. Explicit `menu` / `main` remain live.

---

### 1.1 Human-facing

Running grok-cli with no arguments does not install itself. On a real terminal it shows the numbered start list. In a script or pipe it prints help. With `--json` and no command, it prints JSON help. You can still type `grok-cli menu` (or `main`) for the same list.

| You | Another role | Not this |
|-----|--------------|----------|
| Type `grok-cli` at a prompt | CI / pipe gets help, not a hang | Type O curl\|sh ensure; a hanging menu in a script |

**Includes:** empty argv = Type N (not install); TTY empty argv = numbered list; off-TTY empty argv = help. **Excludes:** domain verb meaning; menu row labels (those live on default-interaction).

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Start daily work at a prompt | Numbered list; **check-session** is **1** | `grok-cli` then `1` |
| Ask for usage in a script | Help screen, no pick | `grok-cli </dev/null` |
| Machine help | JSON help, no command | `grok-cli --json` |
| Open the numbered list by name | Same list as empty argv on a TTY | `grok-cli menu` |


## 2. Core Rules (Mandatory)

### 2.1 Single meaning of empty argv

1. When **argv is empty** (`$# -eq 0` at entry to `app_main`), the dispatcher **MUST NOT** install, backup, or run any state-changing ensure.  
2. Empty argv **MUST** route to the **default-interaction** handler (`app_default`, same as command `menu` / `main`):  
   - **Interactive** (`TTY=1`): numbered start list. **MUST NOT** print the help dump instead of that list.  
   - **Not interactive** (`TTY=0`): **Type N help** — human help when `JSON=0`; JSON help when `JSON=1`. **MUST NOT** draw the numbered list. **MUST NOT** prompt.  
3. Flags with no command token (`grok-cli --json`, `grok-cli --quiet`) are **not** empty argv. They **MUST** keep defaulting to `help` (JSON help when `JSON=1`).  
4. Explicit `grok-cli help` remains full usage.  
5. Explicit `grok-cli install` remains the only first-time local install path (plus documented force refresh).  
6. Explicit `grok-cli menu` / `grok-cli main` remain the same numbered list (TTY) / help (off-TTY).  
7. Script entry **MUST** always call `app_main "$@"` (no basename product-name gate that blocks dispatch).  
8. Menu labels, Exit **9**, family **sudoers**, and off-TTY `menu`/`main` rules live on `requirement-shell-cli-default-interaction`.

### 2.2 Normative matrix

| Invocation | Behavior |
|------------|----------|
| `grok-cli` (no args, TTY) | Numbered start list (`app_default`); exit 0 after pick or Exit; **MUST NOT** install |
| `grok-cli` (no args, not TTY) | Human help; exit 0; **MUST NOT** prompt; **MUST NOT** menu |
| `grok-cli --json` (no command) | JSON help; exit 0; **MUST NOT** prompt |
| `grok-cli help` | Show help; exit 0 |
| `grok-cli install` | Local install ensure |
| `grok-cli menu` / `grok-cli main` | Same handler as TTY empty argv — `requirement-shell-cli-default-interaction` |

### 2.3 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product** | `grok-cli` |
| **Type** | **Type N** |
| **Default COMMAND** | empty argv → `menu` (then `app_default`); flags-only → `help` |
| **Contrast parent** | cli-template is already Type N — **inherited**. (Historical: selfmanaged Type O was trimmed in 2026-08-03; not live origin.) |
| **Default interaction** | Claimed; **case 3** — zero-arg REQ exists and **defers TTY empty argv** to the numbered list; `menu`/`main` stay live |

### 2.4 Why This Requirement Exists (CIAO)

- **Principle 2 – Intentional**: Empty argv meaning is explicit: not install, not “whatever the parent did.” TTY start list is named here.  
- **Principle 1 – Caution**: Avoid surprise install on bare invocation for an ops CLI.  
- **Principle 16 – Interactive**: The numbered list is the human default on a real terminal; scripts still get help.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: No silent ensure on empty argv. No hang off-TTY.  
- **Intentional**: Type N declared in law; TTY vs off-TTY split is written.  
- **Anti-fragile**: Help works offline and in pipes.  
- **Over-protect**: Do not reintroduce Type O without reclassifying product install mode. Do not draw the numbered list without a TTY.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Change empty argv to install-ensure while the product remains local-only.  
2. Copy a Type O empty-argv parent wholesale without updating this file and install mode.  
3. Make bare invocation run domain `backup`.  
4. Draw the numbered menu on **off-TTY** empty argv, or hang a pipe waiting for a pick.  
5. Replace TTY empty argv with the help dump while this requirement remains Active **1.3.0+**.

**Violating this rule is a critical dispatcher regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Empty argv does not install |
| AC-2 | Type N is the declared empty-argv type |
| AC-3 | `install` remains an explicit command |
| AC-4 | Off-TTY empty argv shows help and does not draw the numbered menu |
| AC-5 | TTY empty argv draws the numbered start list (same handler as `menu`) |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-cli-interface` | Dispatcher command table |
| `requirement-shell-cli-default-interaction` | Numbered list body; TTY empty argv defers here |
| `requirement-shell-local-self-management` | Explicit install |
| `requirement-bootstrap-chain` | Trim of Type O from parent |
| `docs/requirements/index.md` | Registry |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-07** | `tests/test_cli.sh` | have |
| **TP-CLI-13** | `tests/test_cli.sh` | have (shared `app_default` with `menu`/`main`) |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active | Type N for local-only folder-backup |
| 2026-08-23 | Active 1.1.0 | (superseded by 1.2.0) TTY empty argv deferred to default-interaction |
| 2026-08-23 | Active 1.2.0 | Empty argv is help again; menu is verb `menu`/`main` |
| 2026-08-23 | Active 1.3.0 | TTY empty argv is the numbered list again; off-TTY stays Type N help; not install |

---

**Last Updated**: 2026-08-23  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
