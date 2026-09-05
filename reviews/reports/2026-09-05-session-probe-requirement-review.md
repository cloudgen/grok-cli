# Requirement review — live `grok -p hello` session gate

**Date:** 2026-09-05  
**Scope:** registry-only (this product)  
**Class gate:** software-development — Active `requirement-class-software-dev.md`

## Registry inventory (Step −1)

- Registered on disk: 24 Active + 4 superseded (index matches disk)
- Orphans: none
- Ghosts: none
- Foreign candidates: none
- Scope this turn: registry-only

## Bootstrap / rewrite gate (Step 0)

- Risk: no rewrite of bootstrap origin
- Direction: folder-backup → grok-cli (unchanged)
- Edits: authorized by user (“update requirement … implement”)

## Termux coverage

| Slice | Owner | Verdict |
|-------|--------|---------|
| Detect / PREFIX / pkg / noexec | `requirement-shell-termux-coding` 1.1.0 | Pass — added session-probe writing (stdin closed, exec resolved peer, fake Core `GROK_BIN`) |
| `setup` procedure | `requirement-grok-setup` | Unchanged; still owns wrapper / resolv |
| Session procedure | `requirement-grok-auth-backup` 1.2.0 | Pass — live `grok -p hello` is the gate |
| `/var/grok-cli` | grok-auth-backup | Pass — no Termux substitute invented |

**Gap closed:** file-only `auth.json` parse hid Termux DNS / wrapper / `ET_EXEC` failures.

## Findings

| ID | Severity | File | Finding | Recommendation | Needs user OK? |
|----|----------|------|---------|----------------|----------------|
| — | — | — | none open after implement | — | no |

## Coverage gaps

- Session gate now has TP-GROK-CLI-03..05, 35..38 (have)
- Menu session line: TP-CLI-17 (have)
- Core tests do not hit xAI

## ID notation

- TP primary on DTV: Pass
- No SK/LM inventory dumps in versioned REQs: Pass

## Least privilege

- N/A change (Type 0 probe; backup elev unchanged)

## Checklist A–G

- A registry/class: Pass
- B dual mention + human-facing: Pass
- C dual policy / no session login freeze: Pass (`{{HOME}}` / `~/.grok`)
- D naming: Pass
- E protection: Pass
- F no unauthorized weakening: Pass (file check replaced by stronger live probe per user order)
- G git-surface: Pass

## Verdict

Authorized edits done. Suite green (PASS=478 FAIL=0 SKIP=0).
