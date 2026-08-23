**file**: docs/requirements/requirement-domain-folder-backup.md  
**Status**: superseded (2026-08-22 — replaced by `requirement-domain-grok-cli`)  
**Area**: domain  
**Key**: `requirement-domain-folder-backup`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **domain surface Single Source of Truth** for folder-backup: which **specialized CLI verbs** exist, what **help** and **about** must show, and how domain routing is labeled.

**Operational backup behavior** (create, name, deposit, verify, fail-closed matrix) is **not** owned here — it is owned by **`requirement-folder-archive-backup`**.  
**Elevation and sudoers files** (emit / install / submit **workflow**) are owned by **`requirement-three-layer-privilege-model`**.  
**JSON sudoer file body** (grant = **`{{PRJ_NAME}}` only**) is owned by **`requirement-sudoer-json-file`**.

This file remains the sole Active **`requirement-domain-*`** (four pillars).

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Pillar A — Specialized CLI subcommands

| Command | Operands / flags | Handler prefix | Behavior summary | Behavior SSOT |
|---------|------------------|----------------|------------------|---------------|
| `backup` | `<source-folder>` required | `fb_*` | Folder archive backup end-to-end | **`requirement-folder-archive-backup`** |
| `restore` | `<archive\|prefix> [dest]`; flags `--force` `--disk` `--ram` | `fb_*` | Restore archive (default dest: hard-disk host) | **`requirement-folder-archive-backup`** |
| `print-sudoers` | optional output path; `--allow-test-local` when test_local | `fb_*` | Emit **project-sudoers-file** (draft; no `/etc` write) | **`requirement-three-layer-privilege-model`** |
| `print-sudoers-install-script` | optional script path; same trust gate | `fb_*` | Admin handoff script under `/dev/shm` or temp (`install`/`uninstall`/`replace`/`status`) | **`requirement-three-layer-privilege-model`** §2.3.3a |
| `remove-project-sudoers` | optional path; `--force` | `fb_*` | Remove **project-sudoers-file** draft only (not `/etc`) | **`requirement-three-layer-privilege-model`** §2.3.3b |
| `generate-sudoer-request` | optional dest path; `--update` / `--add`; `--allow-test-local` | `fb_*` | Type 0 **independent** generate: write JSON grant to a dest **readable without sudo** (tests/review); compact; both verbs; no `/etc`; no inbound | workflow: **`requirement-three-layer-privilege-model`** §2.3.2a · §2.3.3d · JSON body: **`requirement-sudoer-json-file`** |
| `submit-sudoer-request` | optional sudoers file; `--purpose`; `--update` / `--add`; `--allow-test-local` | `fb_*` | Type 0 submitter: detect sudoer-cli + sudoer-adm + **public inbound**; **default action=update** if this user’s `/etc/sudoers.d/{{APP_NAME}}-<user>` exists, else add; sibling allocates JSON (no `/etc` write; no inbound `mkdir`) | workflow: **`requirement-three-layer-privilege-model`** §2.3.3c · JSON body: **`requirement-sudoer-json-file`** |

**Routing:** Dispatcher in `app_main` (CLI interface) **MUST** route these verbs; unknown operands fail closed.

**Non-goals as subcommands:** remote sync, cloud upload, restore UI, schedule daemon (unless a future requirement adds them).

### 2.2 Pillar B — Specialized features (surface map only)

| Feature area | Domain role | Full law |
|--------------|-------------|----------|
| Folder archive backup | Expose `backup` verb | `requirement-folder-archive-backup` |
| Elevated deposit / verify elev | Product uses Type 1 sub-steps | `requirement-three-layer-privilege-model` + backup REQ |
| Sudoers draft print | Expose `print-sudoers` | `requirement-three-layer-privilege-model` |
| Admin sudoers install script | Expose `print-sudoers-install-script` | `requirement-three-layer-privilege-model` §2.3.3a · term `project-sudoers-file` |
| Remove project-sudoers draft | Expose `remove-project-sudoers` | `requirement-three-layer-privilege-model` §2.3.3b |
| Generate sudoer file | Expose `generate-sudoer-request` — **independent** JSON grant to a dest tests/review can read without sudo | workflow: `requirement-three-layer-privilege-model` §2.3.2a · §2.3.3d · body: `requirement-sudoer-json-file` |
| Submit sudoers for approval | Expose `submit-sudoer-request` — JSON request into sibling public inbound | workflow: `requirement-three-layer-privilege-model` §2.3.3c · body: `requirement-sudoer-json-file` |

Domain **MUST NOT** restate full operational backup rules in a second competing SSOT. Pointers and verb catalog only.

### 2.3 Pillar C — Specialized project help items

`help` **MUST** show domain rows (in addition to Type 0 lifecycle):

| Help row | Text intent |
|----------|-------------|
| `backup <source-folder>` | Create tar.gz, deposit under backup notation, verify counts |
| `restore <archive\|prefix> [dest]` | Restore archive; default dest **hard-disk** host (reverse ram-drive-first) |
| `print-sudoers` | Emit **project-sudoers-file** (draft) for admin install |
| `print-sudoers-install-script` | Write admin script (`/dev/shm` or temp) for sudo install/uninstall/replace of project-sudoers-file |
| `remove-project-sudoers [path]` | Delete project-sudoers-file draft only (list/choose if multiple; confirm / `--force`; not `/etc`) |
| `generate-sudoer-request [path]` | Independently write a JSON grant to a dest tests and review can read (compact; both verbs); no `/etc`; no inbound |
| `submit-sudoer-request [file]` | Queue a JSON sudoers-grant request via sudoer-cli into `/var/sudoer-cli/sudoer-request` (default **update** if this user’s host fragment exists; `--add`/`--update`; no `/etc` write; no inbound mkdir) |
| Env note | `BACKUP_*`, `PROJECTS_ROOT`, `RAM_ROOT`, `RESTORE_HOST_DEFAULT` |
| Privilege note | Archive as user; deposit/restore-stage need allowlisted sudo after admin installs fragment |

Examples in help **SHOULD** include:

```text
folder-backup install
folder-backup print-sudoers-install-script
# admin (sudo): sudo sh /dev/shm/folder-backup-<user>-sudoers-admin.sh install
# leave test elev: sudo sh …/…-sudoers-admin.sh uninstall
folder-backup backup /path/to/project
folder-backup generate-sudoer-request
folder-backup submit-sudoer-request ~/.config/folder-backup/sudoer-request-<user>.json
folder-backup submit-sudoer-request
# sibling writes: /var/sudoer-cli/sudoer-request/sudoer-YYYYMMDD-folder-backup-<user>-add-N.json
```

### 2.4 Pillar D — Specialized project about items

`about` **MUST** include domain diagnostics (in addition to Type 0):

| Field / line | Content |
|--------------|---------|
| Backup root | effective `BACKUP_ROOT` |
| Backup notation | effective `BACKUP_NOTATION` |
| Deposit directory | `${BACKUP_ROOT}/${BACKUP_NOTATION}` |
| Sudo deposit status | best-effort probe; honest if not fully probeable |
| sudoer-cli | Detected path or `not_found` |
| sudoer-adm | Detected login or `absent` |
| sudoer inbound | Detected inbound dir or `not_found`; plus writable flag. Preferred: `/var/sudoer-cli/sudoer-request` |
| Host sudoers fragment | `host_sudoers_present` / `host_sudoers_path` — this user’s `/etc/sudoers.d/{{APP_NAME}}-<user>` (or legacy); drives submit default add vs update |
| Domain version note | Product `VERSION` remains Type 0 local version SSOT |

**About is not** a remote version-check and **must not** advertise online install channels.

### 2.5 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product / APP_NAME** | `folder-backup` |
| **Domain prefix** | `fb_` |
| **Ship unit** | `src/folder-backup` |
| **VERSION** | ship unit SSOT (see `src/folder-backup`) |
| **Primary user install** | `~/.local/bin/folder-backup` |
| **Backup operations SSOT** | `requirement-folder-archive-backup` |
| **Privilege / sudoers SSOT** | `requirement-three-layer-privilege-model` (workflow) · `requirement-sudoer-json-file` (JSON grant body) |
| **Submit verb** | `submit-sudoer-request` → `fb_submit_sudoer_request` |
| **Generate verb** | `generate-sudoer-request` → `fb_generate_sudoer_request` |
| **Public inbound (sibling)** | `/var/sudoer-cli/sudoer-request` (3773) |
| **Worked queued basename** | `sudoer-20260815-folder-backup-leolio-add-1.json` |
| **Bootstrap** | Specialized from **cli-template** Type 0 architecture; online install already absent on A |

### 2.6 Why This Requirement Exists (CIAO)

- **Principle 2 – Intentional**: Domain surface is explicit (four pillars) and not mixed with full ops law.  
- **Principle 5 – Output SSOT**: Help/about domain rows via product output system.  
- **Principle 9 – Three Types of Commands**: Domain labels Type 0 verbs that invoke Type 1 sub-steps under peer REQs.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Do not invent a second backup SSOT in domain.  
- **Intentional:** Pillars A–D only; ops in backup requirement.  
- **Anti-fragile:** Clear ownership boundaries reduce drift.  
- **Over-protect:** Keep sole Active domain file; supersede before replace.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Duplicate full create/name/deposit/verify law here once `requirement-folder-archive-backup` is Active.  
2. Add online install or remote upload as silent domain behavior without new requirements.  
3. Put domain law into bootstrap parent `cli-template`.  
4. Leave help listing `backup` without an Active operational backup requirement.  
5. Create a second Active `requirement-domain-*` without superseding this one.  
6. Document inbound as `sudoer-approving` (home dropbox) as the preferred dest.  
7. Let Type 0 `mkdir` `/var/sudoer-cli/sudoer-request`.

**Violating this rule is a critical domain regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Four pillars present (subcommands, feature map, help, about) |
| AC-2 | `backup`, `print-sudoers`, `print-sudoers-install-script`, `remove-project-sudoers`, `generate-sudoer-request`, and `submit-sudoer-request` listed with peer SSOT pointers |
| AC-3 | Help lists backup + print-sudoers + install-script + remove-project-sudoers + generate-sudoer-request + submit-sudoer-request |
| AC-4 | About lists backup root / notation / deposit dir + sudoer-cli / sudoer-adm / inbound (preferred public path) + `host_sudoers_present` |
| AC-5 | Registered as sole Active domain SSOT |
| AC-6 | No competing full backup ops body (defers to folder-archive-backup) |
| AC-7 | Help/about describe submit as JSON into sibling public inbound, not a home `sudoer-approving` mkdir |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-folder-archive-backup` | **Operational backup SSOT** |
| `requirement-three-layer-privilege-model` | Elevation + sudoers workflow |
| `requirement-sudoer-json-file` | JSON sudoer file body (`{{PRJ_NAME}}` only) |
| `requirement-shell-cli-interface` | Routes domain verbs |
| `requirement-bootstrap-chain` | Domain extend from cli-template |
| `docs/requirements/index.md` | Registry |

---

## Design-time verification

| TP family / ID | Suite | Status | Note |
|----------------|-------|--------|------|
| **TP-FOLDER-BACKUP-01,02** | `tests/test_domain_folder_backup.sh` | have | print-sudoers surface (privilege peer) |
| **TP-FOLDER-BACKUP-09** | same | have | about domain fields |
| **TP-CLI-04,06** | `tests/test_cli.sh` | have | help/about list domain verbs |
| **TP-FOLDER-BACKUP-19,20** | `tests/test_domain_folder_backup.sh` | have | submit fail-closed / stub inbound (privilege peer) |
| **TP-FOLDER-BACKUP-23,23b** | same | have | host `/etc/sudoers.d` probe → update; `--add` override |
| **TP-FOLDER-BACKUP-24,24b,24c,24d** | same | have | generate-sudoer-request independent dest; suite reads without sudo |
| **TP-FOLDER-BACKUP-21** | same | have | public inbound preferred over leftover `sudoer-approving`; no Type 0 mkdir |
| **TP-FOLDER-BACKUP-21b** | same | have | env inbound override wins over public |
| **TP-FOLDER-BACKUP-22,22b,22c** | same | **have** | JSON sudoer file body — primary: `requirement-sudoer-json-file` |
| **TP-FOLDER-BACKUP-03..08,10** | `tests/test_domain_folder_backup.sh` | have | **Primary map:** `requirement-folder-archive-backup` |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active 1.0.0 | Domain SSOT: folder tar.gz backup + sudoers deposit |
| 2026-08-03 | Active 1.1.0 | Verification rules (later moved to backup ops REQ) |
| 2026-08-03 | Active 1.2.0 | **Thin domain surface**; ops SSOT → `requirement-folder-archive-backup` |
| 2026-08-13 | Active 1.2.0 | Origin notes retarget: specialize from **cli-template** (not selfmanaged) |
| 2026-08-14 | Active 1.3.0 | `submit-sudoer-request` surface |
| 2026-08-15 | Active 1.4.0 | Submit = JSON into `/var/sudoer-cli/sudoer-request`; no inbound mkdir |
| 2026-08-15 | Active 1.4.1 | JSON sudoer file body → `requirement-sudoer-json-file` |
| 2026-08-17 | Active 1.5.0 | Submit default update when this user’s host fragment exists; `--add`/`--update` |
| 2026-08-17 | Active 1.6.0 | `generate-sudoer-request` surface (local verified JSON) |
| 2026-08-17 | Active 1.6.1 | Generate is independent; dest readable for tests/review (three-layer §2.3.2a) |

---

**Last Updated**: 2026-08-17  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
