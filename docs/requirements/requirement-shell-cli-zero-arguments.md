**file**: docs/requirements/requirement-shell-cli-zero-arguments.md  
**Status**: Active (Version 1.2.0)  
**Area**: shell  
**Key**: `requirement-shell-cli-zero-arguments`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **zero-argument (empty argv) dispatcher behavior** of the grok-cli POSIX shell CLI.

### 1.0 Product type

| Field | Value for grok-cli |
|-------|-------------------------|
| **Empty-argv type** | **Type N — Non-online-install** |
| **Rationale** | Product is **local-only**; no `curl \| sh` channel; empty argv shows **help**, not install-ensure |

Type O (online-install empty-argv = install-ensure) does **not** apply.

The numbered command list is **not** empty argv. That list is `grok-cli menu` (alias `main`) on `requirement-shell-cli-default-interaction`.

---

### 1.1 Human-facing

Running grok-cli with no arguments does not install itself. It prints help — on a real terminal and in a script. With `--json` and no command, it prints JSON help. The numbered list of live commands is a different command: `grok-cli menu`.

| You | Another role | Not this |
|-----|--------------|----------|
| Type `grok-cli` with no extra words | CI uses `--json` | Type O curl\|sh ensure; a hanging menu on empty argv |

**Includes:** empty argv = Type N help (not install). **Excludes:** domain verb meaning; the numbered start list.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Ask for usage | Empty argv is help | `grok-cli` |
| Machine help | JSON help, no command | `grok-cli --json` |
| Open the numbered list | Different command | `grok-cli menu` |


## 2. Core Rules (Mandatory)

### 2.1 Single meaning of empty argv

1. When **argv is empty** (`$# -eq 0` at entry to `app_main`), the dispatcher **MUST NOT** install, backup, or run any state-changing ensure.  
2. Empty argv with no command token **MUST** be Type N **help**: human help when `JSON=0`; JSON help when `JSON=1`. **MUST NOT** draw the default-interaction menu.  
3. Those help paths **MUST NOT** prompt.  
4. Explicit `grok-cli help` remains full usage.  
5. Explicit `grok-cli install` remains the only first-time local install path (plus documented force refresh).  
6. Script entry **MUST** always call `app_main "$@"` (no basename product-name gate that blocks dispatch).  
7. The numbered menu lives on `requirement-shell-cli-default-interaction` as verb `menu` / `main` — **not** here.

### 2.2 Normative matrix

| Invocation | Behavior |
|------------|----------|
| `grok-cli` (no args, TTY) | Human help; exit 0; **MUST NOT** prompt; **MUST NOT** menu |
| `grok-cli` (no args, not TTY) | Human help; exit 0; **MUST NOT** prompt |
| `grok-cli --json` (no command) | JSON help; exit 0; **MUST NOT** prompt |
| `grok-cli help` | Show help; exit 0 |
| `grok-cli install` | Local install ensure |
| `grok-cli menu` / `grok-cli main` | Not this file — `requirement-shell-cli-default-interaction` |

### 2.3 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product** | `grok-cli` |
| **Type** | **Type N** |
| **Default COMMAND** | `help` (TTY and non-TTY) |
| **Contrast parent** | cli-template is already Type N — **inherited**. (Historical: selfmanaged Type O was trimmed in 2026-08-03; not live origin.) |
| **Default interaction** | Claimed; **case 3** — menu is verb `menu`/`main`, not empty argv |

### 2.4 Why This Requirement Exists (CIAO)

- **Principle 2 – Intentional**: Empty argv meaning is explicit and not left as “whatever the parent did.”  
- **Principle 1 – Caution**: Avoid surprise install on bare invocation for an ops CLI.  
- **Principle 16 – Interactive**: Help is the safe human default for local tools.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: No silent ensure on empty argv.  
- **Intentional**: Type N declared in law.  
- **Anti-fragile**: Help works offline.  
- **Over-protect**: Do not reintroduce Type O without reclassifying product install mode. Do not move the numbered menu onto empty argv while this file exists.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Change empty argv to install-ensure while the product remains local-only.  
2. Copy a Type O empty-argv parent wholesale without updating this file and install mode.  
3. Make bare invocation run domain `backup`.  
4. Defer empty argv to the default-interaction menu while this requirement remains Active.

**Violating this rule is a critical dispatcher regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Empty argv shows help and does not install |
| AC-2 | Type N is the declared empty-argv type |
| AC-3 | `install` remains an explicit command |
| AC-4 | Empty argv does not draw the numbered menu |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-cli-interface` | Dispatcher command table |
| `requirement-shell-cli-default-interaction` | Numbered list is verb `menu`/`main`, not empty argv |
| `requirement-shell-local-self-management` | Explicit install |
| `requirement-bootstrap-chain` | Trim of Type O from parent |
| `docs/requirements/index.md` | Registry |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-07** | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active | Type N for local-only folder-backup |
| 2026-08-23 | Active 1.1.0 | (superseded by 1.2.0) TTY empty argv deferred to default-interaction |
| 2026-08-23 | Active 1.2.0 | Empty argv is help again; menu is verb `menu`/`main` |

---

**Last Updated**: 2026-08-23  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
