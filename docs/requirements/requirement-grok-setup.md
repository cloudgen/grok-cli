**file**: docs/requirements/requirement-grok-setup.md  
**Status**: Active (Version 1.1.0)  
**Area**: domain  
**Key**: `requirement-grok-setup`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **operations Single Source of Truth** for grok-cli **`setup`**: a Type 0 command that **downloads xAI’s published grok installer** and runs it so the **peer `grok` CLI** is installed (vendor default `~/.grok/bin`). Operators can then `grok login` and use `grok-cli check-session` / `backup`. A PATH line written to `~/.bashrc` does **not** apply to the current session; that is not an install failure.

This does **not** install grok-cli itself (that remains local `install`). This does **not** add an online-install channel for grok-cli (`SCRIPT_URL` stays empty).

### 1.1 Human-facing

**In one sentence:** you type `grok-cli setup` so this login fetches xAI’s installer and places the `grok` program; then you `grok login`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Run setup without sudo | `grok-cli setup` |
| The other role | xAI publishes the installer; grok-cli does not ship grok | `https://x.ai/cli/install.sh` |
| Not this file | grok-cli’s own copy-to-bin; sudo backup; session parse | `grok-cli install` · `grok-cli backup` |

| Includes | Excludes |
|----------|----------|
| Fetch + run vendor installer; skip if `grok` already works; `--force` | Installing grok-cli; `self-update`; empty-argv install-ensure; sudo |
| Fail closed if curl/bash/download fails | Hitting the public network from Core tests |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/grok-cli` | ship unit | live `setup` |
| `grok-cli help` | command | listed `setup` row |
| `grok` | peer CLI after setup | `grok login` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| First machine | grok-cli downloads xAI’s script and runs it | `grok-cli setup` |
| grok already there | success, no download | `grok-cli setup` |
| Replace grok | fetch again | `grok-cli setup --force` |
| Sign in after | session files appear under `~/.grok` | `grok login` then `grok-cli check-session` |

Jargon: this is ordinary-user work, not a root host bootstrap and not grok-cli’s own installer.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Verb

1. **MUST** route **`setup`** from `app_main`.  
2. **MUST** be Type 0 (invoking login). **MUST NOT** require `sudo` to fetch or run the vendor script.  
3. **MUST** appear in `help` with one-line purpose.  
4. **MUST NOT** appear on the TTY numbered main menu (install/setup excluded).  
5. Dual mention: this file **and** `requirement-shell-cli-interface`. Domain catalog: `requirement-domain-grok-cli`.

### 2.2 Peer probe

6. Peer name **MUST** be `grok` (override `GROK_BIN` = absolute executable).  
7. Probe: `GROK_BIN` when set and executable, else `command -v grok`, else `$(GROK_HOME)/bin/grok`, else `${USER_BIN}/grok`. Disk search is required because the vendor installer writes PATH into `~/.bashrc`; that does not apply to the current session.  
8. Probe **MUST NOT** mean “grok-cli is installed.”

### 2.3 Idempotent skip

9. Probe success and **no** `--force` → exit 0, no network. Human success + JSON `status=already_installed`.  
10. `--force` → fetch even if probe succeeds.  
11. `--json` / off-TTY **MUST NOT** hang.

### 2.4 Fetch and run

12. Default URL **MUST** be `https://x.ai/cli/install.sh` (`GROK_VENDOR_INSTALL_URL` override for tests).  
13. **MUST** `curl -fsSL` that URL into a temp file under product storage, then run with **`bash`**.  
14. Curl non-zero or empty file → fail closed **before** exec.  
15. Missing `curl` or `bash` → fail closed.  
16. After a successful run, re-probe using rule 7 (PATH **and** well-known dirs). Binary present on disk → exit 0. If this session cannot `command -v grok`, that is expected: a PATH line in `~/.bashrc` does not apply until a new session. **MUST** say so as INFO (open a new terminal, then `grok login`). **MUST NOT** print `[ERROR]` for that stale-PATH case. **MUST NOT** tell the operator to add `${USER_BIN}` (`~/.local/bin`) when the vendor placed grok under `~/.grok/bin`. Binary absent on disk → fail closed (installer-output next step).  
17. **MUST NOT** copy `src/grok-cli` or write `grok-cli` as the peer binary.

### 2.5 Errors

Blocking copy **MUST** say what happened and **`Next:`**.

| Case | Next |
|------|------|
| No curl | install curl, then `grok-cli setup` |
| No bash | install bash, then `grok-cli setup` |
| Download failed | check network to x.ai, then `grok-cli setup` |
| Installer ran, `grok` missing on disk | check the installer output, then `grok-cli setup` |
| Installer ran, `grok` on disk, this session PATH stale | not an error: open a new terminal, then `grok login` |

JSON `message` **MUST** match the human sentence.

### 2.6 Invocation samples (dual mention)

```text
grok-cli setup
grok-cli setup --force
grok-cli setup --json
```

### 2.7 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Product | `grok-cli` |
| Verb | `setup` |
| Handler | `gc_setup` |
| Peer | `grok` (xAI Grok Build CLI) |
| Vendor URL | `https://x.ai/cli/install.sh` |
| Override | `GROK_VENDOR_INSTALL_URL`, `GROK_BIN` |
| Privilege | Type 0 |
| grok-cli install class | still **local-only** (no self channel) |
| Menu | setup excluded |
| Egress grant | WA-20260825-001 (`https://x.ai/cli/install.sh`) |

### 2.8 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Fail closed on missing curl/empty download; Core tests never need the public net.  
- **CIAO Principle 2 – Intentional**: Peer installer is a named verb, not grok-cli’s own `install`.  
- **CIAO Principle 10 – Least privilege**: Only the named HTTPS URL; no sudo for setup.  
- **CIAO Principle 16 – Interactive vs non-interactive**: No hang under `--json` / pipes.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Temp-file fetch; never pipe a failed curl.  
- **Intentional:** `setup` ≠ `install`.  
- **Anti-fragile:** Skip when `grok` exists; URL override for tests.  
- **Over-protect:** Menu still hides setup; local-only class unchanged.

---

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Make `setup` install grok-cli or set `SCRIPT_URL` for grok-cli.  
2. Add `self-update` / Type O empty-argv because setup curls x.ai.  
3. Require sudo for setup.  
4. Pipe empty/failed downloads into bash.  
5. Put setup on the TTY main menu.  
6. Require public network for Core tests.  
7. Print tokens.  
8. Freeze a session Unix login or `/home/<login>/…` in this file.  
9. Print `[ERROR]` when grok is on disk but this session has not yet read a PATH line from `~/.bashrc`.  
10. Tell the operator to add `~/.local/bin` to PATH when the vendor placed grok under `~/.grok/bin`.

**Violating this rule is a critical setup / install-class regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | `setup` is routed and listed in help |
| AC-2 | Already-present `grok` is exit 0 with no curl |
| AC-3 | `--force` fetches the vendor URL |
| AC-4 | Curl/bash/download failures are operator-readable and non-zero |
| AC-5 | Successful fake installer places `grok`, not grok-cli |
| AC-6 | TTY menu has no setup row |
| AC-7 | grok-cli remains local-only (`SCRIPT_URL` empty) |
| AC-8 | Vendor dir install with stale session PATH is exit 0, not `[ERROR]` |

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention / dispatch |
| `docs/requirements/requirement-domain-grok-cli.md` | Domain catalog |
| `docs/requirements/requirement-grok-auth-backup.md` | Session after `grok login` |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Menu excludes setup |
| `./src/grok-cli` | Implementation |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-25 | Active (1.0.0) | `setup` curls xAI grok installer |
| 2026-08-30 | Active (1.1.0) | Stale session PATH after vendor `.bashrc` update is INFO, not ERROR; probe `~/.grok/bin` |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-VCLI-01**–**09**, **11**, **12** | `tests/test_grok_setup.sh` | have |
| **TP-CLI-04** (help lists setup) | `tests/test_cli.sh` | have |
| **TP-CLI-13** (menu excludes setup) | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-08-30  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
