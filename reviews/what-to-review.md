# What to review — grok-cli

**Living checklist** (review plan). Product: **grok-cli** local self-managed CLI + grok auth backup/sync + narrow sudo deposit.  
**Class:** software-development · domain SSOT present · **local-only** install channel (online package intentionally absent).  
**Always load first:** `reviews/lessons.md`

**Last plan update:** 2026-08-23  
**Ship unit VERSION:** 1.1.0  
**Suite baseline:** `reviews/test-plan.md`

---

## Pre-flight

| # | Check | Notes |
|---|--------|--------|
| P1 | Read `docs/requirements/index.md` | Class + architecture + shell + domain grok-cli + grok-auth-backup + three-layer |
| P2 | Confirm ship unit `src/grok-cli` | `APP_NAME` / `VERSION` hard-assign (**1.1.0+**) |
| P3 | Load `reviews/lessons.md` and re-check every open L-* | Mandatory (esp. **L-SUDOERS-01/02** · **L-SUDOERS-06** · **L-OUTPUT-01** · **L-AUTH-01**) |
| P4 | Run `./tests/run.sh` | Record PASS/FAIL/SKIP; **must include TP-GROK-CLI-22e** and **TP-24*/25*** when generate/submit is in scope |
| P5 | Confirm install **channel** still local-only | No SCRIPT_URL product UX |
| P6 | Privilege law | three-layer **2.0.0** · sudoer-json **2.0.0** (`backup` only) · operator-readable-error |
| P7 | Host elev posture | Global vs local binary; trust tier; `/etc/sudoers.d/grok-cli-<user>` |
| P8 | **JSON re-encode / inbound fidelity** | Pretty convert + submit inbound still has `backup` |
| P9 | **Host fragment → submit update** | TP-GROK-CLI-23* |
| P10 | **Independent generate dest** | TP-GROK-CLI-24* |
| P11 | **Operator-readable errors** | TP-GROK-CLI-25* |
| P12 | **Session gate + sync-auth** | TP-GROK-CLI-03..10 · 12 |

---

## Product law surfaces

| Surface | Path | Review focus |
|---------|------|--------------|
| Class | `requirement-class-software-dev.md` | posix-sh, local-only, coding-style pointer |
| Bootstrap chain | `requirement-bootstrap-chain.md` | cli-template → folder-backup → grok-cli |
| Project folder | `requirement-project-folder.md` | `src/grok-cli`, bins, `/var/grok-cli` |
| **Privilege / sudoers** | `requirement-three-layer-privilege-model.md` | Type 0/1; `sudo grok-cli backup` only |
| **JSON sudoer file** | `requirement-sudoer-json-file.md` | `grok-cli backup` only; no OS tools |
| **Auth ops** | `requirement-grok-auth-backup.md` | Session gate; deposit; sync-auth |
| **Operator-readable error** | `requirement-operator-readable-error.md` | Blocking `[ERROR]` next step |
| CLI interface | `requirement-shell-cli-interface.md` | check-session / backup / sync-auth |
| Empty argv Type N | `requirement-shell-cli-zero-arguments.md` | TTY = numbered menu; off-TTY = help; never install |
| Local self-management | `requirement-shell-local-self-management.md` | install/uninstall; 0755 |
| Output SSOT | `requirement-shell-output-requirements.md` | `out_*` |
| Modular design | `requirement-shell-modular-function-design.md` | `gc_*` |
| Coding style | `requirement-shell-script-coding.md` | `set -u`, fail-closed |
| Domain | `requirement-domain-grok-cli.md` | Four pillars |
| Superseded | folder-archive + domain-folder-backup | Must stay superseded; do not revive restore |

**Intentionally absent:** online-install, remote self-management, companion checksum, dest fence-test (no dest machine).

---

## High-risk paths (ship unit)

| Path / symbol | Risk | Lesson / TP |
|--------------|------|-------------|
| Empty argv | Type O install leak; off-TTY hang on numbered menu | L-TYPE-N-01 · L-ARGV-01 · TP-CLI-07 |
| `gc_backup` | Deposit without session or without grant | L-AUTH-01 · L-DEPOSIT-01 · TP-GROK-CLI-06/12 |
| `gc_sync_auth` | Uses sudo or leaves dest world-readable | L-SYNC-01 · TP-GROK-CLI-09 |
| `gc_print_sudoers` | Restore verb or OS-tool Cmnds | L-SUDOERS-01 · TP-GROK-CLI-01/22 |
| `gc_submit_sudoer_request` | Inbound drop backup; jargon-only error | L-SUDOERS-06 · L-OUTPUT-01 · TP-25* |
| Tokens in logs | Printing JWT/refresh | L-AUTH-01 · (static: no token print) |
