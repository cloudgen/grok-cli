# Report: local 1.8.0 menu header + setup smoke — grok-cli 1.8.0

**Date:** 2026-09-03  
**Mode:** local product review (human readability, requirement coverage, checklist coverage, tests coverage, tests) then authorized fix  
**Status:** findings closed in the same change  
**Scratch:** `/tmp/grok-sh-cli-template/grok-review-a97ac605.md`

## Summary

1.8.0 remaps the TTY menu (header `APP_NAME(APP_VERSION)`, session line, backup=1, sudoers=5, `check-session` off the numbered list) and smokes `setup` from `~/.grok/downloads`. Review found leftover **pick 4** locators (now `add-crontab`; SPEC is **3**), grok-setup rule 13 vs 18, thin setup §1.1, missing filled checklists, weak TP-CLI-17 asserts, PTY hang risk, inherited `APP_VERSION`, and SSOT tension on `util_app_ident`. Those are fixed below.

## Human readability

Pass after fix. Default-interaction §1.1 already named the header and session line in everyday English. grok-setup §1.1 now says smoke runs from `~/.grok/downloads` because some phones will not execute `/tmp` or the cache folder.

## Requirement coverage

Claim **C-full-product**. Dispatcher verbs remain dual-mentioned. Registry ↔ disk match. Rule 13 now splits pointer (product storage) vs smoked artifact (`{{GROK_HOME}}/downloads` `mktemp` sibling). AC-7 / interactive AC-4 locators name main **3**.

## Checklist coverage

Filled (git-tracked under `reviews/reports/`; `docs/checklists/` is gitignored by docs policy):

| Checklist | File | Verdict |
|-----------|------|---------|
| CL-CLI-DEFAULT-INTERACTION | `2026-09-03-checklist-cli-default-interaction.md` | Pass |
| CL-OPERATOR-READABLE-ERROR | `2026-09-03-checklist-operator-readable-error-setup-smoke.md` | Pass |
| CL-CLI-DUAL-MENTION | `2026-09-03-checklist-cli-dual-mention.md` | Pass |
| CL-CODE-REVIEW | `2026-09-03-code-review-menu-header.md` | Pass |
| CL-SHELL-CLI-TEST | this report §Tests | Pass (PTY kill + TP-CLI-15/17) |
| CL-PRECOMMIT-CHECK | run at commit gate | pending until commit-check |

## Tests coverage

TP-CLI-13/17 **have** with stronger asserts (adjacent nametag, session under header, gray italic backup explain, submenu nametag, inherited `APP_VERSION` ignored). TP-VCLI-15/16 **have**. TP-GROK-CLI-34 already used pick 3; maps/ACs/lessons now match.

## Issues

All reviewer Issues 1–10 **closed** in this change.

### Issue 1 -- Severity: bug
- File: docs/requirements/requirement-grok-auth-backup.md
- Description: leftover pick 4 locators
- Status: closed (main **3**)

### Issue 2 -- Severity: bug
- File: docs/requirements/requirement-grok-setup.md
- Description: rule 13 vs 18
- Status: closed (pointer vs artifact split)

## Lessons re-checked

L-TYPE-N-01 · L-ARGV-01 · L-PROMPT-CAPTURE-01 (locator updated) · L-AUTH-01 · L-SUDOERS-01/02/06 · L-OUTPUT-01 — still open watch; no regression in this diff.
