# Filled run: CL-CLI-DEFAULT-INTERACTION — grok-cli 1.8.32 invalid-choice retry

**Date:** 2026-09-13  
**Blank form:** `CL-CLI-DEFAULT-INTERACTION`  
**Product:** grok-cli **1.8.32**  
**Law:** `requirement-shell-cli-default-interaction` **2.15.0**

## Meta

| Field | Value |
|-------|--------|
| Claimed default function? | yes |
| Case 1 / 2 / 3 | **3** |
| Date | 2026-09-13 |
| Reviewer | Implement + Review |

## 1. Membership and Exit (blocking)

- [x] Labels = routed-verb table **human-readable** `command: what it does`
- [x] Look **default-cli-main-menu-style** (header nametag; TTY explain italic + light gray)
- [x] TTY numbered explain is *italic* and light gray (SGR 3+37); number and name unstyled
- [x] **MUST NOT** list install/setup, self-managed, `version`, `about`, test-purpose, `help`, gaps, or `menu`/`main`
- [x] Exit is **9**
- [x] Invalid choice at **any menu layer** `out_error`, reprint **this** layer, re-prompt — **MUST NOT** `out_die` (**TP-CLI-30**; portable proof names **TP-CLI-19**, already used here for this-login-only host menu)
- [x] Nested sudoers invalid choice retries **that** submenu (`app_default_sudoers_loop`)
- [x] Non-interactive path does not draw the menu or hang

## 2. Do not capture `read` (blocking)

- [x] Menu choice is current-shell `read` then `_pick` (not `$()` of a `read` helper)
- [x] Extra fields still `prompt_ask` then `${PROMPT_ASK_VALUE}`
- [x] Ship unit grep: no `$(prompt_ask` / `$(prompt_yes_no` (**TP-CLI-15**)

## 3. Empty argv vs `menu`/`main`

- [x] Case **3** recorded
- [x] Empty argv = no command token after flag parse
- [x] Overlay flags-only follow empty argv
- [x] `--json` with no command is JSON help (not the list)
- [x] Interactive `menu --json` still the list
- [x] Case 3 empty argv still the zero-arg REQ; menu is verb `menu`/`main`

## 4. Proof

- [x] **TP-CLI-15** static grep
- [x] **TP-CLI-17** look
- [x] **TP-CLI-30** unused listed-gap integer and unknown name: `[ERROR]`, names the pick, reprints **this** layer; sudoers unused **6** reprints the grant list; not unknown argv
- [x] Specialized REQ MUST table names invalid-choice retry at every menu layer (2.15.0 rule 6b / Protection 27)

## 5. Session probe MUST NOT hang the menu

- [x] Reprint after a bad pick reuses `GC_SESSION_STATUS_CACHE` (**TP-CLI-22**)
- [x] **TP-CLI-21** / **TP-CLI-23** unchanged

**Last Updated:** 2026-09-13
