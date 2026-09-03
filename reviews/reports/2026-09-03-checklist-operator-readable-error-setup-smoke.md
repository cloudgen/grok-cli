# Filled run: CL-OPERATOR-READABLE-ERROR — setup smoke `--version`

**Date:** 2026-09-03  
**Blank form:** `docs/templates/checklists/checklist-operator-readable-error.md`  
**Product:** grok-cli  
**Command / path:** `gc_setup` → `gc_setup_smoke_version` fail → `out_die`  
**Error text (shape):** `The downloaded grok failed to run --version (exit 7: boom-from-smoke). This did not install grok-cli. Next: check the download, then grok-cli setup.`

## E1 — What happened (blocking)

- [x] One concrete sentence: the downloaded grok failed to run `--version`
- [x] Not only an incident ID

**Result:** Pass

## E2 — What it means

- [x] E1 is already plain; optional `(exit N: stderr)` is captured fact, not jargon

**Result:** Pass

## E2b — Human-intro jargon ban

- [x] Line is not only Type 0 / euid / F6
- [x] Who / which folder / what to type next is in ordinary words

**Result:** Pass

## E3 — What to do next (blocking)

- [x] `Next: check the download, then grok-cli setup`

**Result:** Pass

## E4 — Do not

- [x] N/A — no dangerous approve/delete next step

**Result:** N/A

## E5 — Channel / SSOT (blocking)

- [x] Printed via `out_die`
- [x] Quiet still shows the error (fatal)

**Result:** Pass

## E6 — Fail-closed honesty (blocking)

- [x] Smoke still fail-closed; tmp binary removed; existing install kept
- [x] “This did not install grok-cli” names the product

**Result:** Pass

## E7 — JSON

- [x] `out_die` emits JSON error when `JSON=1`; `message` is the same sentence

**Result:** Pass

## Verdict

| Field | Value |
|-------|--------|
| E1–E6 + E2b | Pass |
| E7 | Pass |
| Overall | **Pass** |
| Fail-closed removed to pass? | **no** |

**Suite:** TP-VCLI-16
