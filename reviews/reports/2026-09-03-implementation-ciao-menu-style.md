# Filled run: CL-IMPLEMENTATION-CIAO — grok-cli 1.8.1 default CLI main menu style

**Date:** 2026-09-03  
**Blank form:** `docs/templates/checklists/implementation-ciao.md`  
**Change:** Adopt default CLI main menu style (SGR 3+37 / `out_menu_choice`)

## Traceability to requirements

- [x] Cited REQs are Active: `requirement-shell-cli-default-interaction` **2.2.0**, `requirement-shell-output-requirements` **1.1.0**
- [x] Acceptance criteria addressed (AC-6; TP-CLI-17)
- [x] No behavior shipped that contradicts an active requirement
- [x] No new routed verb (dual mention N/A)

## CIAO-Lite

- [x] **C Caution** — CSI only on TTY; off-TTY plain
- [x] **I Intentional** — named look default CLI main menu style; helper `out_menu_choice`
- [x] **A Anti-fragile** — Exit/Back still unstyled; inherited `APP_VERSION` ignored
- [x] **O Over-protect** — Protection Rule 12 forbids a second house look
- [x] Surgical — menu printer + tests + law; no drive-by
- [x] Numbered TTY main menu: **do-not-capture-read** unchanged; **`CL-CLI-DEFAULT-INTERACTION`** filled
- [x] Type 1 / temps / set -u: N/A this change

## Files and docs

- [x] Product source cites live `requirement-*.md` only
- [x] Filled checklist under `docs/checklists/` and `reviews/reports/`
- [x] No-placeholder; README/CHANGELOG use real product facts
