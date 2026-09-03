# Filled run: CL-CLI-DEFAULT-INTERACTION — grok-cli 1.8.1 default CLI main menu style

**Date:** 2026-09-03  
**Blank form:** `docs/templates/checklists/checklist-cli-default-interaction.md`  
**Product:** grok-cli (`src/grok-cli`)  
**Claimed default function?** yes  
**Case:** 3  
**Reviewer:** Implement (this change)

## Verdict

**Pass.** Numbered list look is **default CLI main menu style**: header live `APP_NAME(APP_VERSION)` (bold/italic on TTY); numbered explain *italic* + light gray (SGR 3+37 via `out_menu_choice`); number and command name unstyled; session line under the title; backup is 1; sudoers is 5; Exit 9; no `$()` of `read` helpers (TP-CLI-15).

## Meta

| Field | Value |
|-------|--------|
| Claimed default function? | yes |
| Case 1 / 2 / 3 | 3 |
| Date | 2026-09-03 |
| Reviewer | Implement |

## 1. Membership and Exit (blocking)

- [x] Labels = routed-verb table **human-readable** `command: explain`
- [x] Look **MUST** be **default-cli-main-menu-style**: header (and APP_NAME-led submenu headers) print **`grok-cli(1.8.1)`** with **bold** name and *italic* version on TTY (`util_app_ident`) — **MUST NOT** a bare app-name; **MUST NOT** CSI off-TTY
- [x] TTY numbered explain is *italic* and light gray (SGR 3+37); number and command name unstyled; off-TTY plain — same term **default-cli-main-menu-style** (`out_menu_choice`; not `out_menu_row` / SGR 90)
- [x] MUST NOT list install/setup, self-managed verbs, `version`, `about`, test-purpose, `help`, gaps, or `menu`/`main` itself
- [x] Exit is **9**
- [x] Non-interactive path MUST NOT draw the menu or hang (off-TTY `menu` = help; empty argv = Type O)

## 2. Do not capture `read` (blocking)

- [x] Menu choice is current-shell `read` / `PROMPT_ASK_VALUE` (not `$()` of `prompt_ask`)
- [x] Extra fields on TTY: same call shape (`sync-auth-from-remote` SPEC is main **3**)
- [x] Ship unit grep finds no `$(prompt_ask` / `$(prompt_yes_no` (TP-CLI-15)
- [x] MUST NOT “fix” a freeze by sending the prompt to stderr and keeping `$()`

## 3. Empty argv vs `menu`/`main`

- [x] Case 3 recorded
- [x] Case 3 empty argv still the zero-arg REQ (TTY menu; off-TTY Type O)
- [x] `menu`/`main` is the named verb

## 4. Proof

- [x] TP-CLI-16 / TP-CLI-15 static grep on the ship unit
- [x] TP-CLI-17 look **default-cli-main-menu-style** — header live `APP_NAME(VERSION)` bold/italic; numbered explain italic + light gray SGR 3+37; not SGR 90; number/name unstyled
- [x] Specialized `requirement-shell-cli-default-interaction` **2.2.0** names do-not-capture-read, default CLI main menu style, and `out_menu_choice`
