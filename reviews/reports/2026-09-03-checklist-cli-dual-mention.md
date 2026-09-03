# Filled run: CL-CLI-DUAL-MENTION — grok-cli 1.8.0

**Date:** 2026-09-03  
**Blank form:** `docs/templates/checklists/checklist-cli-dual-mention.md`  
**Product / CLI REQ:** grok-cli / `requirement-shell-cli-interface` **2.7.0**  
**Language family:** shell  
**Change type:** audit (no new dispatcher verb in 1.8.0; menu layout only)

## Verdict

- [x] **Pass** — every routed verb is named on the CLI-interface REQ **and** a topic-owner REQ
- [ ] **Revise**
- [ ] **Block**

## 1. Inventory (blocking)

- [x] Routed verbs listed from `app_main` (`reviews/cli-routed-verb-table.md` scan 2026-09-03: 21 live)
- [x] CLI-interface REQ is `requirement-shell-cli-interface`
- [x] Topic-owner table exists on that CLI REQ
- [x] Unrouted `restore` is forbidden (not a help verb; dispatcher unknown)

## 2. Two mentions per verb (blocking)

- [x] Each routed verb is named on the CLI-interface REQ
- [x] Topic-owners: default-interaction (`menu`/`main`); zero-arguments (empty argv); local-self-management (`install`/`uninstall`/`where-is-me`); self-management (`version-check`/`self-update`/`self-uninstall`); grok-setup (`setup`); grok-auth-backup (`check-session`/`backup`/`sync-auth`/`sync-auth-from-remote`); grok-crontab (`add-crontab`); three-layer + sudoer-json (`print-sudoers*` / `remove-project-sudoers` / `generate-sudoer-request` / `submit-sudoer-request`); domain grok-cli (surface catalog)
- [x] Topic-owners have `grok-cli …` invocation samples
- [x] No new verb this change
- [x] `check-session` remains dual-mentioned; it was removed only from the numbered menu

## 3. What is not a second mention (blocking)

- [x] `app_help` not counted as mention 2
- [x] README / CHANGELOG not counted as mention 2
- [x] Second paragraph on the CLI REQ is not mention 2

## 4. Role-table verbs

- [x] `print-sudoers` / `generate-sudoer-request` / `submit-sudoer-request` dual-mentioned on three-layer + sudoer-json
- [x] No DNS inbound verbs
- [x] Privilege role table stays on three-layer

## 5. Tests

- [x] TP-CLI-04 lists verbs in help; TP-CLI-13/17 cover menu membership. Product has no TP-CLI-14 dual-mention scanner (honest: dual mention is REQ-to-REQ; help is not mention 2)
- [x] Status **have** for membership TPs after suite green
