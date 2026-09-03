# Filled run: CL-CLI-DEFAULT-INTERACTION — grok-cli 1.8.0

**Date:** 2026-09-03  
**Blank form:** `docs/templates/checklists/checklist-cli-default-interaction.md`  
**Product:** grok-cli (`src/grok-cli`)  
**Claimed default function?** yes  
**Case:** 3  
**Reviewer:** Review + Implement (this change)

## Verdict

**Pass.** Main menu header is live `APP_NAME(APP_VERSION)` (bold/italic on TTY); session line under the title; backup is 1; sudoers is 5; Exit 9; no `$()` of `read` helpers (TP-CLI-15).

## 1. Membership and Exit (blocking)

- [x] Labels = routed-verb table **human-readable** `command: explain`
- [x] Header prints **`grok-cli(1.8.0)`** with bold name and italic version on TTY (`util_app_ident`)
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

- [x] TP-CLI-15 static grep on the ship unit
- [x] TP-CLI-17 header nametag, session line, gray italic explain, submenu nametag
- [x] Specialized `requirement-shell-cli-default-interaction` **2.1.0** names do-not-capture-read and the identity-header form
