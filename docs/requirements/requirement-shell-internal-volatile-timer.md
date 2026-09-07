**file**: docs/requirements/requirement-shell-internal-volatile-timer.md  
**Status**: Active (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-internal-volatile-timer`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is grok-cli’s **internal-timer (volatile)** law: process-scoped named stage stopwatches that measure how long **this product’s own** work took (menu paint steps, handlers). It specializes the sibling **timer** product’s start / stop / status / elapsed / kill / reset / list / named-identity / fail-closed contracts as **in-process helpers**, not as a second user domain.

This is **not** a user-facing named-timer CLI (`grok-cli start work`). Domain SSOT stays `requirement-domain-grok-cli`. Persistence (`--persist`, timer files) is **out of scope**.

### 1.1 Human-facing

**In one sentence:** with `--debug`, the numbered start list prints how many seconds each paint step took; that clock dies when the process ends.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | See `[DEBUG] menu step session: elapsed …` while the list paints | `grok-cli --debug menu` |
| The other role | Helpers start and stop named stages | not `grok-cli start` |
| Not this file | Sibling `timer start work` / `--persist` files | out of scope |

| Includes | Excludes |
|----------|----------|
| Named in-process start/stop/status/elapsed/kill/reset/list; debug elapsed of each menu step | `grok-cli start` / `stop` catalog; durable timer files |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/grok-cli` | ship unit | `util_int_timer_*` |
| `grok-cli --debug menu` | TTY list | elapsed of each paint step |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Find which menu step waits | Each paint step prints start, then elapsed seconds, on stderr | `grok-cli --debug menu` |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Mode

1. **MUST** implement **internal-timer** mode **volatile only** (process-scoped; lost on process exit).  
2. **MUST NOT** claim persistent / durable timer state under this requirement.  
3. **MUST NOT** require a storage, temp-file-system, or second domain CLI peer solely for this timer.  
4. **MUST NOT** write timer epoch files under `/dev/shm`, cache, or persistence.

### 2.2 Lifecycle API (helpers — not user domain verbs)

Named-stage helpers **MUST** exist under prefix `util_int_timer_*`. They **MUST** be called **bare** (not only under `$()`), so process state clears in this shell.

| Operation | Required behavior | Failure preference |
|-----------|-------------------|--------------------|
| **start** `[name]` | Record start epoch (`date +%s`); mark that name running | already running → fail closed (return non-zero; no silent overwrite) |
| **stop** `[name]` | Compute elapsed; clear that name; store last elapsed | not running → fail closed; last elapsed `0` |
| **status** / **elapsed** `[name]` | Report elapsed **without** clearing | not running → fail closed; last elapsed `0` |
| **reset** / **kill** `[name]` | Clear without a success elapsed | not running → fail closed |
| **list** | Enumerate running names (empty list is success) | — |

5. Default name when omitted or empty after sanitize: **`default`**.  
6. Distinct valid names **MUST** be independent concurrent timers in this process (so an outer `paint` timer may run while `header` runs).  
7. **MUST NOT** register these helpers as product domain commands (`grok-cli start`, `stop`, `status`, `list`, `kill`, `reset` as timer verbs).  
8. Stage ids **MUST** reject path traversal and map delimiters (`/`, `\\`, `..`, `=`, newline, spaces, shell metas). Invalid name → fail closed (return non-zero; debug log only; **MUST NOT** `exit` the CLI).  
9. Elapsed arithmetic **MUST** expose total seconds plus minutes and remaining seconds (same family as sibling timer `stop` / `status`).  
10. Clock unreadable (`date +%s` fails) → fail closed.

### 2.3 State (volatile)

11. Holding place: shell globals in this process (`UTIL_INT_TIMER_MAP` newline `name=epoch` records).  
12. **MUST NOT** use install-staging `mktemp` temps as the timer state SSOT.  
13. **MUST NOT** invent JSON domain types (`list` / `status` objects) for these helpers.

### 2.4 Debug mode and the numbered menu

14. `--debug` / `DEBUG=1` **MUST** enable elapsed reporting through `out_debug` (stderr). Dual mention: `requirement-shell-cli-interface` owns flag parse; this file owns timer semantics; `requirement-shell-cli-default-interaction` owns which menu steps are timed.  
15. When `DEBUG=1`, painting the TTY numbered list **MUST** start a named timer at the beginning of each paint step, print `menu step {{name}}: start`, then stop and print `menu step {{name}}: elapsed {{N}}s ({{M}} min {{S}} sec)`.  
16. When `DEBUG=0`, **MUST NOT** print those lines. Helpers **MAY** no-op the debug wrappers (do not slow the menu with extra work).  
17. Debug wrappers **MUST NOT** fail the menu: already-running → reset then start; stop without start → print elapsed `0s`.  
18. `--json` **MUST NOT** put `[DEBUG]` / elapsed banners on stdout (`out_debug` already suppressed under JSON).  
19. **MUST NOT** put elapsed text on numbered choice rows (that would change the list labels).

Normative **main-menu** stage names (stable):

| Stage | What it times |
|-------|----------------|
| `paint` | Whole `app_default_print_menu` body (outer; concurrent with inner names) |
| `header` | Title line |
| `session` | Session word + **logged in** / **logged out** |
| `host` | This-login-only not-available line (including the detect) |
| `logged-in` | Logged-in not-available line |
| `rows` | Token list + numbered choices + Exit **9** |

Normative **sudoers-submenu** stage names:

| Stage | What it times |
|-------|----------------|
| `sudoers.paint` | Whole submenu printer |
| `sudoers.header` | Submenu title |
| `sudoers.rows` | Numbered submenu rows |

### 2.5 Implementation Notes (this project)

| Field | Value |
|-------|--------|
| **APP_NAME** | `grok-cli` |
| **Ship unit** | `src/grok-cli` |
| **Timer kind** | internal-timer, **volatile only** |
| **Helper prefix** | `util_int_timer_*` |
| **Epoch source** | `date +%s` (wall-clock seconds) |
| **State** | `UTIL_INT_TIMER_MAP` in this process; last elapsed in `UTIL_INT_TIMER_LAST_ELAPSED` |
| **Double-start** | `util_int_timer_start` returns 1; menu debug wrapper resets then starts |
| **Stop without start** | last elapsed `0`; start helper does not `exit` |
| **Human report** | `out_debug` only (`[DEBUG] menu step …`); suppressed when `DEBUG=0` or `JSON=1` |
| **JSON report** | none (no domain timer objects) |
| **Domain timer CLI** | **not** claimed |
| **Persistence** | **not** claimed |
| **Sibling origin** | specialize from sibling **timer** named-timer contracts; **do not** write that sibling |
| **Worked invocation** | `grok-cli --debug menu` |

### 2.6 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional**: Wait-time debug is a named internal stopwatch, not an accidental `time` wrap.  
- **CIAO Principle 5 – SSOT of output**: Elapsed goes through `out_debug`.  
- **CIAO Principle 1 – Caution**: Fail-closed on double-start / bad names; menu still paints if a helper fails.  
- **CIAO Principle 3 – Anti-fragile**: Volatile in-process state needs no storage peer.  
- **CIAO Principle 16 – Interactive vs non-interactive**: Debug lines must not hang the menu or a pipe.

## Under command line for normal user only

When grok-cli runs on Termux, Git Bash, Windows cmd, or the same class (this login only — no root, no dedicated system account):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** only | Enable **admin privilege** (`sudo`, write `/etc`) or a **dedicated system user** |
| Treat admin-privilege and dedicated-account work as **unused** | Wrap `apt` / `dnf` / `yum`; `useradd`; recommend `sudo curl \| sh` |
| Termux: `pkg` as this login stays ordinary-user work | Recommend `sudo curl \| sh` as the install path |
| Git Bash and Windows cmd: same ceiling | Invoke Termux `pkg` because those hosts were detected |

Detect: Termux — `uname` contains Android, or `PREFIX` / `TERMUX_VERSION` is set. Git Bash — `MSYSTEM` or `uname -s` is MINGW*/MSYS*. Windows cmd — `OS=Windows_NT` after excluding Git Bash, Cygwin, and WSL.

**This requirement:** elapsed clock only. `--debug menu` **MUST** still print per-step elapsed on this class so a Termux wait can be named. This file does not wrap `sudo` or `apt`.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Do not silently overwrite a running named stage.  
- **Intentional**: Helpers are not domain verbs; debug elapsed is for wait-time diagnosis.  
- **Anti-fragile**: No mandatory durable store; nested named stages allowed.  
- **Over-protect**: Subshell mutation documented; stop must be a bare call; menu wrappers never abort the list.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Turn `util_int_timer_*` into user domain timer verbs without a new domain SSOT and CLI/storage/temp peers.  
2. Claim persistence / `--persist` / epoch files under this volatile-only requirement.  
3. Require storage / CLI / temp REQs solely for this timer.  
4. Silently overwrite an already-running named stage in `util_int_timer_start`.  
5. Print menu-step elapsed when `DEBUG=0`, or put `[DEBUG]` on JSON stdout.  
6. Put elapsed text onto numbered choice rows.  
7. Fail the numbered menu because a debug timer helper returned non-zero.  
8. Reverse-copy grok-cli timer helpers onto sibling **timer**.  
9. Drop `--debug` menu elapsed without explicit redesign of wait-time diagnosis.

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Named start/stop/status/elapsed/kill/reset/list helpers exist and are process-scoped |
| AC-2 | `grok-cli --debug menu` prints start + elapsed for each normative main-menu stage |
| AC-3 | Without `--debug`, those lines are absent |
| AC-4 | `--json --debug version` stdout stays JSON (no `[DEBUG]`) |
| AC-5 | Help still lists `--debug`; no `start`/`stop` timer verbs in help |
| AC-6 | Double-start on `util_int_timer_start` is fail-closed |

## 6. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-25** | `tests/test_cli.sh` | have (`--debug menu` elapsed of each paint step, including `sudoers.*`) |
| **TP-CLI-26** | `tests/test_cli.sh` | have (no `--debug` → no menu-step elapsed lines) |
| **TP-CLI-27** | `tests/test_cli.sh` | have (`--json --debug version` stdout JSON-pure) |
| **TP-CLI-28** | `tests/test_cli.sh` | have (`util_int_timer_*` present; AC-6 double-start fail-closed; invalid names rejected; help `--debug`; no timer `start` verb) |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## 7. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention of `--debug` |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Which menu steps are timed |
| `docs/requirements/requirement-shell-output-requirements.md` | `out_debug` channel |
| `docs/requirements/requirement-shell-modular-function-design.md` | `util_*` prefix |
| `docs/requirements/requirement-domain-grok-cli.md` | Domain SSOT — not a timer catalog |
| `./src/grok-cli` | Ship unit under test |

## 8. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-09-07 | Active 1.0.0 | Specialize sibling timer contracts as volatile named internal stages; `--debug` menu elapsed |

**Last Updated**: 2026-09-07  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
