**file**: docs/requirements/requirement-shell-cli-default-interaction.md  
**Status**: Active (Version 2.10.0)  
**Area**: shell  
**Key**: `requirement-shell-cli-default-interaction`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **product Single Source of Truth** for grok-cli’s **default interaction**: a **short numbered main menu** of daily **auth work**, with sudoers grant/draft commands behind one **family** row. grok-cli has `requirement-shell-cli-zero-arguments` (**case 3**): that REQ **defers TTY empty argv** to this menu and **owns off-TTY empty argv as Type O ensure**. The menu **MUST** also be the command **`menu`**. **`main` MAY** be accepted as the same handler.

On a **real terminal**, empty argv (no command token — overlay switches such as `--debug` allowed) and `grok-cli menu` (or `main`) **MUST** show the main menu. `menu`/`main` **MUST ignore `--json`**. Off-TTY, **`menu`/`main` MUST** print **help**, following `--json`. Off-TTY **empty argv** is **not** this file — it is channel ensure. Command rows **MUST** be `command: what it does`. The family row **MUST NOT** be a live dispatcher command.

Empty-argv type and the TTY vs off-TTY split for **no command token** stay on `requirement-shell-cli-zero-arguments`. Confirm / no-hang stays on `requirement-shell-interactive-vs-noninteractive`. Live command inventory stays dispatcher truth (`requirement-shell-cli-interface`).

### 1.1 Human-facing

Typing only `grok-cli` at a real terminal shows the numbered start list. In a script, bare `grok-cli` installs or reports already installed (not this menu). `grok-cli menu` (or `grok-cli main`) still opens the list on a TTY and prints help in a script. The list header is **grok-cli**(*version*) — **Alternative online installer for xAI grok** and the next line is **logged in** or **logged out**. On a multi-user host, numbered rows are backup, sync-auth, sync-auth-from-remote, add-crontab, then **sudoers**. On Termux / Git Bash / Windows cmd (this login only), **backup**, **sync-auth**, and **sudoers** are omitted; remaining rows start at **1** with **`run`**; immediately under the login status the list prints **backup, sync-auth and sudoers features are not available in {{termux/gitbash/windows-cmd}}.** When the session is **logged in**, **sync-auth** and **sync-auth-from-remote** are also omitted on every host; immediately under any host not-available line (or under the login status when there is none) the list **appends** **`sync-auth and sync-auth-from-remote features are not available for logged-in environment.`** — it **MUST NOT** replace the host line. Remaining rows start at **1**. On a real terminal the “what it does” text after the colon is gray and italic (default CLI main menu style). `check-session` is not a row — login status is already under the title. Install, uninstall, self-update, where-is-me, version, and about stay off this list. Pick **sudoers** (when listed) to open the grant/draft list; **8** goes back; **9** leaves. On a real terminal the `menu`/`main` list appears even if you also passed `--json`.

| You | Another role | Not this |
|-----|--------------|----------|
| Type `grok-cli`, `grok-cli --debug`, or `grok-cli menu`, pick a number | CI / pipe: empty argv ensures install; `menu` prints help; `--json` with no command gets JSON help | A menu that hangs a pipeline; help because `--debug` was present; `restore` on the list; install/version on the list; `sudoers` as a typed CLI command |

**Includes:** TTY empty argv numbered list; `menu`/`main` numbered TTY main list; default CLI main menu style (header `APP_NAME(APP_VERSION)`; TTY explain italic + light gray); session line under the title; **not-available** line on this-login-only hosts; **appended** logged-in not-available line when the session is valid; family row **sudoers** + submenu on multi-user hosts; Exit **9**; Back **8**; off-TTY `menu` help. **Excludes:** off-TTY empty argv (Type O); `help` as a list row; `check-session` as a numbered row; install / uninstall / self-update / where-is-me / version / about on either list; a live `sudoers` dispatcher token; showing backup / sync-auth / sudoers on Termux / Git Bash / Windows cmd; showing **sync-auth** / **sync-auth-from-remote** when **logged in**; replacing the host not-available line with the logged-in line; a second TTY look (unstyled explain, SGR 90, styled number/name).

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Start at a prompt | Daily work; on a multi-user host when **logged out** **backup** is **1**; on Termux / Git Bash / Windows cmd **run** is **1**; login status is under the title | `grok-cli` then `1` |
| Start grok without auto-update | First row on Termux / Git Bash / Windows cmd | `grok-cli` then `1` (or `grok-cli run`) |
| Push auth to the store | First row (multi-user host) | `grok-cli` then `1` |
| Pull from another host | Listed only when **logged out**: third row on a multi-user host; **2** on Termux / Git Bash / Windows cmd (prompts for SPEC on TTY) | `grok-cli` then the listed number |
| Install the timers | Fourth row (multi-user, logged out); **3** on this-login-only when logged out; **2** on a multi-user host when logged in; **2** on this-login-only when logged in | `grok-cli` then the listed number |
| Open grant/drafts | Family row **5** on a multi-user host when **logged out**, **3** when **logged in**, then a number. **Not listed** on Termux / Git Bash / Windows cmd | `grok-cli` then the listed sudoers number then `1` |
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
| empty argv (no command token; overlay `--debug` / `--quiet` allowed) | Same handler as `menu` when TTY=1; Type O ensure when TTY=0 (owned by zero-arguments; **not** `app_default`) |
| `menu` | Primary named command for this default |
| `main` | Same handler (alias) |

After flag parse, when the command token is `menu` or `main`, **or** when no command token was present and `--json` is off (zero-arguments routes `COMMAND=menu` on a TTY — including `grok-cli --debug`), grok-cli **MUST** branch (`TTY` measured in the main process, **not** inside helpers):

| # | Condition | MUST | MUST NOT |
|---|-----------|------|----------|
| 1 | Interactive (`TTY=1`) | **Main menu** (§2.3). For `menu`/`main`, **ignore `--json`** even if `JSON=1` | JSON help; hang |
| 2 | Not interactive (`TTY=0`) and `JSON=0` | **Human help screen** — `app_help` (not JSON) | Menu; silent return; hang |
| 3 | Not interactive (`TTY=0`) and `JSON=1` | **JSON help** — `app_help` in JSON mode | Menu; human banners; hang |

`--quiet` without a TTY on **`menu`/`main`** still takes the **help screen** path (do not swallow `menu` help). Flags-only `--json` **is** empty argv on `requirement-shell-cli-zero-arguments`; **special case** = JSON help **even on a TTY** (this file **MUST NOT** steal it onto the numbered list). Overlay flags-only (`--debug`, `--quiet` with no command) follow the ordinary empty-argv path on that REQ. `grok-cli menu --json` on a TTY still ignores `--json` (rule 1).

### 2.3 Main menu

1. Print a **numbered list** of **daily auth work** plus one **family** row, then **Exit**.  
2. **MUST NOT** list **install / setup**, **self-managed** commands (`install`, `uninstall`, `where-is-me`), **diagnostics** (`version`, `about`), or **test-purpose** verbs.  
3. Command-row text **MUST** be `command: what it does`. The numbered list **MUST** follow **default CLI main menu style**: header as in rule 10; each numbered row `command: what it does` with the number and command name **unstyled**; on a TTY the **explain** text after `: ` **MUST** be *italic* **and** light gray (SGR **3** + **37**, CSI `ESC[3;37m` … `ESC[0m` via `out_menu_choice`). Off-TTY: plain. **MUST NOT** print explain unstyled on a TTY. **MUST NOT** a second house look (SGR 90, italic-only, gray-only, styled number/name).  
4. **MUST NOT** list `help`, `restore`, `menu`/`main`, `check-session`, or the five sudoers verbs on the **main** list (sudoers verbs live on the submenu; session status is under the title).  
5. Main command rows **N** is the count of **listed** remaining verbs (plus family when listed). On a **multi-user** host when **logged out**, **N = 5**. On a **multi-user** host when **logged in**, **N = 3** (backup, add-crontab, sudoers). On **command line for normal user only** (Termux / Git Bash / Windows cmd — §2.3b) when **logged out**, **N = 3** (`run`, `sync-auth-from-remote`, `add-crontab`). On that class when **logged in**, **N = 2** (`run`, `add-crontab`). Exit **MUST** be **9**. Unused integers between the last listed row and **9** are omitted.  
6. Accept a **number** or a **listed verb**. **9** / `exit` / `quit` returns 0.  
7. **`sudoers` is not a live CLI command.** On a multi-user host, choosing the **listed** sudoers number (**5** when logged out; **3** when logged in) or typing `sudoers` at the pick prompt **MUST** open the submenu (§2.4). On Termux / Git Bash / Windows cmd, **sudoers** is not a listed row — choosing a leftover integer or typing `sudoers` **MUST** be “not a menu choice” (do not open the submenu). `grok-cli sudoers` **MUST** remain unknown.  
8. Typing a submenu verb at the **main** pick prompt **MAY** run that handler (shortcut) when that verb is listed on this host’s menu. Live verbs excluded from both lists **MUST NOT** run from the pick prompt (typed `check-session` **MAY** still run as a shortcut). Hidden **backup** / **sync-auth** / **sudoers** on this-login-only hosts **MUST NOT** run from a listed number. Hidden **sync-auth** / **sync-auth-from-remote** when **logged in** **MUST NOT** run from a listed number.  
9. The choice **MUST** be read in the **current shell**. **MUST NOT** `$()` / backticks a helper whose body contains `read` (**do-not-capture-read** / **PP-A-22**; current-shell `PROMPT_ASK_VALUE`).  
10. **Header (mandatory — default CLI main menu style):** the first human line that names the program **MUST** be live **`APP_NAME(APP_VERSION)`** (`APP_VERSION` = Config `VERSION`) with **bold** name and *italic* version, then the product short description (`SHORT_DESCRIPTION` / `APP_DESC`). Typical: `out_info "$(util_app_ident) — ${SHORT_DESCRIPTION}"` which prints **Alternative online installer for xAI grok**. TTY: SGR 1 / SGR 3. Off-TTY: plain. **MUST NOT** a bare `APP_NAME` on that header. **MUST NOT** the generic board title “numbered list of live commands”.  
11. **Session line (mandatory):** immediately under the header, print **`logged in`** when `gc_session_status_word` is `valid`, otherwise **`logged out`**. That word **MUST** use the live `grok -p hello` probe (`requirement-grok-auth-backup`) — **MUST NOT** treat `auth.json` parse alone as logged-in. The probe **MUST** close stdin and **MUST NOT** hang the menu — **MUST** bound even when `timeout` is missing, and **MUST** SIGKILL-follow (`timeout -k` or POSIX watchdog) so a Termux `proot` child that ignores SIGTERM cannot freeze after the header. If `proot` is on PATH, that probe **MUST** use the PRoot-exit reaper (`requirement-shell-termux-coding` 2.4c); else simple `grok -p hello`. A reprint after a bad pick **MUST NOT** run a second probe (reuse `GC_SESSION_STATUS_CACHE`). **MUST NOT** make this a numbered row.  
12. **Not-available line (mandatory on this-login-only hosts):** immediately under the session line, when the host is Termux / Git Bash / Windows cmd (detect in **Under command line for normal user only**), print exactly **`backup, sync-auth and sudoers features are not available in {{label}}.`** where **label** is **`termux`**, **`gitbash`**, or **`windows-cmd`**. **MUST NOT** make this a numbered row. **MUST NOT** print this line on a multi-user host.  
13. **Logged-in not-available line (mandatory when session is valid):** when `gc_session_status_word` is `valid`, **MUST NOT** display **sync-auth** or **sync-auth-from-remote**. Immediately under the host not-available line when that line is printed, otherwise immediately under the session line, **MUST** print exactly **`sync-auth and sync-auth-from-remote features are not available for logged-in environment.`** This line **MUST** be an **additional** `out_plain` line — **MUST NOT** replace, rewrite, or drop the host not-available line. **MUST NOT** make this a numbered row. **MUST NOT** print this line when the session is not valid.  
14. **Debug elapsed (mandatory when `DEBUG=1`):** the numbered list **MUST** print elapsed wall-clock of each paint step on stderr via `out_debug` (`requirement-shell-internal-volatile-timer`). Stages: `paint`, `header`, `session`, `host`, `logged-in`, `rows` (plus `sudoers.*` on the submenu). **MUST NOT** put elapsed on numbered choice rows. **MUST NOT** print those lines when `DEBUG=0`. **MUST NOT** hang or skip the list because a timer helper failed.

Normative **main** order (multi-user host, **logged out**):

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

### 2.3b Main menu on command line for normal user only

When detect is Termux / Git Bash / Windows cmd, the start list **MUST NOT** display **backup**, **sync-auth**, or **sudoers**. Remaining listed verbs **MUST** be numbered from **1**. Direct CLI `{{APP_NAME}} backup` / `sync-auth` stay routed (unused on this class is menu honesty, not a second dispatcher).

Normative **main** order (this-login-only host, **logged out**):

| # | Token | Label |
|---|-------|-------|
| *(header)* | — | `**APP_NAME**(*APP_VERSION*) — Alternative online installer for xAI grok` |
| *(status)* | — | `logged in` / `logged out` |
| *(not-available)* | — | `backup, sync-auth and sudoers features are not available in {{termux\|gitbash\|windows-cmd}}.` |
| 1 | `run` | `run: Start grok without auto-update` |
| 2 | `sync-auth-from-remote` | `sync-auth-from-remote: Copy a remote host's auth.* into ~/.grok` |
| 3 | `add-crontab` | `add-crontab: Add backup and sync-auth jobs to this login's crontab` |
| **9** | **Exit** | leave the menu |

### 2.3c Main menu when logged in

When the session line is **logged in**, the start list **MUST NOT** display **sync-auth** or **sync-auth-from-remote** (any host). Direct CLI `{{APP_NAME}} sync-auth` / `sync-auth-from-remote` stay routed; the copy skip is `requirement-grok-auth-backup`. Remaining listed verbs **MUST** be numbered from **1**.

Normative **main** order (multi-user host, **logged in**):

| # | Token | Label |
|---|-------|-------|
| *(header)* | — | `**APP_NAME**(*APP_VERSION*) — Alternative online installer for xAI grok` |
| *(status)* | — | `logged in` |
| *(not-available)* | — | `sync-auth and sync-auth-from-remote features are not available for logged-in environment.` |
| 1 | `backup` | `backup: Push ~/.grok/auth.* to /var/grok-cli` |
| 2 | `add-crontab` | `add-crontab: Add backup and sync-auth jobs to this login's crontab` |
| 3 | family `sudoers` | `sudoers: Grant and drafts` |
| **9** | **Exit** | leave the menu |

Normative **main** order (this-login-only host, **logged in**) — host line **then** logged-in line (**append**, never replace):

| # | Token | Label |
|---|-------|-------|
| *(header)* | — | `**APP_NAME**(*APP_VERSION*) — Alternative online installer for xAI grok` |
| *(status)* | — | `logged in` |
| *(not-available)* | — | `backup, sync-auth and sudoers features are not available in {{termux\|gitbash\|windows-cmd}}.` |
| *(not-available)* | — | `sync-auth and sync-auth-from-remote features are not available for logged-in environment.` |
| 1 | `run` | `run: Start grok without auto-update` |
| 2 | `add-crontab` | `add-crontab: Add backup and sync-auth jobs to this login's crontab` |
| **9** | **Exit** | leave the menu |

### 2.4 Sudoers submenu

On a multi-user host, choosing the listed sudoers number (**5** logged out; **3** logged in) / `sudoers` **MUST** print a second numbered list of the grouped live verbs. On Termux / Git Bash / Windows cmd the family row is omitted (§2.3b). Submenu header **MUST** use the same `APP_NAME(APP_VERSION)` nametag. Explain text **MUST** follow the same default CLI main menu style as the main list (*italic* + light gray SGR **3** + **37** on a TTY via `out_menu_choice`). **MUST NOT** hang off-TTY (submenu exists only on the interactive menu path).

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
| **Verb** | `menu` (alias `main`); TTY empty argv (including `--debug` with no command) sets `COMMAND=menu` |
| **Handler** | `app_default` (`menu` / `main` / TTY empty argv); submenu printer/loop under the same `app_default_*` family |
| **Family row** | `sudoers` — menu-only; **not** dispatched |
| **Label source** | `reviews/cli-routed-verb-table.md` **human-readable** for command rows; family explain is this file’s table |
| **Interactive + `--json`** | Ignore json on `menu`/`main`; still the menu |
| **Non-interactive** | `app_help` (human; `--quiet` still prints help) |
| **Look** | **default CLI main menu style** — header `APP_NAME(APP_VERSION)`; TTY explain *italic* + light gray (SGR 3+37) via `out_menu_choice`; number and name unstyled |
| **Honesty** | **Implemented.** TTY empty argv (including `--debug` with no command) draws this menu. Off-TTY empty argv is Type O ensure (not help, not this menu). Header `APP_NAME(APP_VERSION)`; session line under the title from live `grok -p hello` (always bounded; reprint reuses `GC_SESSION_STATUS_CACHE`); host not-available line on Termux / Git Bash / Windows cmd; logged-in not-available line **appended** when session is valid; main **N = 5 / 3 / 3 / 2** (multi-user logged out / multi-user logged in / this-login-only logged out / this-login-only logged in); submenu **N = 5**; Exit **9**; Back **8**. `--debug` prints elapsed of each paint step (`requirement-shell-internal-volatile-timer`). |
| **Host detect** | `gc_host_is_normal_user_only` / `gc_host_normal_user_only_label` (`termux` · `gitbash` · `windows-cmd`) |

### 2.6 Why this requirement exists (CIAO)

- **Intentional**: Daily auth work is the start list; grant/draft commands are one extra pick.  
- **Caution**: Scripts never hang; `--json` on a real terminal does not hide the `menu` list.  
- **Anti-fragile**: Back returns to the start list; Exit leaves from either screen.  
- **Over-protect**: `sudoers` is not a live dispatcher token; install / version / about / `help` / `restore` stay off both lists; Exit is **9**, not **5**.

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

**This requirement:** omit **backup**, **sync-auth**, and **sudoers** from the numbered list on detect. Remaining rows number from **1** with **`run` first**. Immediately under the login status print **`backup, sync-auth and sudoers features are not available in {{termux/gitbash/windows-cmd}}.`** When **logged in**, **also** omit **sync-auth-from-remote** and **append** the logged-in not-available line (§2.3c) after the host line. Do not add sudo-install rows.

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
9b. Treat TTY `grok-cli --debug` (no command) as help instead of this menu. Overlay flags-only is empty argv (`requirement-shell-cli-zero-arguments` **2.1.0+**).  
9c. Draw this menu for TTY `grok-cli --json` (no command). That invocation **is** empty argv but the special-case outcome is JSON help (`requirement-shell-cli-zero-arguments` **2.2.0+**).  
10. Print a main-menu (or APP_NAME-led submenu) header as a bare `APP_NAME` without live `VERSION` / `APP_VERSION`, or unstyled on TTY.  
11. Capture the menu choice with `$()` of a `read` helper.  
12. Draw the numbered list off **default CLI main menu style** — **MUST NOT** print numbered-choice explain unstyled on a TTY (it **MUST** be *italic* and light gray, SGR **3** + **37**, via `out_menu_choice`). **MUST NOT** invent a second house look (SGR 90, italic-only, gray-only, styled number/name).  
13. Print the generic board title “numbered list of live commands” instead of Config `SHORT_DESCRIPTION` / `APP_DESC` (**Alternative online installer for xAI grok**).  
14. Print **logged in** from `auth.json` parse alone (the session line **MUST** use `grok -p hello`).  
15. Strip the **Under command line for normal user only** section, or enable admin privilege / a dedicated system user on Termux / Git Bash / Windows cmd.  
16. Display **backup**, **sync-auth**, or **sudoers** on the main list on Termux / Git Bash / Windows cmd.  
17. Omit the **host not-available** line on that class, print it on a multi-user host, or invent a different wording / host label (`termux` · `gitbash` · `windows-cmd`).  
18. Display **sync-auth** or **sync-auth-from-remote** on the main list when the session is **logged in**, or omit the logged-in not-available line on that session.  
19. Replace the host not-available line with the logged-in line, merge them into one sentence, or skip the host line because the session is logged in. The logged-in line **MUST** append.  
20. Freeze the numbered menu on Termux (or any host) while waiting for `grok -p hello` — missing `timeout`, a peer that ignores SIGTERM, or a second probe on reprint.  
21. Skip `--debug` elapsed of each paint step, print those lines when `DEBUG=0`, or put elapsed onto numbered choice rows.  
22. Omit **`run`** from the this-login-only start list, or number it after backup/sync-auth/sudoers on that class.  


## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-07** | `tests/test_cli.sh` | have (TTY empty argv = this menu; off-TTY empty argv = Type O ensure) |
| **TP-CLI-29** | `tests/test_cli.sh` | have (TTY `--debug` no command = this menu; off-TTY `--debug` no command = Type O ensure) |
| **TP-CLI-13** | `tests/test_cli.sh` | have (main list, family row, submenu Back/Exit, off-TTY help) |
| **TP-CLI-17** | `tests/test_cli.sh` | have (default CLI main menu style: header `APP_NAME(APP_VERSION)` bold/italic; board title **Alternative online installer for xAI grok**; numbered explain italic + light gray SGR 3+37; number/name unstyled; logged in/out from live `grok -p hello`; no check-session row) |
| **TP-CLI-19** | `tests/test_cli.sh` | have (Termux / Git Bash / Windows cmd: hide backup / sync-auth / sudoers; **run** is **1**; not-available line under session; remaining rows from **1**) |
| **TP-CLI-20** | `tests/test_cli.sh` | have (logged in: hide sync-auth / sync-auth-from-remote; append logged-in not-available line; host line still present on this-login-only; remaining rows from **1**; listed sudoers number opens submenu) |
| **TP-CLI-21** | `tests/test_cli.sh` | have (Termux menu with a SIGTERM-ignoring grok still prints the list and accepts Exit; no freeze) |
| **TP-CLI-22** | `tests/test_cli.sh` | have (bad pick reprints without a second hang-grok probe) |
| **TP-CLI-23** | `tests/test_cli.sh` | have (ship unit has `timeout -k` + watchdog `kill -9`) |
| **TP-CLI-25** | `tests/test_cli.sh` | have (`--debug menu` elapsed of each paint step, including `sudoers.*`) |
| **TP-CLI-26** | `tests/test_cli.sh` | have (no `--debug` → no menu-step elapsed) |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

---

**Last Updated**: 2026-09-07 (2.10.0 — session probe uses PRoot reaper when `proot` is on PATH)  
**Owner**: product  
**Alignment**: `requirement-shell-cli-zero-arguments` · `requirement-shell-cli-interface` · `requirement-shell-interactive-vs-noninteractive` · `requirement-shell-output-requirements` · `requirement-shell-internal-volatile-timer` (`--debug` elapsed) · `requirement-grok-auth-backup` (session probe) · `requirement-domain-grok-cli` (no `restore`) · CIAO / CIAO-Lite
