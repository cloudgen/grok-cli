# Filled run: language menu 5 — grok-cli 1.8.42

**Date:** 2026-10-02
**Checklist:** `CL-CLI-DEFAULT-INTERACTION`
**Blank form:** `docs/templates/checklists/checklist-cli-default-interaction.md`
**Product:** grok-cli **1.8.42**
**Law:** `requirement-shell-cli-language` **1.1.0** · `requirement-shell-cli-default-interaction` **2.22.0** · `requirement-shell-cli-interface` **2.15.3** · `requirement-shell-cli-storage` **1.4.1**
**Proof:** **TP-CLI-32** · **TP-CLI-13** · **TP-CLI-19** · **TP-CLI-20** · **TP-CLI-30** (`tests/test_cli.sh`)
**Suite:** PASS=998 FAIL=56 SKIP=0 (`sh tests/run.sh`, 2026-10-02). Language rows passed. The 56 fails are **TP-VCLI-19** through **TP-VCLI-36** (Termux/proot grok place and Windows `.exe` place), the same class that failed on 1.8.41.

## Verdict

- [x] **Pass** — front **5** language; block **50–69**; thirteen assigned rows **51–63**
- [ ] **Revise**
- [ ] **Block**

Reviewer / role: Implement + Review (this change)
Date: 2026-10-02

## Checklist

- [x] Front row is **5** language on every host, including Termux / Git Bash / Windows cmd
- [x] Language rows are reserved **50–69** (twenty numbers, not more than 20 languages)
- [x] Assigned rows are **51** English, **52** 简体中文, **53** 繁體中文, **54** Español, **55** العربية, **56** Français, **57** Português, **58** Русский, **59** Deutsch, **60** 日本語, **61** 한국어, **62** Nederlands, **63** Ελληνικά
- [x] **50** and **64–69** are not printed; choosing **50**, **64**, or **69** warns and does not write `language`
- [x] Front **6** is not a row; the error hint lists **5**, not **6**
- [x] Requirements, review matrix, test plan, and **TP-CLI-32** name the same numbers
- [x] `src/grok-cli.sha256` is the bare hex of `src/grok-cli`

## Meta

| Field | Value |
|-------|--------|
| Claimed default function? | yes |
| Case 1 / 2 / 3 | **3** |
| Date | 2026-10-02 |
| Reviewer | Implement + Review |

## 1. Membership and Exit (blocking)

- [x] Labels stay the routed-verb human-readable form (`language: display language for this menu`)
- [x] Look stays default-cli-main-menu-style
- [x] Exit is **9**
- [x] Invalid choice at any menu layer is `out_error` and reprints this layer (**TP-CLI-30**)
- [x] Nested sudoers invalid **6** still retries that submenu
- [x] Non-interactive path does not draw the menu

## 2. Do not capture `read` (blocking)

- [x] Language choice is current-shell `read` then `_pick` (`app_default_language_loop`)
- [x] `app_menu_text` does not call `read`

## 3. Empty argv vs `menu`/`main`

- [x] Case **3** recorded
- [x] English menu literals stay (`logged in`, `Choice: `, `Not a menu choice`, `9. Exit`, `0. Back`)

## 4. Proof

- [x] **TP-CLI-13** front prints `5. language:` and does not print `6. language:`
- [x] **TP-CLI-19** Termux / Git Bash / Windows cmd print `5. language:`; Termux **6** warns and does not open **51**
- [x] **TP-CLI-20** pick **5** opens **51** English and **63** Ελληνικά
- [x] **TP-CLI-30** unused front integer stays **4**; Termux unused integer is **6**; sudoers unused **6** stays
- [x] **TP-CLI-32** board **51–63**, save `zh-Hant` / `el` / `ar` mode 0600, Back and reserved picks and front **6** do not write, `GROK_CLI_LANG=ja` does not rewrite the file, human help and about follow the code, JSON stays English, `language` is not an argv verb

## 5. Session probe

- [x] **TP-CLI-21** / **TP-CLI-22** / **TP-CLI-23** still pass in this suite run

## Scope

| Field | Value |
|-------|--------|
| Script / ship unit | `src/grok-cli` 1.8.42 |
| Digest | `0f9bfc9f17ee594845199872f74b91868e251f83ff126166fe93d85dcaaced71` |
| Related requirements | language 1.1.0, default-interaction 2.22.0, interface 2.15.3, storage 1.4.1 |
| Change type | menu number and thirteen language codes |

## Non-findings

| Check | Result |
|-------|--------|
| Language rows **TP-CLI-32** and the front-row proofs | Pass |
| **TP-VCLI-19..36** | Still fail. They are the Termux/proot place class, not this menu change |

**Last Updated:** 2026-10-02
