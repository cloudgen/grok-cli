# Product review: grok-cli (main-menu invalid-choice retry)

**Date:** 2026-09-13  
**Reviewer:** Implement + Review  
**Product:** grok-cli `VERSION=1.8.32`  
**Ship unit:** `src/grok-cli`  
**Scope:** Coverage of “every layer of the main menu reprints on incorrect input”; align molds, tests, checklist; implement and fix  
**Method:** registry + law mold `LM-CLI-DEFAULT-INTERACTION` 1.15.1 vs specialized REQ; ship-unit `app_default` / `app_default_sudoers_loop`; suite `tests/run.sh`  
**Baseline:** PASS=848 FAIL=0 SKIP=0

## Summary

Portable law already required an invalid TTY menu pick to `out_error`, reprint **this** layer, and re-prompt. Product law 2.14.0 did not say that. The loops already retried, but they used `out_warn` and a `Next: grok-cli menu` line that sounded like “leave and run the command again.” Product **TP-CLI-19** already meant this-login-only host menu, so the portable proof id could not be reused. Same-change: REQ **2.15.0**, ship unit `out_error` + reprint, product **TP-CLI-30**, filled `CL-CLI-DEFAULT-INTERACTION`, mold map note.

## Strengths

| Area | Notes |
|------|--------|
| Loops | Main and sudoers already continued after a bad pick (no `out_die`) |
| Probe cache | **TP-CLI-22** already proved a reprint does not run a second live probe |
| ID hygiene | Product **TP-CLI-19** kept as this-login-only host menu; invalid-choice retry is **TP-CLI-30** |

## Findings

### GC-MENU-01 — Severity: P2 (medium)
- **Area:** REQ / coverage  
- **Status:** fixed  
- **Location:** `requirement-shell-cli-default-interaction` (was 2.14.0)  
- **Description:** Mold 1.15.0 required invalid-choice retry at any menu layer. Product MUST tables had no such row.  
- **Impact:** Implement could treat a TTY typo as unknown argv.  
- **Suggestion:** Rule 6b + Protection 27 + DTV **TP-CLI-30**. Done in 2.15.0.  
- **Cross-ref:** `LM-CLI-DEFAULT-INTERACTION` 8c  

### GC-MENU-02 — Severity: P2 (medium)
- **Area:** ship unit / tests  
- **Status:** fixed  
- **Location:** `app_default` · `app_default_sudoers_loop`  
- **Description:** Invalid pick used `out_warn` and `Next: grok-cli menu`. Submenu reprint was untested.  
- **Impact:** Operator-readable law wants `[ERROR]` and the listed numbers; nested layer was a coverage hole.  
- **Suggestion:** `out_error` naming the pick; reprint this layer; **TP-CLI-30** main unused 6, unknown name, sudoers unused 6, Termux logged-in unused 3. Done.  

### GC-MENU-03 — Severity: P3 (low)
- **Area:** proof IDs  
- **Status:** fixed  
- **Location:** portable **TP-CLI-19** vs product **TP-CLI-19**  
- **Description:** Portable proof assigned **TP-CLI-19** to invalid-choice retry after this product already used **TP-CLI-19** for Termux / Git Bash / Windows cmd hide.  
- **Impact:** Reusing the id would mix two intents.  
- **Suggestion:** Keep product **TP-CLI-19**. Prove retry as **TP-CLI-30**. Mold/skill/checklist: do not reuse **19** when it already names a different intent. Done.  

## Non-findings (explicitly OK)

| Check | Result |
|-------|--------|
| Main loop already retried | yes (was `out_warn` + continue) |
| Sudoers loop already retried | yes |
| EOF / failed `read` leaves | yes (`return 0`) |
| Setup already-installed list | **not** a main-menu layer (`grok-cli setup`); invalid pick there still defaults to keep. Out of this MUST. |
| Class gate | software-development; `requirement-class-software-dev` Active |
| Registry ↔ disk | no orphans in this change; REQ path registered 2.15.0 |
| Git-surface on the REQ | no `docs/templates` / `docs/skills` paths |

## Priority remediation order

1. ~~Add product MUST + Protection 27~~ done  
2. ~~`out_error` + reprint both layers~~ done  
3. ~~**TP-CLI-30** + maps + checklist~~ done  

## Related

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Product law 2.15.0 |
| `src/grok-cli` | `app_default` / `app_default_sudoers_loop` |
| `tests/test_cli.sh` | **TP-CLI-30** |
| `reviews/reports/2026-09-13-checklist-cli-default-interaction-invalid-choice.md` | Filled CL |
| `reviews/lessons.md` | **L-MENU-05** |

**Written by:** Implement + Review  
**Review status:** Findings closed  
**Suite:** PASS=848 FAIL=0 SKIP=0
