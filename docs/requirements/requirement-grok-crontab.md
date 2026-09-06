**file**: docs/requirements/requirement-grok-crontab.md  
**Status**: Active (Version 1.1.0)  
**Area**: domain  
**Key**: `requirement-grok-crontab`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is grok-cli’s **cron-job** law (user-crontab ensure): the **operations Single Source of Truth** for **`add-crontab`**. It installs this login’s **user crontab** jobs that match the host’s studied grok-cli timer pattern — elevated `backup` on a half-hour tick, unprivileged `sync-auth` at minute 45. Portable cron-job rules (whose crontab, grant gate, no `/etc`, idempotent lines) are specialized here; this file fills grok-cli schedules and the `backup` grant.

The jobs **MUST** target the invoking login (`id -un`). They **MUST NOT** freeze one Unix login as the only operator. The backup job **MUST** fail closed unless this login’s installed sudoers fragment grants passwordless `grok-cli backup` (the same grant sudoer-adm approves). `add-crontab` itself **MUST NOT** call `sudo` and **MUST NOT** write `/etc`.

Auth copy semantics stay on `requirement-grok-auth-backup`. Sudoers JSON / install workflow stay on `requirement-sudoer-json-file` and `requirement-three-layer-privilege-model`. Help catalog stays on `requirement-domain-grok-cli`.

### 1.1 Human-facing

**In one sentence:** you type `grok-cli add-crontab` so **this** login’s crontab runs `backup` every 30 minutes and `sync-auth` at minute 45 — after sudoer-adm has approved your passwordless backup grant.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Install jobs into **your** crontab | `grok-cli add-crontab` |
| The other role | sudoer-adm already approved `NOPASSWD: … grok-cli backup` for **you** | `/etc/sudoers.d/grok-cli-<you>` |
| Not this file | Copying `auth.*`; writing `/etc`; root’s crontab | `grok-cli backup` · `grok-cli generate-sudoer-request` |

| Includes | Excludes |
|----------|----------|
| Per-login user crontab; studied schedules; grant check for **this** `id -un`; idempotent re-run | Hard-coding one Unix login; installing into another user’s crontab; `crontab` as root; changing sudoers |
| Fail closed when the fragment is missing or the Cmnd line is wrong | Treating a sibling login’s fragment as your grant |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/grok-cli` | ship unit | live `add-crontab` |
| `grok-cli help` | command | listed `add-crontab` row |
| this login’s crontab | `crontab -l` | the two jobs |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| After sudoer-adm approves backup | This login gets the same timers the host already uses | `grok-cli add-crontab` |
| Run it again | No duplicate lines | `grok-cli add-crontab` |
| Grant missing | Error names generate/submit, not a silent skip | `grok-cli generate-sudoer-request` then `grok-cli submit-sudoer-request` |

Jargon: this is ordinary-user crontab work, not a root host bootstrap.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Verb

1. **MUST** route **`add-crontab`** from `app_main`.  
2. **MUST** be Type 0 (invoking login). **MUST NOT** require `sudo` to read or write this login’s crontab. **MUST NOT** write `/etc` or root’s crontab.  
3. **MUST** appear in `help` with one-line purpose.  
4. **MUST** appear on the TTY numbered **main** menu (daily auth work — not install/setup, not the sudoers family).  
5. Dual mention: this file **and** `requirement-shell-cli-interface`. Domain catalog: `requirement-domain-grok-cli`. Menu body: `requirement-shell-cli-default-interaction`.

### 2.2 Who the jobs belong to

6. The crontab **MUST** be the invoking login’s user crontab (`crontab -l` / `crontab <file>` as this login).  
7. The Unix login **MUST** be resolved at runtime with `id -un` (product helper `gc_current_login_user`).  
8. **MUST NOT** hard-code a particular login (including any template account) as the crontab owner or as the sudoers username.  
9. **MUST NOT** install jobs for a different login than the invoking user.

### 2.3 Sudoers gate (backup job)

The backup cron line uses `sudo {{GLOBAL_BIN}}/grok-cli backup`. That only works when **this** login has the approved passwordless grant.

10. **MUST** probe **this** login’s installed fragment first: `{{SUDOERS_D_DIR}}/grok-cli-<id -un>` (then legacy `{{SUDOERS_D_DIR}}/grok-cli`). Other users’ `grok-cli-<other>` files **MUST NOT** count.  
11. When the fragment is **readable**, it **MUST** contain this exact Cmnd (studied dual of the JSON grant):

```text
<id -un> ALL=(root) NOPASSWD: <GLOBAL_BIN>/grok-cli backup
```

12. A readable fragment that exists but **lacks** that line (wrong user on the line, missing `NOPASSWD`, extra argv, different verb) **MUST** fail closed. **MUST NOT** fall through to a sibling login’s grant.  
13. When the fragment **exists** but is **unreadable** (typical `sudoers.d` mode), **MAY** corroborate with `sudo -n -l` listing `{{GLOBAL_BIN}}/grok-cli backup`. **MUST NOT** probe with `sudo true`, `sudo -n grok-cli backup`, or any OS tool.  
14. Missing fragment **MUST** fail closed even if some other sudo right exists.  
15. **MUST NOT** treat a draft under `~/.config/grok-cli/` as an installed grant.

### 2.4 Job lines (studied host pattern)

Default schedules **MUST** match the studied user-crontab pattern (overrides for tests only):

| Job | Default schedule (`GROK_CLI_CRON_*`) | Command |
|-----|--------------------------------------|---------|
| backup | `*/30 * * * *` (`GROK_CLI_CRON_BACKUP`) | `sudo {{GLOBAL_BIN}}/grok-cli backup` |
| sync-auth | `45 * * * *` (`GROK_CLI_CRON_SYNC`) | `{{GLOBAL_BIN}}/grok-cli sync-auth` |

16. Both commands **MUST** use the **global** managed path `{{GLOBAL_BIN}}/grok-cli` (default `/usr/local/bin/grok-cli`) because the sudoers grant is that path.  
17. **MUST** fail closed if that binary is missing or not executable.  
18. The sync-auth line **MUST NOT** use `sudo`.  
19. **MUST** use `crontab` (override `GROK_CLI_CRONTAB` for tests). Missing crontab command **MUST** fail closed.  
20. **MUST** preserve other crontab lines (comments and unrelated jobs).  
21. Re-run **MUST** be idempotent: if the backup command (`sudo {{GLOBAL_BIN}}/grok-cli backup`) is already present, do not add a second backup line; same for `{{GLOBAL_BIN}}/grok-cli sync-auth`. Success when both are already present.  
22. Off-TTY / `--json` **MUST NOT** hang or prompt.

### 2.5 Errors

Blocking copy **MUST** say what happened and **Next:**.

| Case | Next |
|------|------|
| No grant / wrong fragment content | `grok-cli generate-sudoer-request` then `grok-cli submit-sudoer-request`, then ask sudoer-adm to approve |
| Global binary missing | `sudo sh src/grok-cli install` (or `grok-cli install --global`) |
| crontab command missing | install cron, then `grok-cli add-crontab` |
| crontab install failed | check `crontab -l`, then `grok-cli add-crontab` |

JSON `message` **MUST** match the human sentence.

### 2.6 Invocation samples (dual mention)

```text
grok-cli add-crontab
grok-cli add-crontab --json
```

Worked crontab body (no Unix login on the lines — crontab is already per-login):

```text
*/30 * * * * sudo /usr/local/bin/grok-cli backup
45 * * * * /usr/local/bin/grok-cli sync-auth
```

### 2.7 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product / verb** | `grok-cli` / `add-crontab` |
| **Handler** | `gc_add_crontab` |
| **Privilege** | Type 0 (this login’s crontab) |
| **Login SSOT** | `id -un` via `gc_current_login_user` |
| **Fragment dest** | `/etc/sudoers.d/grok-cli-<id -un>` (`SUDOERS_D_DIR` override for tests) |
| **Studied Cmnd** | `<id -un> ALL=(root) NOPASSWD: /usr/local/bin/grok-cli backup` |
| **Binary in jobs** | `GLOBAL_BIN` default `/usr/local/bin` |
| **crontab binary** | `GROK_CLI_CRONTAB` default `crontab` (tests inject a fake) |
| **Schedules** | backup `*/30 * * * *`; sync-auth `45 * * * *` |
| **Menu** | main list row **4**; family `sudoers` moves to **5**; Exit **9** |
| **Portable pattern** | cron-job (user-crontab ensure; typical verb `add-crontab`) |
| **Proof family** | **TP-CRON-01..06** mapped to **TP-GROK-CLI-26..29** |
| **Not** | root crontab; `/etc/cron.d`; hard-coded template login |

### 2.8 Why This Requirement Exists (CIAO)

- **Principle 2 – Intentional**: The host already uses two grok-cli timer lines; the product owns installing the same pattern per login.  
- **Principle 9 – Three Types of Commands**: crontab write is Type 0; the backup job later uses the approved Type 1 grant.  
- **Principle 10 – Least privilege**: no extra sudoers tools; no other user’s fragment.  
- **Principle 21 – Dual policies**: core rules use `id -un` / `GLOBAL_BIN`; Implementation Notes fill product defaults without freezing a session login.

---

## Under command line for normal user only

When grok-cli runs on Termux, Git Bash, Windows cmd, or the same class (this login only — no root, no dedicated system account):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** only | Enable **admin privilege** (`sudo`, write `/etc`) or a **dedicated system user** |
| Treat admin-privilege and dedicated-account work as **unused** | Wrap `apt` / `dnf` / `yum`; `useradd`; recommend `sudo curl \| sh` |
| Termux: `pkg` as this login stays ordinary-user work | Recommend `sudo curl \| sh` as the install path |
| Git Bash and Windows cmd: same ceiling | Invoke Termux `pkg` because those hosts were detected |

Detect: Termux — `uname` contains Android, or `PREFIX` / `TERMUX_VERSION` is set. Git Bash — `MSYSTEM` or `uname -s` is MINGW*/MSYS*. Windows cmd — `OS=Windows_NT` after excluding Git Bash, Cygwin, and WSL.

**This requirement:** `add-crontab` stays **unused** on this class (it needs a backup grant). Do not write `/etc`.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail closed without **this** login’s backup grant; never install into someone else’s crontab.  
- **Intentional:** Two studied lines only; sync-auth stays unprivileged.  
- **Anti-fragile:** Idempotent; preserves other jobs; tests isolate crontab via `GROK_CLI_CRONTAB`.  
- **Over-protect:** Wrong-user and wrong-argv fragments are refusals, not a skip.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Hard-code a Unix login (including a template account) as the crontab owner or sudoers username.  
2. Treat another login’s `/etc/sudoers.d/grok-cli-<other>` as this login’s grant.  
3. Write `/etc`, root’s crontab, or `/etc/cron.d` from `add-crontab`.  
4. Put `sudo` on the `sync-auth` job, or omit `sudo` on the `backup` job.  
5. Use `~/.local/bin/grok-cli` in the jobs (sudoers grants the global path).  
6. Probe the grant by running `sudo grok-cli backup` or `sudo true`.  
7. Duplicate job lines on re-run.  
8. Hang off-TTY / `--json`.  
9. Drop `add-crontab` from the main numbered list once it is live.

10. Strip the **Under command line for normal user only** section, or enable admin privilege / a dedicated system user on Termux / Git Bash / Windows cmd.  

**Violating this rule is a critical crontab / multi-user regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | `add-crontab` is routed, listed in help, and on the TTY main menu |
| AC-2 | Jobs match the studied schedules and global-binary commands |
| AC-3 | Fail closed without **this** login’s correct `NOPASSWD` backup grant |
| AC-4 | A wrong-user or wrong-argv fragment does not count |
| AC-5 | Re-run does not duplicate; other crontab lines are kept |
| AC-6 | No hardcoded Unix login in jobs or in product law |

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-domain-grok-cli.md` | Domain surface catalog |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention / routing |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Main menu row |
| `docs/requirements/requirement-grok-auth-backup.md` | What backup / sync-auth do |
| `docs/requirements/requirement-sudoer-json-file.md` | Grant body (backup only) |
| `docs/requirements/requirement-three-layer-privilege-model.md` | Fragment dest / trust |
| `docs/requirements/requirement-operator-readable-error.md` | Fatal wording |
| `./src/grok-cli` | Implementation |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-09-02 | Active (1.0.0) | Per-login crontab jobs matching studied backup / sync-auth timers |
| 2026-09-02 | Active (1.1.0) | Named as this product’s **cron-job** law; TP-CRON maps to TP-GROK-CLI-26..29 |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-GROK-CLI-26**, **26b**, **27**, **28**, **28b**, **29**, **29b** | `tests/test_domain_grok_cli.sh` | have |
| **TP-CLI-04** (help lists `add-crontab`) | `tests/test_cli.sh` | have |
| **TP-CLI-13** (main menu row 4 `add-crontab`) | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-06  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
