# Report: human readability + coverage — grok-cli 1.8.9

**Date:** 2026-09-06
**Mode:** review + authorized implement
**Status:** findings closed (residuals noted)

## Summary

Product README Features led with workshop codes (`ET_EXEC`, CIAO Protection Zones, `out_*`). Related Projects led with **Type 0**. Last Update duplicated CHANGELOG.

All 24 Active requirements already had **§1.1 Human-facing**. Grant samples in three Active files froze a session Unix login. Related shell requirements were missing the exact heading **Under command line for normal user only** (skill 2026-09-05). CLI interface Type 1 still named leftover `/var/backup`. Idempotency human-facing still talked about dated tar.gz. Ship unit header still said online install was absent.

Coverage: RTM already mapped Active REQs to TP families. Added **TP-CLI-18** so Active requirement samples cannot freeze a session login. Filled product checklists for this pass live in `reviews/` (not genesis harness runs under `docs/checklists/`).

## Issues

### Issue 1 -- Severity: bug
- File: docs/requirements/requirement-sudoer-json-file.md (samples)
- Description: JSON/sudoers examples used a frozen Unix login.
- Suggestion: Samples use `id -un`.
- Lesson: L-NEX-01
- Test: TP-CLI-18
- Status: closed

### Issue 2 -- Severity: bug
- File: docs/requirements/requirement-shell-cli-interface.md (command table Type 1 row)
- Description: Type 1 deposit still said leftover `/var/backup`.
- Suggestion: `/var/grok-cli` auth copy.
- Status: closed

### Issue 3 -- Severity: suggestion
- File: README.md (Features / Related Projects / Last Update)
- Description: Features and Related Projects led with catalog/workshop talk; Last Update was a changelog dump.
- Suggestion: Everyday words; current date; history in CHANGELOG.
- Status: closed

### Issue 4 -- Severity: suggestion
- File: docs/requirements/ (related shell REQs)
- Description: Missing exact heading **Under command line for normal user only**.
- Suggestion: Print the heading; Termux/Git Bash/Windows cmd stay this-login.
- Status: closed

## Residual (not this turn)

- Dedicated `requirement-shell-sudo-command` is still unregistered; studied `sudo grok-cli backup` allowlist lives on `requirement-three-layer-privilege-model`. P1.
- Output-only REQs (`requirement-shell-output-requirements`, `requirement-operator-readable-error`) honestly omit the Termux heading.
- Superseded folder-archive files may still contain historical sample logins; they are not Active law.

## Suite

`./tests/run.sh` — PASS=479 FAIL=0 SKIP=0 (includes TP-CLI-18).
