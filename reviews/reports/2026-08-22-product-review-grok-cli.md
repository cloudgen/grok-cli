# Report: full product — grok-cli 1.0.0

**Date:** 2026-08-22  
**Mode:** product review after requirement retarget + plan revision  
**Status:** clean (suite green)

## Summary

Ship unit `src/grok-cli` matches domain: session gate, `/var/grok-cli` deposit, unprivileged `sync-auth`, JSON grant `backup` only. Review/test plans retargeted from folder-backup. Lessons loaded. Suite **PASS=207 FAIL=0 SKIP=0**.

## Pre-flight

- P1 index: grok-cli law  
- P2 APP_NAME=grok-cli VERSION=1.0.0  
- P3 lessons retargeted (L-AUTH-01, L-SYNC-01, L-DEPOSIT-01)  
- P4 suite green  
- P5 local-only  
- P8–P12 JSON/session/generate/operator-readable covered by TP-GROK-CLI-22e / 24* / 25* / 03–12  

## Issues

### Issue 1 -- Severity: nit
- File: `reviews/lessons.md` historical INC-20260817-001 still names restore-era inbound
- Description: Lesson L-SUDOERS-06 retargeted; incident files remain historical folder-backup
- Suggestion: keep incidents as history
- Status: closed (lesson text updated; incidents stay)

No open bugs.

## JSON re-encode / inbound fidelity

TP-GROK-CLI-22e pretty convert keeps `grok-cli backup`. TP-22f stub inbound has backup not restore. TP-25 fail-closed when inbound omits backup.

## Operator-readable errors

TP-GROK-CLI-03/06/10/12/25 assert what-happened + next step (`grok login` / `backup` / `generate-sudoer-request` / `install`).

## Type 1 TTY traps

Product Type 1 is passwordless `sudo -n /usr/local/bin/grok-cli backup` (NOPASSWD grant). No interactive password-sudo ladder in ship unit. Negative fail-closed: TP-GROK-CLI-12. Interactive password sudo **n/a**.

## Test lock-in

New TP-GROK-CLI-12 (production dest without global binary). Plans/RTM updated.

## Verdict

**Pass**
