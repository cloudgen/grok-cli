# Filled run: CL-CLI-DUAL-MENTION — grok-cli 1.8.20 `run`

**Date:** 2026-09-07  
**Blank form:** `docs/templates/checklists/checklist-cli-dual-mention.md`  
**Product / CLI REQ:** grok-cli / `requirement-shell-cli-interface` **2.8.0**  
**Language family:** shell  
**Change type:** new verb `run`

## Verdict

- [x] **Pass** — every routed verb is named on the CLI-interface REQ **and** a topic-owner REQ
- [ ] **Revise**
- [ ] **Block**

## 1. Inventory (blocking)

- [x] Routed verbs listed from `app_main` (`reviews/cli-routed-verb-table.md` scan 2026-09-07: `run` → `gc_run_grok`)
- [x] CLI-interface REQ is `requirement-shell-cli-interface`
- [x] Topic-owner table exists on that CLI REQ (`run` Type 0 `gc_run_grok`)
- [x] Unrouted `restore` remains forbidden

## 2. Two mentions per verb (blocking)

- [x] `run` named on `requirement-shell-cli-interface` (command table, AC-13)
- [x] Topic-owners: `requirement-grok-setup` (18f, samples, AC-26) **and** `requirement-domain-grok-cli` (pillars A–C, samples)
- [x] Topic-owner samples: `grok-cli run` · `grok-cli run -p hello`
- [x] Same-change dual mention
- [x] Help/`app_help` **not** counted as mention 2

## 3. What is not a second mention (blocking)

- [x] `app_help` not counted as mention 2
- [x] README / CHANGELOG not counted as mention 2
- [x] Second paragraph on the CLI REQ is not mention 2

## 4. Role-table verbs

- [x] Unchanged; `run` is Type 0 domain, not a sudoers/DNS verb

## 5. Tests

- [x] **TP-GROK-CLI-46** argv inject / no duplicate / `--json` fail / missing grok Next setup
- [x] **TP-CLI-04** help lists `run`
- [x] Product has no TP-CLI-14 dual-mention scanner (honest: dual mention is REQ-to-REQ)

**Last Updated:** 2026-09-07
