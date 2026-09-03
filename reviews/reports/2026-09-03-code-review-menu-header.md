# Filled run: CL-CODE-REVIEW — grok-cli 1.8.0 menu header / setup smoke

**Date:** 2026-09-03  
**Blank form:** `docs/templates/checklists/code-review.md`  
**Change summary:** TTY menu header `APP_NAME(APP_VERSION)`, session line, drop `check-session` row (backup=1, sudoers=5); `setup` smoke from `~/.grok/downloads` with captured `--version` failure. Review locators and rule 13 vs 18 fixed in the same change.
**REQ-IDs:** `requirement-shell-cli-default-interaction` 2.1.0 · `requirement-grok-setup` 2.1.0 · `requirement-shell-output-requirements` 1.0.3 · `requirement-grok-auth-backup` 1.1.3
**Diff scope:** `src/grok-cli`, `tests/test_cli.sh`, `tests/test_grok_setup.sh`, `tests/helpers.sh`, requirements + reviews maps, README/CHANGELOG/SECURITY

## Correctness

- [x] Behavior matches cited requirements
- [x] Edge cases: off-TTY `menu` help; TTY `--json` ignored; inherited `APP_VERSION` ignored; smoke fail-closed
- [x] No obvious off-by-one in menu numbering
- [x] Failures loud (`out_die` with Next)
- [x] Changed blocking `out_die` (setup smoke) scored **CL-OPERATOR-READABLE-ERROR** Pass

## Design and maintainability

- [x] Follows existing `out_*` / `app_default_*` patterns
- [x] Change is scoped (PTY helper extracted to `ci_pty_capture` to stop hang)
- [x] Names clear (`util_app_ident`, `out_menu_row`, `gc_session_status_word`)
- [x] Comments explain why (downloads vs noexec)

## Requirements and docs

- [x] Durable intent updated in `docs/requirements/`
- [x] README / CHANGELOG updated
- [x] Product source ALIGNMENT cites live `requirement-*.md`
- [x] Domain law still `requirement-domain-grok-cli`
- [x] No template/skill as behavioral authority in the ship unit
- [x] No invented requirement names
- [x] README Install unchanged (not this change)
- [x] No new dispatcher verb (dual mention audit Pass)
- [x] Sudoer verbs unchanged

## No-placeholder + no-hardcode

- [x] No TODO/FIXME/TBD in delivered paths
- [x] No changeme slots
- [x] No stubs
- [x] No toy credentials as production
- [x] No toy install hosts
- [x] No hollow sections
- [x] Gaps tracked (TP-VCLI-10 live fetch remains optional)
- [x] Diff does not hardcode into `docs/templates/**`
- [x] README/CHANGELOG excluded from no-hardcode

## Tests

- [x] TP-CLI-13/17, TP-VCLI-15/16, TP-GROK-CLI-34 cover new behavior and hang/fail paths
- [x] Isolated HOME; fake curl/scp; PTY kill on timeout
- [x] Flaky hang path closed (`ci_pty_capture` SIGTERM)

## CIAO cross-check

- [x] Protection zones respected
- [x] `set -u` defaults unchanged (N/A for new vars: `APP_VERSION` now hard-assigned)
- [x] Type 1 interactive sudo not in this diff (N/A **CL-SHELL-TTY-PRIVILEGE-TRAPS**; backup grant unchanged)
- [x] No `$(prompt_` / `$()` of `read` (TP-CLI-15)

## Findings closed this pass

Reviewer scratch (`/tmp/grok-sh-cli-template/grok-review-a97ac605.md`) Issues 1–10 addressed in this change: pick-4 locators, setup rule 13, §1.1 noexec sentence, filled checklists, TP-CLI-17 nametag/session/submenu, PTY kill, `APP_VERSION` pin, `util_app_ident` exception B2, smoke period, verb-table scan date.
