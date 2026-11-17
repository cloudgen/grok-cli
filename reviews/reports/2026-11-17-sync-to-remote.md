# Review: sync-to-remote — grok-cli 1.8.48

**Date:** 2026-11-17
**Scope:** Verb `sync-to-remote`. Auth menu **17**. `--json` does not prompt. Help, requirements, reviews, and README screens.
**Law:** `requirement-grok-auth-backup` **1.11.0** · `requirement-shell-cli-default-interaction` **2.28.0** · `requirement-shell-cli-interface` **2.16.0** · `requirement-domain-grok-cli` **1.11.0**.
**Proof:** **TP-GROK-CLI-51** · **TP-CLI-04** · **TP-CLI-13** · **TP-CLI-17** · **TP-CLI-19** · **TP-CLI-20** · **TP-CLI-31**
**Checklist:** local filled run `docs/checklists/2026-11-17-implementation-ciao-sync-to-remote.md` (not tracked).
**Suite:** `tests/run.sh` on 2026-11-17: PASS=1110 FAIL=56 SKIP=0. Every failure is **TP-VCLI** after the sandbox refused to create a fake `uname` (treated as a system binary). **TP-CLI** and **TP-GROK-CLI-51** passed. The same FAIL=56 count is recorded on the 2026-10-02 language review.

## Verdict

**Pass** for this change. `sync-to-remote` checks `~/.grok` before any prompt, copies regular non-empty `auth.*` files onto each named login’s `~/.grok` with ssh and scp in BatchMode, and does not skip a logged-in session. Auth **17** is that verb on every host and in both sessions. **18** is not a row. `sync-auth-to-remote` stays typed-only. The verb does not write `preferred-remote` and does not print token values.

## What was checked

| Check | Result |
|-------|--------|
| Missing `~/.grok` and empty grok home fail closed with Next | Pass (**TP-GROK-CLI-51**) |
| `--json` with no operands does not prompt and is `out_error` | Pass |
| Two-host operand form copies `auth.json` and `auth.extra`; chmod 0600 | Pass (fake ssh and scp) |
| Logged-in session still pushes and does not print the pull-skip sentence | Pass |
| JSON type `sync-to-remote`, message `ok`, remotes and counts, no token | Pass |
| `preferred-remote` unchanged after the push | Pass |
| Logged-out, logged-in, and Termux menus list `17. sync-to-remote` | Pass (**TP-CLI-13** · **17** · **19** · **20** · **31**) |
| Pick **18** is not a menu choice | Pass |
| Hide lines do not name `sync-to-remote` | Pass |
| Real PTY capture of the top list and both auth lists is in README | Pass |

## Follow-ups

None that block this release. The 56 **TP-VCLI** failures need a host that can place a fake `uname` on `PATH`. They are not caused by this verb.

## Remediation order

None for `sync-to-remote`.
