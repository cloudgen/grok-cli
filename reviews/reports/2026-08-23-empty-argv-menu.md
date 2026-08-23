# Report: empty argv menu — grok-cli 1.1.0

**Date:** 2026-08-23  
**Mode:** product review after empty-argv route change (law + ship unit + suite + plans)  
**Status:** clean (suite green)

## Summary

Empty argv (`$# -eq 0`) now sets `COMMAND=menu` and runs `app_default`. On a real terminal that is the numbered start list. Off-TTY it stays help. `--json` with no command still defaults to JSON help (not empty argv). Type N is unchanged: empty argv never install-ensures. Lessons loaded. Suite **PASS=242 FAIL=0 SKIP=0**.

## Pre-flight

- P1 index: grok-cli law (zero-arguments 1.3.0 · default-interaction 1.7.0 · interface 2.2.0)
- P2 APP_NAME=grok-cli VERSION=1.1.0
- P3 lessons re-checked (L-TYPE-N-01 still Type O leak; new **L-ARGV-01** off-TTY hang)
- P4 suite green (PASS=242 FAIL=0 SKIP=0)
- P5 local-only (no SCRIPT_URL / self-update)

## Lessons re-check

| ID | Result |
|----|--------|
| L-TYPE-N-01 | PASS — empty argv is not install-ensure (TP-CLI-07 off-TTY help; TTY menu) |
| L-ARGV-01 | PASS — off-TTY empty argv is help, not `9. Exit` (TP-CLI-07 / TP-CLI-13) |
| L-ONLINE-01 | PASS — TP-CLI-04/10 still reject online verbs |
| L-OUTPUT-01 | not in this diff (no new fatals) |

## Issues

### Issue 1 -- Severity: nit
- File: `src/grok-cli` `app_main`
- Description: Empty argv now shares `app_default` with `menu`/`main` instead of early `app_help`.
- Suggestion: Keep one handler (done).
- Lesson: L-ARGV-01
- Test: TP-CLI-07
- Status: closed

No open bugs.

## JSON re-encode / inbound fidelity

Not in this diff. Prior TP-GROK-CLI-22e/22f/25 still green in this suite run.

## Operator-readable errors

Not in this diff. No new `out_die` on the empty-argv path (help or menu).

## Type 1 TTY traps

Unchanged. Empty argv does not call `backup`. Menu pick of `backup` still uses the existing Type 1 path.

## Test lock-in

TP-CLI-07 now proves: off-TTY help, `--json` no-command JSON help, TTY numbered list, not install. TP-CLI-13 still proves `menu`/`main` and off-TTY empty argv help.

## Verdict

**Pass**
