# Filled run: CL-CLI-DEFAULT-INTERACTION — grok-cli 1.8.20 `run` first

**Date:** 2026-09-07  
**Blank form:** `docs/templates/checklists/checklist-cli-default-interaction.md`  
**Product:** grok-cli **1.8.20**  
**Law:** `requirement-shell-cli-default-interaction` **2.9.0**

## Meta

| Field | Value |
|-------|--------|
| Claimed default function? | yes |
| Case 1 / 2 / 3 | **3** |
| Date | 2026-09-07 |
| Reviewer | Implement + Review |

## 1. Membership and Exit (blocking)

- [x] Labels = routed-verb table human-readable (`run: Start grok without auto-update`)
- [x] Look default-cli-main-menu-style (unchanged)
- [x] **MUST NOT** list install/setup, self-managed, `version`, `about`, test-purpose, `help`, `menu`/`main`
- [x] This-login-only **N = 3 / 2** with **`run` first** (logged out / logged in)
- [x] Multi-user host still **backup** as **1** (no `run` row)
- [x] Exit is **9**
- [x] Off-TTY `menu`/`main` is help; off-TTY empty argv is Type O

## 2. Do not capture `read` (blocking)

- [x] Menu choice stays current-shell `read` (unchanged this pass)
- [x] Menu pick `run` calls `gc_run_grok` with no `$()` of `read`

## 3. Empty argv vs `menu`/`main`

- [x] Case **3** recorded
- [x] Overlay flags-only still empty argv
- [x] TTY `--json` no command still JSON help (not this list)

## 4. Proof

- [x] **TP-CLI-19** Termux / Git Bash / Windows cmd: **1. run:** **2. sync-auth-from-remote:** **3. add-crontab:**
- [x] **TP-CLI-20** this-login-only logged in: **1. run:** **2. add-crontab:**
- [x] **TP-CLI-13** / **TP-CLI-17** look unchanged

## 5. Session probe MUST NOT hang

- [x] Unchanged from 1.8.14 bounded probe (TP-CLI-21/22/23)
- [x] `run` is a listed verb, not a second session probe

**Last Updated:** 2026-09-07
