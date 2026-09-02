# Requirement review — grok-setup 2.0.0 (inlined xAI procedure)

**Date:** 2026-09-02  
**Product:** grok-cli **1.6.0**  
**Scope:** `requirement-grok-setup` plus dual-mention peers (`requirement-shell-cli-interface`, `requirement-domain-grok-cli`) and registry  
**Mode:** review + authorized align (user asked to add procedure law and align)

## Registry inventory + foreign/orphan gate (Step −1)

- Registered on disk (in-scope default): 20 Active + 4 superseded — matches `docs/requirements/index.md`
- On disk, **not** in registry: none
- In registry, missing on disk: none
- Foreign candidates: none
- Scope this turn: registry-only; topic = peer `grok` install (`setup`)

## Bootstrap / rewrite gate (Step 0)

- Risk: low for this slice — not a tree rewrite; authorized retarget of existing `requirement-grok-setup`
- Direction: cli-template → folder-backup → grok-cli (unchanged)
- Edits applied this turn: setup law 1.1.0 → **2.0.0**; CLI interface **2.6.0**; domain **1.4.0**; ship unit `gc_setup` inlines the studied procedure
- Reverse-direction evidence: none

## Class gate (Step −2)

- Project nature: software-development
- Class file: Active `requirement-class-software-dev.md` — Pass
- Coding-style related REQ: Active `requirement-shell-script-coding.md` — Pass
- Dest fence / dest approver: class residual none — Pass (N/A this slice)

## Findings

| ID | Severity | File | Finding | Recommendation | Closed? |
|----|----------|------|---------|----------------|---------|
| GS-01 | High | `requirement-grok-setup` 1.1.0 | Law required curling and executing `https://x.ai/cli/install.sh` (third-party bash). Studied installer already does platform + channel pointer + artifact + `~/.grok` place. | Inline that procedure; **MUST NOT** fetch or exec `install.sh`; **MUST NOT** require bash. | Yes — 2.0.0 |
| GS-02 | Medium | CLI / domain dual mention | Still said “curl vendor installer”. | Dual-mention `setup` as channel + artifact on CLI 2.6.0 and domain 1.4.0. | Yes |
| GS-03 | Medium | Implementation Notes | Cited missing egress grant `WA-20260825-001`; whitelist index empty. | Drop invented WA id; name the two HTTPS bases and forbid `/install.sh`. | Yes |
| GS-04 | Low | Tests TP-VCLI-05 | Asserted curl log contains `install.sh`. | Assert channel `/stable` + `grok-` artifact; **MUST NOT** contain `install.sh` (TP-VCLI-13/14). | Yes |
| GS-05 | Info | Termux | Stock Termux is linux-aarch64; musl DNS reads `/etc/resolv.conf`. | PATH candidate `${PREFIX}/bin`; INFO if resolv missing; **MUST NOT** byte-patch. | Yes — in 2.0.0 rules 21 / PATH table |

No remaining Block findings in this slice.

## Dual mention

| Verb | CLI interface | Topic owner | Catalog |
|------|---------------|-------------|---------|
| `setup` | `requirement-shell-cli-interface` 2.6.0 (AC-11) | `requirement-grok-setup` 2.0.0 | `requirement-domain-grok-cli` 1.4.0 |

Invocation samples remain:

```text
grok-cli setup
grok-cli setup --force
grok-cli setup --json
```

## ID notation (Step 0-ID)

- TP primary: TP-VCLI-01..09, 11..14, TP-CLI-04, TP-CLI-13 — Pass
- No harness path dumps in versioned `docs/requirements/**` — Pass
- Optional `RQ-*` not declared (path/key citation) — N/A

## Least privilege (Step 0-LP)

- `setup` remains Type 0, no sudo — Pass
- Egress is version pointer + artifact on `https://x.ai/cli` and GCS fallback; not `install.sh`; not grok-cli `SCRIPT_URL` — Pass
- LPU/LPA: N/A this slice

## Checklist (A–G, this slice)

- A class/registry: Pass
- B dual mention / human-intro / install-mode local-only: Pass (`setup` does not create a grok-cli online channel)
- B2 TP primary: Pass
- B3 Type 0 setup: Pass
- C no session login/home in REQs: Pass (`{{HOME}}` / `~/.grok` families)
- G git-surface: Pass

## Verdict

**Approve with follow-ups closed.** `setup` law now owns the studied grok-build install procedure. Product `gc_setup` matches. Suite **PASS=350 FAIL=0 SKIP=0**.

Optional later (not this turn): live TP-VCLI-10 against public x.ai; a real whitelist grant file if the project starts using that registry.
