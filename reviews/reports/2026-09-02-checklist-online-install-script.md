# Filled run: CL-ONLINE-INSTALL-SCRIPT — grok-cli 1.7.0

**Date:** 2026-09-02  
**Blank form:** `docs/templates/checklists/checklist-online-install-script.md`  
**Product:** grok-cli (`src/grok-cli`)  
**Change type:** new installer + empty-argv + self-update reuse + review existing  
**Claims `curl | sh`:** yes  
**Empty-argv type:** Type O-S off-TTY; TTY numbered menu (case 3)  
**Channel:** `SCRIPT_URL` composed `https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main/src/${APP_NAME}`  
**Related law:** `requirement-shell-online-install` · `requirement-shell-cli-zero-arguments` · `requirement-shell-automatic-checksum` · `requirement-shell-self-management`

## Verdict

- [x] **Pass** — ready to ship  
- [ ] **Revise**  
- [ ] **Block**

Reviewer / role: Implement + Review (this change)  
Date: 2026-09-02

## 1. Bootstrap / entry gate

- [x] `app_main` is the entry  
- [x] Pipe `curl | sh` calls `app_main "$@"` (no basename gate)  
- [x] `$0` under pipe is not Config identity  
- [x] Off-TTY empty argv install-ensure lives inside the dispatcher (`COMMAND=ensure` → `inst_channel_ensure`)  
- [x] TTY empty argv is the numbered menu (authorized case 3; **not** a pipe path)

**Block check:** one-liner cannot succeed without `app_main` — Pass.

## 2. One-liner / zero-arg (Type O)

- [x] README has a literal `curl -fsSL https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli | sh`  
- [x] Off-TTY empty argv is install-ensure, not help (TP-CLI-07 · TP-ONL-01)  
- [x] Already installed → success no-op (TP-CLI-07)  
- [x] `--json` with no command stays JSON help (flags-only)  
- [x] TTY empty argv does **not** install-ensure (TP-CLI-07 PTY)

## 3. Integrity

- [x] Automatic `${SCRIPT_URL}.sha256` (match / mismatch abort / missing warn) — TP-ONL-02  
- [x] Companion file `src/grok-cli.sha256`  
- [x] `CHECKSUM` not on help/about (TP-CLI-04 / 06)

## 4. Place / PATH / lifecycle

- [x] Atomic stage → chmod 0755 → mv  
- [x] User vs global by uid  
- [x] `version-check` / `self-update` / `self-uninstall` routed (TP-CLI-10 · TP-ONL-03/04)  
- [x] Checkout `install` still copies running file (TP-LC-*)  
- [x] Dual-mode matrix filled on `requirement-shell-online-install`

## Notes

Pipe stdin is never a TTY, so `curl | sh` always takes the Type O branch. Interactive `grok-cli` at a prompt keeps the daily-work menu.
