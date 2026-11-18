# Review: setup place diagram — grok-cli 1.8.50

**Date:** 2026-11-18  
**Ship unit:** `src/grok-cli` **1.8.50**  
**Law:** `requirement-grok-setup` **2.16.0** (unchanged). The figure restates that procedure.

## Scope

README section **Where setup installs grok** and `images/grok-install-where.png`.

The figure shows `uname -s` and `uname -m` naming the artifact, the shared version pointer, and the three place results under `~/.grok` (or `GROK_HOME`): Linux and macOS symlinks, an Android wrapper around the unmodified `linux-*` file, and a Git Bash / MSYS / Cygwin copy of `grok.exe`. The cache host kind stays off that URL and folder.

## Verdict

**Pass.** No setup behavior changed. Full `sh tests/run.sh` at 1.8.50 is PASS=1213 FAIL=0 SKIP=0. Product version is 1.8.50 so the README badge matches `VERSION=`.
