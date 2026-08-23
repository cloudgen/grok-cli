**file**: docs/requirements/requirement-shell-cli-default-interaction.md  
**Status**: Active (Version 1.6.0)  
**Area**: shell  
**Key**: `requirement-shell-cli-default-interaction`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **product Single Source of Truth** for grok-cli’s **default interaction**: a **short numbered main menu** of daily **auth work**, with sudoers grant/draft commands behind one **family** row. grok-cli already has `requirement-shell-cli-zero-arguments` (**case 3**): empty argv stays Type N **help**. The menu **MUST** be the command **`menu`**. **`main` MAY** be accepted as the same handler.

On a **real terminal**, `grok-cli menu` (or `main`) **MUST** show the main menu and **MUST ignore `--json`**. Off-TTY it **MUST** print **help**, following `--json` (human help vs JSON help). Command rows **MUST** be `command: what it does` (same meaning as that command’s help one-liner). The family row **MUST NOT** be a live dispatcher command.

Empty-argv type (Type N vs Type O) stays on `requirement-shell-cli-zero-arguments`. Confirm / no-hang stays on `requirement-shell-interactive-vs-noninteractive`. Live command inventory stays dispatcher truth (`requirement-shell-cli-interface`).

### 1.1 Human-facing

Typing only `grok-cli` still prints help. The numbered start list is `grok-cli menu` (or `grok-cli main`). It shows check-session, backup, sync-auth, then **sudoers** for grants and drafts. Install, uninstall, where-is-me, version, and about stay on **help**. Pick **sudoers** to open the grant/draft list; **8** goes back; **9** leaves. On a real terminal the list appears even if you also passed `--json`. In a script, `menu` prints the help screen; with `--json` it prints JSON help.

| You | Another role | Not this |
|-----|--------------|----------|
| Type `grok-cli menu`, pick a number | CI / pipe gets help from `menu`; `--json` gets JSON help | A menu that hangs a pipeline; `restore` on the list; install/version on the list; `sudoers` as a typed CLI command; a menu when you type only `grok-cli` |

**Includes:** `menu`/`main` numbered TTY main list; family row **sudoers** + submenu; `command: what it does`; Exit **9**; Back **8** on the submenu; non-interactive help; JSON help off-TTY. **Excludes:** empty argv; `help` as a list row; install / uninstall / where-is-me / version / about on either list; a live `sudoers` dispatcher token; dest yes/no review.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Start at a prompt | Daily auth work; **check-session** is **1** | `grok-cli menu` then `1` |
| Push auth to the store | Second row | `grok-cli menu` then `2` |
| Open grant/drafts | Family row **4**, then a number | `grok-cli menu` then `4` then `1` |
| Leave the grant list | Back to the start list | `8` |
| Leave the menu | Exit | `9` |
| Install the program | Not on this list | `grok-cli install` |
| Run `menu` in a script | Help screen, no pick | `grok-cli menu </dev/null` |

---

## 2. Core Rules (Mandatory)

### 2.1 Claim and case

grok-cli **claims** a default function. **Case 3** applies: `requirement-shell-cli-zero-arguments` exists; product is **not** online-installable. Type O install-ensure does **not** apply. Empty argv **MUST NOT** become this menu.

### 2.2 Routed verb `menu` / `main`

| Token | Role |
|-------|------|
| `menu` | Primary command for this default |
| `main` | Same handler (alias) |

After flag parse, when the command token is `menu` or `main`, grok-cli **MUST** branch (`TTY` measured in the main process, **not** inside helpers):

| # | Condition | MUST | MUST NOT |
|---|-----------|------|----------|
| 1 | Interactive (`TTY=1`) | **Main menu** (§2.3). **Ignore `--json`** even if `JSON=1` | JSON help; hang |
| 2 | Not interactive (`TTY=0`) and `JSON=0` | **Human help screen** — `app_help` (not JSON) | Menu; silent return; hang |
| 3 | Not interactive (`TTY=0`) and `JSON=1` | **JSON help** — `app_help` in JSON mode | Menu; human banners; hang |

`--quiet` without a TTY still takes the **help screen** path (do not swallow `menu` help).

### 2.3 Main menu

1. Print a **numbered list** of **daily auth work** plus one **family** row, then **Exit**.  
2. **MUST NOT** list **install / setup**, **self-managed** commands (`install`, `uninstall`, `where-is-me`), **diagnostics** (`version`, `about`), or **test-purpose** verbs.  
3. Command-row text **MUST** be `command: what it does`.  
4. **MUST NOT** list `help`, `restore`, `menu`/`main`, or the five sudoers verbs on the **main** list (they live on the submenu).  
5. Main command rows **N = 4** (three verbs + one family). Exit **MUST** be **9**. Unused integers **5–8** are omitted.  
6. Accept a **number** or a **listed verb**. **9** / `exit` / `quit` returns 0.  
7. **`sudoers` is not a live CLI command.** Choosing **4** or typing `sudoers` at the pick prompt **MUST** open the submenu (§2.4). `grok-cli sudoers` **MUST** remain unknown.  
8. Typing a submenu verb at the **main** pick prompt **MAY** run that handler (shortcut). Live verbs excluded from both lists **MUST NOT** run from the pick prompt.

Normative **main** order:

| # | Token | Label |
|---|-------|-------|
| 1 | `check-session` | `check-session: Confirm grok is logged in` |
| 2 | `backup` | `backup: Push ~/.grok/auth.* to /var/grok-cli` |
| 3 | `sync-auth` | `sync-auth: Copy /var/grok-cli/auth.* into ~/.grok` |
| 4 | family `sudoers` | `sudoers: Grant and drafts` |
| **9** | **Exit** | leave the menu |

### 2.4 Sudoers submenu

Choosing main **4** / `sudoers` **MUST** print a second numbered list of the grouped live verbs. **MUST NOT** hang off-TTY (submenu exists only on the interactive menu path).

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
| **Case** | **3** (zero-argument REQ exists; not online-installable) |
| **Empty argv** | Type N help — `requirement-shell-cli-zero-arguments` (not this file) |
| **Verb** | `menu` (alias `main`) |
| **Handler** | `app_default` (`menu` / `main`); submenu printer/loop under the same `app_default_*` family |
| **Family row** | `sudoers` — menu-only; **not** dispatched |
| **Label source** | `reviews/cli-routed-verb-table.md` **human-readable** for command rows; family explain is this file’s table |
| **Interactive + `--json`** | Ignore json; still the menu |
| **Non-interactive** | `app_help` (human; `--quiet` still prints help) |
| **Honesty** | **Implemented.** Empty argv still prints help (case 3). Main **N = 4**; submenu **N = 5**; Exit **9**; Back **8**. |

### 2.6 Why this requirement exists (CIAO)

- **Intentional**: Daily auth work is the start list; grant/draft commands are one extra pick.  
- **Caution**: Scripts never hang; `--json` on a real terminal does not hide the list.  
- **Anti-fragile**: Back returns to the start list; Exit leaves from either screen.  
- **Over-protect**: `sudoers` is not a live dispatcher token; install / version / about / `help` / `restore` stay off both lists; Exit is **9**, not **5**.

---

## 3. Design Principles

- The start list is **daily work**, not a reprint of `help`.  
- Related rare commands share one family row.  
- Dispatcher remains routing SSOT (`sudoers` is not added there).  
- Fail closed off-TTY.  
- Zero-arguments owns `grok-cli` with no command.

---

## 4. Protection Rule (Sacred)

Future agents **MUST NOT**:

1. Put `install`, `uninstall`, `where-is-me`, `version`, `about`, `help`, `menu`/`main`, or `restore` on the main list or the sudoers submenu.  
2. Put the five sudoers verbs on the **main** list.  
3. Drop a grouped sudoers verb from the submenu.  
4. Number main Exit as **5** or submenu Exit as **6** (Exit **MUST** be **9**; Back **MUST** be **8** on the submenu).  
5. Wire `sudoers` as a live `app_main` command.  
6. Steal empty argv for this menu.  
7. Hang off-TTY on `menu` / `main`.  
8. Invent command-row labels that are not `command: what it does`.

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-07** | `tests/test_cli.sh` | have (empty argv still help) |
| **TP-CLI-13** | `tests/test_cli.sh` | have (main list, family row, submenu Back/Exit, off-TTY help) |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

---

**Last Updated**: 2026-08-23 (1.6.0 — daily-work main list; sudoers family + submenu; Exit 9; Back 8)  
**Owner**: product  
**Alignment**: `requirement-shell-cli-zero-arguments` · `requirement-shell-cli-interface` · `requirement-shell-interactive-vs-noninteractive` · `requirement-domain-grok-cli` (no `restore`) · CIAO / CIAO-Lite
