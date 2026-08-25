**file**: docs/requirements/requirement-domain-grok-cli.md  
**Status**: Active (Version 1.1.0)  
**Area**: domain  
**Key**: `requirement-domain-grok-cli`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **domain surface Single Source of Truth** for grok-cli: which **specialized CLI verbs** exist, what **help** and **about** must show, and how domain routing is labeled.

**Operational session / deposit / sync behavior** is **not** owned here — it is owned by **`requirement-grok-auth-backup`**.  
**Elevation and sudoers files** (emit / install / submit **workflow**) are owned by **`requirement-three-layer-privilege-model`**.  
**JSON sudoer file body** (grant = **`{{PRJ_NAME}}` only**, verb **`backup`**) is owned by **`requirement-sudoer-json-file`**.

This file is the sole Active **`requirement-domain-*`** (four pillars). It supersedes `requirement-domain-grok-cli`.

### 1.1 Human-facing

This file lists the grok-cli commands a login types after install: place the xAI `grok` program (`setup`), check that grok is signed in, push `~/.grok/auth.*` into `/var/grok-cli`, or copy those files back into `~/.grok` without sudo.

| You | Another role | Not this |
|-----|--------------|----------|
| Run `setup`, `check-session`, `backup`, `sync-auth`, and the sudoer generate/submit verbs | sudoer-adm approves the JSON grant so `sudo grok-cli backup` is passwordless | Folder tar.gz backup; writing `/etc` yourself; typing `restore` (retired — the program must say unknown); using `setup` to install grok-cli |

**Includes:** verb catalog, help rows, about fields, pointers to ops and privilege law.  
**Excludes:** JWT/token parsing rules, chown/chmod numbers, sudoers schema (peer files).

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/grok-cli` | ship unit | live behavior |
| `grok-cli help` | command | listed verbs |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Place grok | grok-cli curls xAI’s installer so `grok` is on PATH | `grok-cli setup` |
| Confirm login | grok-cli reads `~/.grok/auth.json` and fails closed if it is missing or expired | `grok-cli check-session` |
| Push shared auth | After a valid session, grok-cli copies `auth.*` into `/var/grok-cli` as root | `grok-cli backup` |
| Pull shared auth | A normal login copies from `/var/grok-cli` into `~/.grok` with no sudo | `grok-cli sync-auth` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Pillar A — Specialized CLI subcommands

| Command | Operands / flags | Handler prefix | Behavior summary | Behavior SSOT |
|---------|------------------|----------------|------------------|---------------|
| `setup` | `--force` | `gc_*` | Curl xAI grok installer; skip if `grok` already on PATH | **`requirement-grok-setup`** |
| `check-session` | none | `gc_*` | Confirm grok is logged in | **`requirement-grok-auth-backup`** |
| `backup` | none | `gc_*` | Check session, then elevated deposit of `auth.*` into `/var/grok-cli` | **`requirement-grok-auth-backup`** |
| `sync-auth` | none | `gc_*` | Copy `/var/grok-cli/auth.*` into `~/.grok` **without sudo** | **`requirement-grok-auth-backup`** |
| `print-sudoers` | optional output path; `--allow-test-local` when test_local | `gc_*` | Emit **project-sudoers-file** (draft; no `/etc` write) | **`requirement-three-layer-privilege-model`** |
| `print-sudoers-install-script` | optional script path; same trust gate | `gc_*` | Admin handoff script under `/dev/shm` or temp | **`requirement-three-layer-privilege-model`** |
| `remove-project-sudoers` | optional path; `--force` | `gc_*` | Remove **project-sudoers-file** draft only (not `/etc`) | **`requirement-three-layer-privilege-model`** |
| `generate-sudoer-request` | optional dest path; `--update` / `--add`; `--allow-test-local` | `gc_*` | Independent JSON grant (compact; **backup** only) to a dest readable without sudo | workflow: **`requirement-three-layer-privilege-model`** · JSON body: **`requirement-sudoer-json-file`** |
| `submit-sudoer-request` | optional sudoers file; `--purpose`; `--update` / `--add`; `--allow-test-local` | `gc_*` | Type 0 submitter into `/var/sudoer-cli/sudoer-request` | workflow: **`requirement-three-layer-privilege-model`** · JSON body: **`requirement-sudoer-json-file`** |

**Routing:** Dispatcher in `app_main` **MUST** route these verbs; unknown operands fail closed.  
**MUST NOT** route `restore` (retired folder-archive verb).

### 2.2 Pillar B — Specialized features (surface map only)

| Feature area | Domain role | Full law |
|--------------|-------------|----------|
| Peer grok install | Expose `setup` (vendor curl; not grok-cli install) | `requirement-grok-setup` |
| Grok session gate | Expose `check-session`; backup MUST call the same gate | `requirement-grok-auth-backup` |
| Auth deposit | Expose `backup` | `requirement-grok-auth-backup` |
| Unprivileged sync | Expose `sync-auth` | `requirement-grok-auth-backup` |
| Sudoers draft print | Expose `print-sudoers` | `requirement-three-layer-privilege-model` |
| Admin sudoers install script | Expose `print-sudoers-install-script` | `requirement-three-layer-privilege-model` |
| Remove project-sudoers draft | Expose `remove-project-sudoers` | `requirement-three-layer-privilege-model` |
| Generate sudoer file | Expose `generate-sudoer-request` | workflow + `requirement-sudoer-json-file` |
| Submit sudoers for approval | Expose `submit-sudoer-request` | workflow + `requirement-sudoer-json-file` |

**Filename grammar** (queued sudoer request — sibling allocator; informative):

```text
sudoer-{{YYYYMMDD}}-grok-cli-{{username}}-{{action}}-{{n}}.json
```

**Worked sample basename (add):** `sudoer-20260822-grok-cli-leolio-add-1.json`

**Complete sample JSON grant (add):**

```json
{
  "schema_version": 1,
  "purpose": "Allow leolio to run grok-cli backup as root.",
  "username": "leolio",
  "service": "grok-cli",
  "action": "add",
  "commands": [
    {
      "runas": "root",
      "tags": ["NOPASSWD"],
      "path": "/usr/local/bin/grok-cli",
      "args": ["backup"]
    }
  ]
}
```

**Complete sample JSON grant (update):** same `commands`; `"action": "update"`.

**Equivalent text dual:**

```text
leolio ALL=(root) NOPASSWD: /usr/local/bin/grok-cli backup
```

### 2.3 Pillar C — Specialized project help items

`help` **MUST** show domain rows (in addition to Type 0 lifecycle):

| Help row | Text intent |
|----------|-------------|
| `setup` | Install grok from x.ai (`curl` vendor installer); skip if already present |
| `check-session` | Confirm grok is logged in |
| `backup` | Check session, push `~/.grok/auth.*` to `/var/grok-cli` (passwordless `sudo grok-cli backup` after sudoer-adm) |
| `sync-auth` | Copy `/var/grok-cli/auth.*` into `~/.grok` with no sudo |
| `print-sudoers` | Emit project-sudoers-file (draft) for admin install |
| `print-sudoers-install-script` | Write admin script for sudo install/uninstall/replace |
| `remove-project-sudoers [path]` | Delete project-sudoers-file draft only |
| `generate-sudoer-request [path]` | Independently write a JSON grant (backup verb) |
| `submit-sudoer-request [file]` | Queue a JSON sudoers-grant request via sudoer-cli |
| Env note | `GROK_HOME`, `GROK_CLI_ROOT` |

Examples in help **MUST** include:

```text
grok-cli install
grok-cli setup
grok-cli check-session
grok-cli generate-sudoer-request
grok-cli submit-sudoer-request
grok-cli backup
grok-cli sync-auth
```

### 2.4 Pillar D — Specialized project about items

`about` **MUST** include domain diagnostics (in addition to Type 0):

| Field / line | Content |
|--------------|---------|
| Grok peer | path of `grok` or `not_found` (`setup` places it) |
| Grok home | effective grok auth directory |
| Session | `valid` / `invalid` / `missing` |
| Deposit directory | effective `GROK_CLI_ROOT` (default `/var/grok-cli`) |
| Sudo deposit status | best-effort probe; honest if not fully probeable |
| sudoer-cli | Detected path or `not_found` |
| sudoer-adm | Detected login or `absent` |
| sudoer inbound | Detected inbound dir or `not_found`; plus writable flag |
| Host sudoers fragment | `host_sudoers_present` / `host_sudoers_path` |

**About is not** a remote version-check and **must not** advertise online install channels.

### 2.5 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product / APP_NAME** | `grok-cli` |
| **Domain prefix** | `gc_` |
| **Ship unit** | `src/grok-cli` |
| **VERSION** | ship unit SSOT (`1.0.0`) |
| **Primary user install** | `~/.local/bin/grok-cli` |
| **Auth operations SSOT** | `requirement-grok-auth-backup` |
| **Privilege / sudoers SSOT** | `requirement-three-layer-privilege-model` (workflow) · `requirement-sudoer-json-file` (JSON grant body) |
| **Public inbound (sibling)** | `/var/sudoer-cli/sudoer-request` |
| **Worked queued basename** | `sudoer-20260822-grok-cli-leolio-add-1.json` |
| **Bootstrap** | Specialized from sibling **folder-backup**; chain cli-template → folder-backup → grok-cli |

### 2.6 Why This Requirement Exists (CIAO)

- **Principle 2 – Intentional**: Domain surface is explicit (four pillars) and not mixed with full ops law.  
- **Principle 5 – Output SSOT**: Help/about domain rows via product output system.  
- **Principle 9 – Three Types of Commands**: Domain labels user verbs that invoke a narrow elevated backup sub-step under peer REQs.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Do not invent a second auth-ops SSOT in domain.  
- **Intentional:** Pillars A–D only; ops in grok-auth-backup.  
- **Anti-fragile:** Clear ownership boundaries reduce drift.  
- **Over-protect:** Keep sole Active domain file; supersede before replace.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Duplicate full session/deposit/chmod/sync law here once `requirement-grok-auth-backup` is Active.  
2. Reintroduce folder tar.gz `restore` as a domain verb.  
3. Add online install of **grok-cli** or remote upload as silent domain behavior without new requirements. `setup` installing **peer `grok`** is owned by `requirement-grok-setup` — **MUST NOT** set grok-cli `SCRIPT_URL`.  
4. Put domain law into bootstrap origin folder-backup or cli-template.  
5. Create a second Active `requirement-domain-*` without superseding this one.  
6. Let Type 0 `mkdir` `/var/sudoer-cli/sudoer-request`.

**Violating this rule is a critical domain regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | `help` lists setup, check-session, backup, sync-auth and sudoer verbs |
| AC-2 | `about --json` reports grok_cli_root, deposit_dir, session |
| AC-3 | Dispatcher routes those verbs; `restore` is unknown |
| AC-4 | JSON grant sample in this file names backup only |
| AC-5 | Sole Active domain file |

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-grok-auth-backup.md` | Ops SSOT |
| `docs/requirements/requirement-grok-setup.md` | `setup` / peer grok installer |
| `docs/requirements/requirement-three-layer-privilege-model.md` | Privilege workflow |
| `docs/requirements/requirement-sudoer-json-file.md` | JSON grant body |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention of verbs |
| `./src/grok-cli` | Implementation |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-22 | Active (1.0.0) | Specialized from folder-backup domain; grok auth surface |
| 2026-08-25 | Active (1.1.0) | `setup` peer grok installer (xAI curl) |

---


## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-04**, **TP-CLI-06** | `tests/test_cli.sh` | have |
| **TP-VCLI-01**–**09** | `tests/test_grok_setup.sh` | have |
| **TP-GROK-CLI-01**, **01b**, **02**, **11**, **14**, **15**, **15b**, **19**–**25** | `tests/test_domain_grok_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-08-25  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
