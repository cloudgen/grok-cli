# Requirement review — grok-cli 1.7.0 (curl install + TTY menu)

**Date:** 2026-09-02  
**Scope:** registry + empty-argv / online package / default-interaction; test-plan; lessons; molds; `CL-ONLINE-INSTALL-SCRIPT`  
**Mode:** review + authorized fix (user: review requirements, test plan, revision, molds, checklist; update README; test; nfix; commit and push)

## Registry inventory (Step −1)

- Registered on disk: 23 Active + 4 superseded (matches `docs/requirements/index.md` after this change)
- Unregistered on disk: none
- Ghosts: none
- Foreign candidates: none
- Class: software-development — Active `requirement-class-software-dev`

## Findings (closed in this change)

| ID | Severity | Surface | Finding | Fix |
|----|----------|---------|---------|-----|
| RV-01 | High | `reviews/test-plan.md` | Still Type N off-TTY help; online n/a; VERSION 1.5.0 | Retarget TP-CLI-07/10/13; add TP-ONL-*; VERSION 1.7.0 |
| RV-02 | High | `reviews/what-to-review.md` | P5 no SCRIPT_URL; local-only; L-TYPE-N-01 as leak | Dual-mode + Type O off-TTY |
| RV-03 | High | `reviews/requirement-test-matrix.md` | Online absent; zero-arg Type N | Add online/self-management/checksum rows |
| RV-04 | Medium | `reviews/lessons.md` | L-TYPE-N-01 / L-ONLINE-01 still “must not reintroduce” | Watch TTY-not-ensure; dual-mode matrix |
| RV-05 | Medium | README | Usage still “help in a script”; SCRIPT_URL empty lie | Curl + menu + env |
| RV-06 | Medium | index / class / bootstrap headers | Stale “local-only” / 3.0.1 | Dual-mode; bootstrap **4.0.0**; class **1.3.0** |
| RV-07 | Low | `cli-routed-verb-table.md` | Missing version-check / self-update / self-uninstall | Add rows |
| RV-08 | Medium | Checklist | `CL-ONLINE-INSTALL-SCRIPT` never filled | `reviews/reports/2026-09-02-checklist-online-install-script.md` |
| RV-09 | High | Live REQ bodies after 1.7.0 draft | Bootstrap 2.2 still local-only/`leolio` paths; class AC-7 “online absent”; grok-setup AC-7 `SCRIPT_URL` empty; default-interaction honesty “off-TTY help”; local-self-management “online absent”; SECURITY 1.5.0 current; tests README Type N | Retargeted current-law rows; hop paths without Unix login; SECURITY 1.7.0 |

## Mold alignment

| Mold | Product law | Verdict |
|------|-------------|---------|
| **LM-SHELL-CLI-ZERO-ARGUMENTS** | `requirement-shell-cli-zero-arguments` 2.0.0 | Type O-S off-TTY; TTY menu (case 3). Flags-only stay help. Pass |
| **LM-CLI-DEFAULT-INTERACTION** | `requirement-shell-cli-default-interaction` 2.0.0 | TTY empty argv + `menu`/`main`. Off-TTY `menu` = help. Off-TTY empty argv **not** this mold. Pass |
| **LM-ONLINE-INSTALL** | `requirement-shell-online-install` 1.0.0 | Channel + pipe + dual-mode matrix. Pass |
| **LM-SELF-MANAGEMENT** | `requirement-shell-self-management` 1.0.0 | version-check / self-update / self-uninstall. Pass |
| **LM-AUTOMATIC-CHECKSUM** | `requirement-shell-automatic-checksum` 1.0.0 | Companion link/value/result. Pass |
| **LM-SHELL-LOCAL-SELF-MANAGEMENT** | `requirement-shell-local-self-management` 1.3.0 | Checkout `install` secondary. Pass |

## Dual mention

`version-check` / `self-update` / `self-uninstall` on CLI interface **and** self-management. `setup` on CLI **and** grok-setup.

## Checklist

Filled run: `reviews/reports/2026-09-02-checklist-online-install-script.md` — **Pass** (TTY empty argv is an authorized case-3 exception to “empty argv always install”; pipe/off-TTY is Type O).

## Verdict

**Approve with follow-ups closed in this change.** Suite after fixes recorded in test-plan header.
