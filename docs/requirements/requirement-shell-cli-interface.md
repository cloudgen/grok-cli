**file**: docs/requirements/requirement-shell-cli-interface.md  
**Status**: Active (Version 2.3.0)  
**Area**: shell  
**Key**: `requirement-shell-cli-interface`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for the **POSIX shell CLI interface** of grok-cli: command surface, privilege typing, global flags, dispatcher behavior, help/about contracts, and mode rules.

It defines a **Type 0–centric local self-managed shell CLI** plus **domain grok-auth** commands, **`setup`** (peer `grok` via xAI installer), and a **narrow elevated deposit** path. Full domain semantics live in `requirement-domain-grok-cli.md`. Full elevation/sudoers rules live in `requirement-three-layer-privilege-model.md`. Auth ops live in `requirement-grok-auth-backup.md`. Peer grok install lives in `requirement-grok-setup.md`.

---

### 1.1 Human-facing

This file lists the grok-cli commands you can type after install — names the program actually runs, not names that only appear in a plan.

| You | Another role | Not this |
|-----|--------------|----------|
| Type `grok-cli help` to see live commands | Domain law owns backup/sync meaning | Online `self-update`; typing a name that was never wired |

**Includes:** dispatch table, flags. **Excludes:** auth.json parse rules.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Start at a prompt | Numbered list on a real terminal; help in a script | `grok-cli` |


## 2. Core Rules / Requirements (Mandatory)

### 2.1 Command surface (portable shape)

Every command **MUST** map to exactly one privilege type. Unclassified commands are incomplete design.

| Category | Privilege | Meaning |
|----------|-----------|---------|
| **Type 0 – CLI lifecycle + diagnostics** | Invoking user | `install`, `uninstall`, `where-is-me`, `version`, `about`, `help`, `menu` (`main` alias) |
| **Type 0 – Domain (user work)** | Invoking user | `setup` (peer grok installer), session/sync, sudoers fragment **print** |
| **Type 1 – Narrow elevated deposit** | Controlled sudo (allowlisted only) | Copy staged archive into `/var/backup/...` only |
| **Type 2 – Dedicated system user app ops** | Dedicated app user | **Not in scope** for this product |

### 2.2 Global flags (portable)

| Flag | Env / state | Behavior |
|------|-------------|----------|
| `--quiet`, `-q` | `QUIET=1` | Suppress non-error human output; errors still visible |
| `--json` | `JSON=1` (implies quiet) | Machine-readable structured output |
| `--debug` | `DEBUG=1` | Extra diagnostics on stderr; must not break JSON purity on stdout |
| `--force` | `FORCE=1` / force policy | Skip safe confirms or force reinstall only where documented |

Additional flags **MAY** be added only when documented here (or a superseding requirement) and wired in the dispatcher.

### 2.3 Dispatcher and entry rules

1. **Single entry:** `app_main` **MUST** parse global flags and route commands.  
2. **Unknown command:** **MUST** fail loudly with pointer to `help` (via output SSOT).  
3. **Empty argv:** **Type N** (`requirement-shell-cli-zero-arguments.md`): TTY → numbered start list (same handler as `menu` / `main`); off-TTY → help. **MUST NOT** install. Flags-only (`--json` with no command) stay help.  
4. **No raw user I/O:** User-facing messages **MUST** go through `out_*`.  
5. Script end **MUST** call `app_main "$@"` (no basename gate that blocks dispatch).

### 2.4 Help surface

`help` **MUST** list:

- Usage line  
- Every supported command with one-line purpose  
- Privilege category (Type 0 vs elevated deposit)  
- Global flags  
- Honest note that deposit requires admin-installed sudoers fragment  

In JSON mode, help **MUST NOT** dump long human text; return a short structured success/note object.

### 2.5 Implementation Notes (this project)

| Item | Value for grok-cli |
|------|-------------------------|
| **Product / binary name** | `grok-cli` (`APP_NAME`) |
| **Primary executable** | `src/grok-cli` (POSIX `/bin/sh`, single-file ship unit) |
| **Dispatcher** | `app_main` |
| **Output SSOT** | `out_text` + wrappers (`out_info`, `out_success`, `out_warn`, `out_error`, `out_die`, `out_plain`, `out_json`, …) |
| **Version SSOT** | ship unit `VERSION=` in `src/grok-cli` (do not pin a stale number here) |
| **Install paths** | Global: `GLOBAL_BIN` default `/usr/local/bin`; User: `USER_BIN` default `${HOME}/.local/bin` |
| **Primary install story** | User bin: `~/.local/bin/grok-cli` |
| **Online channel env** | **Not product UX** (absent; inherited from cli-template) |
| **Type 2 commands** | None |
| **Dedicated system user** | Not required |

#### Supported commands (normative for this project)

| Command | Type | Handler family | Required behavior |
|---------|------|----------------|-------------------|
| *(no args — empty argv)* | Type 0 | `app_main` → `app_default` | **Type N**: TTY numbered menu; off-TTY help; **MUST NOT** install |
| `install` | Type 0 | `inst_local_install` | Copy running ship unit to privilege-correct bin; idempotent unless `--force` |
| `uninstall` | Type 0 | `inst_local_uninstall` | Remove managed binary; confirm unless `--force` |
| `where-is-me` | Type 0 | `app_where_is_me` | Running + install paths + installed flag |
| `version` | Type 0 | `app_version` | Local `VERSION` only; no network |
| `about` | Type 0 | `app_about` | Diagnostics: install presence, paths, user, shell, TTY, storage, grok home, session, deposit dir; **no** channel one-liner |
| `help` | Type 0 | `app_help` | Full usage in human mode; short JSON note in JSON mode |
| `menu` | Type 0 | `app_default` | Numbered list (`requirement-shell-cli-default-interaction`). Interactive: **ignore `--json`**. Non-interactive: help, following `--json`. |
| `main` | Type 0 | `app_default` (alias) | Same as `menu` |
| `setup` | Type 0 | `gc_setup` (domain) | Fetch xAI grok installer and run it so peer `grok` is installed; skip if already present unless `--force`. Stale session PATH is not an error. **MUST NOT** install grok-cli |
| `check-session` | Type 0 | `gc_check_session` (domain) | Confirm grok is logged in |
| `backup` | Type 0 (+ Type 1 deposit step) | `gc_backup` (domain) | Session gate; elevated copy of `~/.grok/auth.*` into `/var/grok-cli` |
| `sync-auth` | Type 0 | `gc_sync_auth` (domain) | Copy `/var/grok-cli/auth.*` into `~/.grok` without sudo |
| `print-sudoers` | Type 0 | `gc_print_sudoers` (domain) | Emit sudoers fragment for admin to install under `/etc/sudoers.d/` — **does not** write `/etc` itself |
| `print-sudoers-install-script` | Type 0 | `gc_print_sudoers_install_script` (domain) | Write admin handoff script (no `/etc` write) |
| `remove-project-sudoers` | Type 0 | `gc_remove_project_sudoers` (domain) | Delete draft only; never `/etc` |
| `generate-sudoer-request` | Type 0 | `gc_generate_sudoer_request` (domain) | **Independent** generate: write JSON grant to a dest tests/review can read without sudo (compact; backup verb; sibling convert when present) — **does not** write `/etc` or inbound |
| `submit-sudoer-request` | Type 0 | `gc_submit_sudoer_request` (domain) | Detect sudoer-cli + sudoer-adm + public inbound; **update** if this user’s `/etc/sudoers.d` fragment exists else **add**; `--add`/`--update` override — **does not** write `/etc` or `mkdir` inbound |

#### Global flags (normative wiring)

| Flag | Required wiring |
|------|-----------------|
| `--quiet`, `-q` | `QUIET=1` in `app_main` |
| `--json` | `JSON=1` and `QUIET=1` in `app_main` |
| `--debug` | `DEBUG=1` in `app_main` |
| `--force` | `FORCE=1` (and install reinstall policy when applicable) |
| `--update` | `SUBMIT_ACTION=update` + explicit (submit only) |
| `--add` | `SUBMIT_ACTION=add` + explicit (submit only) |

#### Dispatcher acceptance criteria

1. Unknown token after flag parse → `out_die` with pointer to `grok-cli help`.  
2. Zero-arg → Type N: TTY numbered menu; off-TTY help (never install, never `setup`).  
3. Command routing table in `app_main` **must** include every **Supported commands** row above.  
4. Help text **must** stay aligned with that table.  
5. Domain catalog detail is owned by `requirement-domain-grok-cli.md` — this file owns the **listed verbs** and routing. Auth ops detail is `requirement-grok-auth-backup.md`. Peer grok install is `requirement-grok-setup.md`.

#### Explicitly out of scope

- Online: `version-check`, `self-update`, `self-uninstall`, channel `install` via URL  
- Type 1 host bootstrap beyond **narrow deposit** and **sudoers fragment generation**  
- Creating the sibling inbound (`sudo sudoer-cli setup` is not this CLI)  
- Type 2 app runtime under a dedicated system user  

### 2.6 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution**: Unknown commands fail loud; force gates destructive ops.  
- **CIAO Principle 2 – Intentional**: Every command has one privilege type and one handler family.  
- **CIAO Principle 5 – Single Source of Output**: Central `out_*`.  
- **CIAO Principle 6 – Single Point of Entry**: `app_main` is the dispatcher SSOT.  
- **CIAO Principle 9 – Three Types of Commands**: Type 0 lifecycle/domain; Type 1 narrow deposit only.  
- **CIAO Principle 10 – Least-Privilege User**: No invented system-user requirement for binary lifecycle.  
- **CIAO Principle 16 – Interactive vs Non-Interactive**: No hang in non-interactive mode.  
- **CIAO Principle 4 / 20 – Over-protect**: Protection Rule blocks privilege and UX regressions.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail loud on bad input; never silent wrong privilege context.  
- **Intentional:** Command table + help + dispatcher stay synchronized.  
- **Anti-fragile:** Works under TTY, quiet, JSON, offline local install.  
- **Over-protect:** Do not collapse Type 0/1, reintroduce online verbs, or raw output for user messages.  
- **SSOT:** `APP_NAME` / `VERSION` / flags at config defaults; output via `out_*`; dispatch via `app_main`.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Add online lifecycle commands without an explicit product-mode change and registry update.  
2. Change empty argv to install-ensure while install mode remains local-only, or hang off-TTY empty argv on the numbered menu.  
3. List commands in help that are not routed (or route commands not listed).  
4. Bypass `out_*` for product user messages.  
5. Run the entire CLI as root by default instead of narrow deposit elevation.  
6. Put full domain archive semantics only here and omit the domain SSOT.  
7. Add a second submit verb (`submit-sudoer`) without routing + help, or invent inbound `mkdir` as this CLI’s job.

**Violating this rule is a critical CLI interface regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | All commands in the table are routed and listed in help |
| AC-2 | Global flags wire QUIET/JSON/DEBUG/FORCE as specified |
| AC-3 | Empty argv is Type N: TTY numbered menu; off-TTY help; never install |
| AC-4 | No online self-management verbs on the surface |
| AC-5 | Domain verbs point to domain requirement for deep semantics |
| AC-6 | `submit-sudoer-request` is Type 0, routed, listed in help; does not write `/etc` or create inbound |
| AC-7 | `generate-sudoer-request` is Type 0, routed, listed in help; independent of submit; dest is invoking-user readable; does not write `/etc` or inbound |
| AC-8 | `menu` / `main` routed; match `requirement-shell-cli-default-interaction` |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-cli-zero-arguments` | Empty argv Type N (TTY menu; off-TTY help) |
| `requirement-shell-cli-default-interaction` | Numbered list body; TTY empty argv and `menu`/`main` |
| `requirement-shell-local-self-management` | install/uninstall/where-is-me |
| `requirement-shell-output-requirements` | `out_*` catalog |
| `requirement-domain-grok-cli` | Domain four pillars |
| `requirement-grok-setup` | Dual mention of `setup` |
| `requirement-three-layer-privilege-model` | Elevation model |
| `docs/requirements/index.md` | Registry |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-01..13** | `tests/test_cli.sh` | have |
| **TP-VCLI-01..09**, **11**, **12** | `tests/test_grok_setup.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active 1.0.0 | CLI surface for local-only folder-backup + domain backup |
| 2026-08-15 | Active 1.1.0 | `submit-sudoer-request` listed as Type 0 JSON submit into sibling public inbound |
| 2026-08-17 | Active 1.2.0 | `--add` / `--update`; default submit action from host `/etc/sudoers.d` probe |
| 2026-08-17 | Active 1.3.0 | `generate-sudoer-request` Type 0; AC-7 |
| 2026-08-17 | Active 1.3.1 | Generate dest must be readable for tests/review; independent of submit |
| 2026-08-23 | Active 2.1.0 | Intended Gap `menu`/`main`; empty argv stays Type N help (not the numbered list) |
| 2026-08-23 | Active 2.2.0 | `menu`/`main` routed to `app_default`; TTY empty argv numbered list |
| 2026-08-25 | Active 2.3.0 | `setup` Type 0 — curl xAI grok installer (peer CLI; not grok-cli install) |

---

**Last Updated**: 2026-08-25  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
