# Requirement review: empty argv → numbered menu (grok-cli 1.1.0)

**Date:** 2026-08-23  
**Reviewer:** product council  
**Product:** grok-cli `VERSION=1.1.0`  
**Ship unit:** `src/grok-cli`  
**Scope:** `requirement-shell-cli-zero-arguments` · `requirement-shell-cli-default-interaction` · `requirement-shell-cli-interface` plus peer pointer updates  
**Method:** disk read + `./tests/run.sh`  
**Baseline:** PASS=242 FAIL=0 SKIP=0

## Registry inventory + foreign/orphan gate (Step −1)

- **Registered on disk (in-scope default):** 18 Active + 4 superseded (22 files). Registry `docs/requirements/index.md` matches disk `requirement-*.md` basenames.
- **On disk, not in registry:** none
- **In registry, missing on disk:** none
- **Foreign candidates:** none (notes name grok-cli)
- **Scope this turn:** registry-only, focused on empty-argv / default-interaction / CLI-interface

## Bootstrap / rewrite gate (Step 0)

- **Risk:** yes — bootstrap chain cli-template → folder-backup → grok-cli
- **Direction:** A = cli-template (via folder-backup) → B = grok-cli; shared Type 0 architecture = yes
- **Edits this turn:** authorized by user (“update requirement”); surgical empty-argv law, not a tree rewrite
- **Reverse-direction evidence:** none

## Class gate (Step −2)

- **Class:** software-development
- **Class file:** Active `requirement-class-software-dev.md` (1.2.1)
- **Verdict:** Pass

## ID notation compliance (Step 0-ID)

- DTV uses **TP-CLI-07** / **TP-CLI-13** (Pass)
- No Skill-ID / Mold-ID inventory dumps in versioned requirements (Pass)
- Optional **RQ-*** not declared (N/A)

## Least privilege / LLM escape (Step 0-LP)

- N/A for this empty-argv change (no privilege Type map change)

## Findings

| ID | Severity | File | Finding | Recommendation | Needs user OK? |
|----|----------|------|---------|----------------|----------------|
| GC-ARGV-01 | P2 | zero-arguments 1.2.0 (pre-change) | Empty argv was help while user ordered TTY menu | Revised to 1.3.0: TTY menu; off-TTY help; Type N | no (user ordered) |
| GC-ARGV-02 | P3 | bootstrap/class/coding/interactive | Pointer files changed without version bump | Bumped 3.0.1 / 1.2.1 / 1.0.1 / 1.0.1 | no |

No open P0/P1. GC-ARGV-01 and GC-ARGV-02 **fixed** in this change.

## Coverage

- Empty argv Type N (not install): AC-1/2/3 · TP-CLI-07
- Off-TTY empty argv help: AC-4 · TP-CLI-07 / TP-CLI-13
- TTY empty argv numbered list: AC-5 · TP-CLI-07
- `menu`/`main` still live: AC-8 · TP-CLI-13
- `--json` no command stays JSON help: TP-CLI-07
- Human-facing §1.1 present on the three primary REQs (Pass jargon scan: lead sentences are operator actions, not catalog codes)

## Git-surface

- No `docs/templates/` · `docs/skills/` · `docs/terminologies/` · `docs/incidents/` · `docs/checklists/` prefixes in `docs/requirements/**`

## Verdict

**Approve with follow-ups closed.** Case 3 remains (zero-arg REQ exists). That REQ now defers TTY empty argv to the numbered list. Off-TTY stays Type N help. Type O remains absent.
