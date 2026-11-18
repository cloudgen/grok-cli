# Review: uname wrapper — grok-cli 1.8.49

**Date:** 2026-11-17
**Ship unit:** `src/grok-cli` **1.8.49**
**Law:** `requirement-shell-script-coding` **1.2.0** · `requirement-shell-cli-interface` **2.16.1** · `requirement-shell-cli-zero-arguments` **2.2.1** · `requirement-actor-role-subject` **1.0.0**
**Suite:** `sh tests/run.sh` PASS=1213 FAIL=0 SKIP=0

## Verdict

**Pass.** Host reads go through `util_uname`. `--uname-s WORD` and `--uname-a WORD` inject the `-s` and `-a` lines. `-m`, `-o`, and `-r` stay the real `uname`. A missing, empty, or dash-leading WORD dies with `Next:`. The operand is not a command token.

## What changed

- `util_uname` is the only product call of the `uname` binary. Setup still uses `command -v uname`, which does not run `uname`.
- The switches are parsed before `util_resolve_storage` and again in the flag loop, so they work before or after the verb.
- Android setup tests pass `--uname-a` with a line that contains `Android`. The Git Bash setup test passes `--uname-s MINGW64_NT-10.0`. Neither test creates a regular file named `uname`.
- Human help lists both switches under Test-purpose. JSON help names them and does not print a sample host line as a command.
- **TP-ARS-01** reads the light catalog: Actor, Role, Subject; this login; Subject None; no Approver column.

## Suite

The previous full run was PASS=1110 FAIL=56. Those 56 were **TP-VCLI-19** through **TP-VCLI-36** (except the cases that never replaced `uname`). The sandbox refused a PATH file whose basename is `uname`. This run is PASS=1213 FAIL=0 SKIP=0. Cleanup of `/tmp/fb-home.*` is still refused by safe-rm. That refusal is not an assertion failure.

## Left as-is

- Fallback `: "${VERSION:=1.8.43}"` stays.
- `sync-to-remote` and auth menu **17** stay as shipped in **1.8.48**.
- No commit and no push in this change.
