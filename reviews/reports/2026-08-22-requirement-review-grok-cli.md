# Requirement review — grok-cli 1.0.0

**Date:** 2026-08-22  
**Mode:** review + authorized fix (user: review requirements, revise plans, review, test, fix)  
**Status:** follow-ups closed in same turn (grant identity, §1.1, DTV, coding-style REQ, plans)

## Registry inventory + foreign/orphan gate (Step −1)

- Registered on disk: 21 `requirement-*.md` (17 Active + 4 superseded) match `docs/requirements/index.md`
- Orphans: none
- Ghosts: none
- Foreign candidates: **intentional bootstrap lineage** (folder-backup hop-1 names in `requirement-bootstrap-chain` / class history) — keep as lineage, not this-product identity
- Scope: registry-only (full disk tree equals registry)

## Bootstrap / rewrite gate (Step 0)

- Risk: yes — dest specialized from folder-backup
- Direction: folder-backup (A, sibling) → grok-cli (B); architecture shared Type 0 + privilege
- User authorized fix this turn
- Reverse-direction evidence: none (sibling folder-backup not overwritten)

## Findings (pre-fix)

| ID | Severity | File | Finding | Fix |
|----|----------|------|---------|-----|
| RR-01 | bug | sudoer-json / three-layer | Implementation Notes still required `backup` **and** `restore` | Retargeted to `grok-cli backup` only |
| RR-02 | bug | several Active REQs | This-product identity still `folder-backup` / `src/folder-backup` | Retargeted APP_NAME, bins, store |
| RR-03 | high | reviews/test-plan.md | Plans still TP-FOLDER-BACKUP 1.9.0 | Rewritten TP-GROK-CLI / 1.0.0 |
| RR-04 | high | class gate | No coding-style related REQ | Added `requirement-shell-script-coding` |
| RR-05 | medium | 13 Active REQs | Missing §1.1 Human-facing | Inserted |
| RR-06 | medium | domain + ops | Missing DTV | Inserted TP tables |
| RR-07 | nit | Status headers | File versions lagged index | Aligned 2.0.0 / 1.1.0 |

## Coverage gaps

- automatic-checksum: **N/A** (local-only)
- dest fence-test: **N/A** (class residual: no dest fence)
- dest approver: **N/A** (class residual: no dest approver; sudoer-adm is sibling)
- artifact samples: domain JSON grant samples present
- dual mention: check-session / backup / sync-auth on CLI + domain/ops

## ID notation

- TP-* primary on DTV: Pass after insert
- RQ-* optional unused: N/A
- Pollution: none dumped into index

## Least privilege

- Type 0/1 map: Pass (`backup` elevated; `sync-auth` Type 0)
- No Type 2
- LPU/LPA: N/A (no dest machine)

## Verdict

**Approve with follow-ups closed** after this-turn fixes. Residual: some history rows still name folder-backup as past product (honest).

## Checklist A–G

A Pass · B Pass after coding-style · B2 Pass · B3 Pass (privilege in scope) · C Pass after retarget · D Pass · E Pass · F Pass · G Pass (index requirement rows only)
