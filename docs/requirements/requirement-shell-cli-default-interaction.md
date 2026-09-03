**file**: docs/requirements/requirement-shell-cli-default-interaction.md  
**Status**: Active (Version 2.3.0)  
**Area**: shell  
**Key**: `requirement-shell-cli-default-interaction`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **product Single Source of Truth** for grok-cli’s **default interaction**: a **short numbered main menu** of daily **auth work**, with sudoers grant/draft commands behind one **family** row. grok-cli has `requirement-shell-cli-zero-arguments` (**case 3**): that REQ **defers TTY empty argv** to this menu and **owns off-TTY empty argv as Type O ensure**. The menu **MUST** also be the command **`menu`**. **`main` MAY** be accepted as the same handler.

On a **real terminal**, empty argv and `grok-cli menu` (or `main`) **MUST** show the main menu. `menu`/`main` **MUST ignore `--json`**. Off-TTY, **`menu`/`main` MUST** print **help**, following `--json`. Off-TTY **empty argv** is **not** this file — it is channel ensure. Command rows **MUST** be `command: what it does`. The family row **MUST NOT** be a live dispatcher command.

Empty-argv type and the TTY vs off-TTY split for **no command token** stay on `requirement-shell-cli-zero-arguments`. Confirm / no-hang stays on `requirement-shell-interactive-vs-noninteractive`. Live command inventory stays dispatcher truth (`requirement-shell-cli-interface`).

### 1.1 Human-facing

Typing only `grok-cli` at a real terminal shows the numbered start list. In a script, bare `grok-cli` installs or reports already installed (not this menu). `grok-cli menu` (or `grok-cli main`) still opens the list on a TTY and prints help in a script. The list header is **grok-cli**(*version*) — **Alternative online installer for xAI grok** and the next line is **logged in** or **logged out**. Numbered rows are backup, sync-auth, sync-auth-from-remote, add-crontab, then **sudoers**. On a real terminal the “what it does” text after the colon is gray and italic (default CLI main menu style). `check-session` is not a row — login status is already under the title. Install, uninstall, self-update, where-is-me, version, and about stay off this list. Pick **sudoers** to open the grant/draft list; **8** goes back; **9** leaves. On a real terminal the `menu`/`main` list appears even if you also passed `--json`.

| You | Another role | Not this |
|-----|--------------|----------|
| Type `grok-cli` or `grok-cli menu`, pick a number | CI / pipe: empty argv ensures install; `menu` prints help; `--json` with no command gets JSON help | A menu that hangs a pipeline; `restore` on the list; install/version on the list; `sudoers` as a typed CLI command |

**Includes:** TTY empty argv numbered list; `menu`/`main` numbered TTY main list; default CLI main menu style (header `APP_NAME(APP_VERSION)`; TTY explain italic + light gray); session line under the title; family row **sudoers** + submenu; Exit **9**; Back **8**; off-TTY `menu` help. **Excludes:** off-TTY empty argv (Type O); `help` as a list row; `check-session` as a numbered row; install / uninstall / self-update / where-is-me / version / about on either list; a live `sudoers` dispatcher token; a second TTY look (unstyled explain, SGR 90, styled number/name).

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Start at a prompt | Daily auth work; **backup** is **1**; login status is under the title | `grok-cli` then `1` |
| Push auth to the store | First row | `grok-cli` then `1` |
| Pull from another host | Third row (prompts for SPEC on TTY) | `grok-cli` then `3` |
| Install the timers | Fourth row | `grok-cli` then `4` |
| Open grant/drafts | Family row **5**, then a number | `grok-cli` then `5` then `1` |
| Leave the grant list | Back to the start list | `8` |
| Leave the menu | Exit | `9` |
| Install the program | Not on this list | `grok-cli install` |
| Run with no args in a script | Channel ensure (not this menu) | `curl -fsSL … \| sh` |
| Run `menu` in a script | Help screen, no pick | `grok-cli menu </dev/null` |

---

## 2. Core Rules (Mandatory)

### 2.1 Claim and case

grok-cli **claims** a default function. **Case 3** applies: `requirement-shell-cli-zero-arguments` exists. That REQ **defers TTY empty argv** to this menu. Off-TTY empty argv is Type O ensure on that REQ — **this file MUST NOT** print help for bare off-TTY empty argv. Off-TTY **`menu`/`main`** still print help.

### 2.2 Routed verb `menu` / `main` and TTY empty argv

| Token | Role |
|-------|------|
| empty argv (`$# -eq 0`) | Same handler as `menu` when TTY=1; Type O ensure when TTY=0 (owned by zero-arguments; **not** `app_default`) |
| `menu` | Primary named command for this default |
| `main` | Same handler (alias) |

After flag parse, when the command token is `menu` or `main`, **or** when argv was empty at `app_main` (zero-arguments routes `COMMAND=menu`), grok-cli **MUST** branch (`TTY` measured in the main process, **not** inside helpers):

| # | Condition | MUST | MUST NOT |
|---|-----------|------|----------|
| 1 | Interactive (`TTY=1`) | **Main menu** (§2.3). For `menu`/`main`, **ignore `--json`** even if `JSON=1` | JSON help; hang |
| 2 | Not interactive (`TTY=0`) and `JSON=0` | **Human help screen** — `app_help` (not JSON) | Menu; silent return; hang |
| 3 | Not interactive (`TTY=0`) and `JSON=1` | **JSON help** — `app_help` in JSON mode | Menu; human banners; hang |

`--quiet` without a TTY still takes the **help screen** path (do not swallow `menu` help). Flags-only `--json` (not empty argv) stays help — `requirement-shell-cli-zero-arguments`.

### 2.3 Main menu

1. Print a **numbered list** of **daily auth work** plus one **family** row, then **Exit**.  
2. **MUST NOT** list **install / setup**, **self-managed** commands (`install`, `uninstall`, `where-is-me`), **diagnostics** (`version`, `about`), or **test-purpose** verbs.  
3. Command-row text **MUST** be `command: what it does`. The numbered list **MUST** follow **default CLI main menu style**: header as in rule 10; each numbered row `command: what it does` with the number and command name **unstyled**; on a TTY the **explain** text after `: ` **MUST** be *italic* **and** light gray (SGR **3** + **37**, CSI `ESC[3;37m` … `ESC[0m` via `out_menu_choice`). Off-TTY: plain. **MUST NOT** print explain unstyled on a TTY. **MUST NOT** a second house look (SGR 90, italic-only, gray-only, styled number/name).  
4. **MUST NOT** list `help`, `restore`, `menu`/`main`, `check-session`, or the five sudoers verbs on the **main** list (sudoers verbs live on the submenu; session status is under the title).  
5. Main command rows **N = 5** (four verbs + one family). Exit **MUST** be **9**. Unused integers **6–8** are omitted.  
6. Accept a **number** or a **listed verb**. **9** / `exit` / `quit` returns 0.  
7. **`sudoers` is not a live CLI command.** Choosing **5** or typing `sudoers` at the pick prompt **MUST** open the submenu (§2.4). `grok-cli sudoers` **MUST** remain unknown.  
8. Typing a submenu verb at the **main** pick prompt **MAY** run that handler (shortcut). Live verbs excluded from both lists **MUST NOT** run from the pick prompt (typed `check-session` **MAY** still run as a shortcut).  
9. The choice **MUST** be read in the **current shell**. **MUST NOT** `$()` / backticks a helper whose body contains `read` (**do-not-capture-read** / **PP-A-22**; current-shell `PROMPT_ASK_VALUE`).  
10. **Header (mandatory — default CLI main menu style):** the first human line that names the program **MUST** be live **`APP_NAME(APP_VERSION)`** (`APP_VERSION` = Config `VERSION`) with **bold** name and *italic* version, then the product short description (`SHORT_DESCRIPTION` / `APP_DESC`). Typical: `out_info "$(util_app_ident) — ${SHORT_DESCRIPTION}"` which prints **Alternative online installer for xAI grok**. TTY: SGR 1 / SGR 3. Off-TTY: plain. **MUST NOT** a bare `APP_NAME` on that header. **MUST NOT** the generic board title “numbered list of live commands”.  
11. **Session line (mandatory):** immediately under the header, print **`logged in`** when `gc_session_status_word` is `valid`, otherwise **`logged out`**. **MUST NOT** make this a numbered row.

Normative **main** order:

| # | Token | Label |
|---|-------|-------|
| *(header)* | — | `**APP_NAME**(*APP_VERSION*) — Alternative online installer for xAI grok` |
| *(status)* | — | `logged in` / `logged out` |
| 1 | `backup` | `backup: Push ~/.grok/auth.* to /var/grok-cli` |
| 2 | `sync-auth` | `sync-auth: Copy /var/grok-cli/auth.* into ~/.grok` |
| 3 | `sync-auth-from-remote` | `sync-auth-from-remote: Copy a remote host's auth.* into ~/.grok` |
| 4 | `add-crontab` | `add-crontab: Add backup and sync-auth jobs to this login's crontab` |
| 5 | family `sudoers` | `sudoers: Grant and drafts` |
| **9** | **Exit** | leave the menu |

### 2.4 Sudoers submenu

Choosing main **5** / `sudoers` **MUST** print a second numbered list of the grouped live verbs. Submenu header **MUST** use the same `APP_NAME(APP_VERSION)` nametag. Explain text **MUST** follow the same default CLI main menu style as the main list (*italic* + light gray SGR **3** + **37** on a TTY via `out_menu_choice`). **MUST NOT** hang off-TTY (submenu exists only on the interactive menu path).

| # | Command | Label |
|---|---------|-------|
| 1 | `generate-sudoer-request` | `generate-sudoer-request: Write a JSON grant you can read` |
| 2 | `submit-sudoer-request` | `submit-sudoer-request: Queue the JSON grant inbound` |
| 3 | `print-sudoers` | `print-sudoers: Emit sudoers draft` |
| 4 | `print-sudoers-install-script` | `print-sudoers-install-script: Write admin install script` |
| 5 | `remove-project-sudoers` | `remove-project-sudoers: Remove sudoers draft only` |
| **8** | **Back** | return to the main list (not a command) |
| **9** | **Exit** | leave the menu |

Submenu command rows **N = 5**. Exit **MUST** be **9**. **Back MUST** be **8**. Unused **6** and **7** are omitted.

- **8** / `back` / `Back` returns to the main list (does not run a handler).  
- **9** / `exit` / `quit` returns 0 from `menu` (same as main Exit).  
- A listed number or verb runs that handler, then returns 0 from `menu` (one command, then done).  
- All five grouped verbs **MUST** appear here. **MUST NOT** put install/version/about/`help`/`restore` on this list.

### 2.5 Implementation Notes (this product)

| Item | Value |
|------|--------|
| **Product** | grok-cli |
| **Ship unit** | `src/grok-cli` |
| **Claimed** | yes |
| **Case** | **3** (zero-argument REQ exists; that REQ defers TTY empty argv here; off-TTY empty argv is Type O, not this file) |
| **Empty argv** | TTY → this menu; off-TTY → Type O ensure (`requirement-shell-cli-zero-arguments`; not this handler) |
| **Verb** | `menu` (alias `main`); TTY empty argv sets `COMMAND=menu` |
| **Handler** | `app_default` (`menu` / `main` / TTY empty argv); submenu printer/loop under the same `app_default_*` family |
| **Family row** | `sudoers` — menu-only; **not** dispatched |
| **Label source** | `reviews/cli-routed-verb-table.md` **human-readable** for command rows; family explain is this file’s table |
| **Interactive + `--json`** | Ignore json on `menu`/`main`; still the menu |
| **Non-interactive** | `app_help` (human; `--quiet` still prints help) |
| **Look** | **default CLI main menu style** — header `APP_NAME(APP_VERSION)`; TTY explain *italic* + light gray (SGR 3+37) via `out_menu_choice`; number and name unstyled |
| **Honesty** | **Implemented.** TTY empty argv draws this menu. Off-TTY empty argv is Type O ensure (not help, not this menu). Header `APP_NAME(APP_VERSION)`; session line under the title; main **N = 5**; submenu **N = 5**; Exit **9**; Back **8**. |

### 2.6 Why this requirement exists (CIAO)

- **Intentional**: Daily auth work is the start list; grant/draft commands are one extra pick.  
- **Caution**: Scripts never hang; `--json` on a real terminal does not hide the `menu` list.  
- **Anti-fragile**: Back returns to the start list; Exit leaves from either screen.  
- **Over-protect**: `sudoers` is not a live dispatcher token; install / version / about / `help` / `restore` stay off both lists; Exit is **9**, not **5**.

---

## 3. Design Principles

- The start list is **daily work**, not a reprint of `help`.  
- Related rare commands share one family row.  
- Dispatcher remains routing SSOT (`sudoers` is not added there).  
- Fail closed off-TTY.  
- Zero-arguments owns Type O off-TTY vs TTY menu; this file owns the list body.

---

## 4. Protection Rule (Sacred)

Future agents **MUST NOT**:

1. Put `install`, `uninstall`, `where-is-me`, `version`, `about`, `help`, `menu`/`main`, or `restore` on the main list or the sudoers submenu.  
2. Put the five sudoers verbs on the **main** list.  
2b. Put `check-session` on the numbered main list (login status **MUST** stay under the title).  
3. Drop a grouped sudoers verb from the submenu.  
4. Number main Exit as **5** or submenu Exit as **6** (Exit **MUST** be **9**; Back **MUST** be **8** on the submenu).  
5. Wire `sudoers` as a live `app_main` command.  
6. Draw this menu on **off-TTY** empty argv, or hang a pipe on empty argv / `menu` / `main`.  
7. Steal Type O install-ensure onto **TTY** empty argv (menu stolen).  
8. Invent command-row labels that are not `command: what it does`.  
9. Replace TTY empty argv with the help dump while zero-arguments **1.3.0+** defers that path here.  
10. Print a main-menu (or APP_NAME-led submenu) header as a bare `APP_NAME` without live `VERSION` / `APP_VERSION`, or unstyled on TTY.  
11. Capture the menu choice with `$()` of a `read` helper.  
12. Draw the numbered list off **default CLI main menu style** — **MUST NOT** print numbered-choice explain unstyled on a TTY (it **MUST** be *italic* and light gray, SGR **3** + **37**, via `out_menu_choice`). **MUST NOT** invent a second house look (SGR 90, italic-only, gray-only, styled number/name).  
13. Print the generic board title “numbered list of live commands” instead of Config `SHORT_DESCRIPTION` / `APP_DESC` (**Alternative online installer for xAI grok**).

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-07** | `tests/test_cli.sh` | have (TTY empty argv = this menu; off-TTY empty argv = Type O ensure) |
| **TP-CLI-13** | `tests/test_cli.sh` | have (main list, family row, submenu Back/Exit, off-TTY help) |
| **TP-CLI-17** | `tests/test_cli.sh` | have (default CLI main menu style: header `APP_NAME(APP_VERSION)` bold/italic; board title **Alternative online installer for xAI grok**; numbered explain italic + light gray SGR 3+37; number/name unstyled; logged in/out; no check-session row) |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

---

**Last Updated**: 2026-09-03 (2.3.0 — main-menu board title is product short description **Alternative online installer for xAI grok**)  
**Owner**: product  
**Alignment**: `requirement-shell-cli-zero-arguments` · `requirement-shell-cli-interface` · `requirement-shell-interactive-vs-noninteractive` · `requirement-shell-output-requirements` · `requirement-domain-grok-cli` (no `restore`) · CIAO / CIAO-Lite
