**file**: docs/requirements/requirement-shell-script-coding.md  
**Status**: Active (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-script-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **product Single Source of Truth** for **POSIX `/bin/sh` coding style** of grok-cli: `set -u`, explicit errors, no `set -e` as the only handler, prefixes, and fail-closed elevation. Without this file, portable shell lessons would arrive **raw**.

### 1.1 Human-facing

This file says how grok-cli’s ship unit must be written: one `/bin/sh` file, `out_*` for messages, `gc_*` for grok auth, never a silent success.

| You | Another role | Not this |
|-----|--------------|----------|
| Read prefixes and `set -u` rules when changing `src/grok-cli` | Modular-function REQ owns the prefix table SSOT | Python/Node style; online-install coding |

**Includes:** interpreter, unset handling, no raw product `echo`. **Excludes:** grant JSON schema.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Edit the CLI | Follow `out_*` / `gc_*` / `set -u` | Open `src/grok-cli` |

---

## 2. Core Rules (Mandatory)

1. **MUST** ship as POSIX `/bin/sh` (`#!/bin/sh`), `set -u`, explicit `out_die` (not global `set -e`).  
2. **MUST** use defined prefixes (`out_`, `inst_`, `util_`, `app_`, `gc_`, `prompt_`).  
3. **MUST NOT** print product messages with raw `echo`/`printf` outside `out_*`.  
4. **MUST** measure `[ -t 0 ]` / `[ -t 1 ]` for TTY **outside** functions; helpers consume `TTY`.  
5. **MUST NOT** use `sudo -n true` as the only elevation proof. Passwordless elev is the grant `sudo -n {{GLOBAL_BIN}}/grok-cli backup`.  
6. **MUST** fail closed on missing session, missing grant, or unreadable store.  
7. Temps **MUST** use `mktemp` under storage `TMPDIR`, not `$$` names.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Ship unit | `src/grok-cli` |
| Interpreter | `/bin/sh` |
| Domain prefix | `gc_` |
| Version SSOT | `VERSION="1.0.0"` in ship unit |

### 2.2 Why This Requirement Exists (CIAO)

- **Principle 2 – Intentional**: Style is law so later hops do not dump raw lessons.  
- **Principle 5 – Output SSOT**: `out_*` only.  
- **Principle 16 – Interactive**: TTY measured outside functions.

---

## 3. Design Principles

- **Caution:** Assume unset HOME and missing sudo.  
- **Intentional:** One ship unit.  
- **Anti-fragile:** Isolated tests.  
- **Over-protect:** Fail closed; no OS-tool sudoers.

---

## 4. Protection Rule

**MUST NOT** add `set -e` as the only error policy, drop prefixes, or treat coding skills as product law in place of this file.

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | `sh -n src/grok-cli` passes (TP-CLI-01) |
| AC-2 | `set -u` survives unset HOME (TP-CLI-11) |
| AC-3 | Domain functions use `gc_` |

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-01**, **TP-CLI-11** | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

---

**Last Updated**: 2026-08-22  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
