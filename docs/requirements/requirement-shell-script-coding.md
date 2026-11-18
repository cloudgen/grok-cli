**file**: docs/requirements/requirement-shell-script-coding.md  
**Status**: Active (Version 1.2.2)  
**Area**: shell  
**Key**: `requirement-shell-script-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **product Single Source of Truth** for **POSIX `/bin/sh` coding style** of grok-cli: `set -u`, explicit errors, no `set -e` as the only handler, prefixes, and fail-closed elevation. Without this file, portable shell lessons would arrive **raw**.

**Termux / Android host writing** is **not** duplicated here — **`requirement-shell-termux-coding`** owns detect/`PREFIX`/`pkg`/`noexec`/FHS-not-assumed. This file **points**. Skipping that peer because “this change is not on a phone” is pain **PP-A-21**.

### 1.1 Human-facing

This file says how grok-cli’s ship unit must be written: one `/bin/sh` file, `out_*` for messages, `gc_*` for grok auth, never a silent success.

| You | Another role | Not this |
|-----|--------------|----------|
| Read prefixes and `set -u` rules when changing `src/grok-cli` | Modular-function REQ owns the prefix table SSOT | Python/Node style; online-install coding |

**Includes:** interpreter, unset handling, no raw product `echo`, and the `util_uname` wrapper. `--uname-s WORD` and `--uname-a WORD` are the well-known test-purpose switches. **Excludes:** grant JSON schema; Termux `PREFIX`/`pkg`/`noexec` writing (`requirement-shell-termux-coding`); which download Android versus Git Bash selects (`requirement-grok-setup`); the test-purpose verb `rc-test` (`requirement-shell-path-and-shell-support`); `--debug` elapsed (`requirement-shell-internal-volatile-timer`).

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Edit the CLI | Follow `out_*` / `gc_*` / `set -u` | Open `src/grok-cli` |

---

## 2. Core Rules (Mandatory)

1. **MUST** ship as POSIX `/bin/sh` (`#!/bin/sh`), `set -u`, explicit `out_die` (not global `set -e`).  
2. **MUST** use defined prefixes (`out_`, `inst_`, `util_`, `app_`, `gc_`, `prompt_`).  
3. **MUST NOT** print product messages with raw `echo`/`printf` outside `out_*`.  
4. **MUST** measure `[ -t 0 ]` / `[ -t 1 ]` for TTY **outside** functions; helpers consume `TTY`.  
4b. **MUST NOT** `_x=$(prompt_ask …)` / `$()` `prompt_yes_no` / `$()` any function that contains `read`. Call in the current shell; `prompt_ask` assigns `PROMPT_ASK_VALUE` (INC-20260902-001; **TP-ELEV-10** / TP-CLI-15).  
5. **MUST NOT** use `sudo -n true` as the only elevation proof. Passwordless elev is the grant `sudo -n {{GLOBAL_BIN}}/grok-cli backup`.  
6. **MUST** fail closed on missing session, missing grant, or unreadable store.  
7. Temps **MUST** use `mktemp` under storage `TMPDIR`, not `$$` names.  
8. **Termux / Android (own-or-point):** host-writing rules **MUST** follow **`requirement-shell-termux-coding`** (detect Android; honor `PREFIX`; Termux `pkg` never sudo; do not exec from cache/`/tmp`/`/dev/shm`; do not assume `/usr/local/bin` or `/var`). Remainder of this POSIX file stays in force. **MUST NOT** skip that peer because the current diff is not on a phone (**PP-A-21**).
9. **uname wrapper:** every product read of a `uname` result **MUST** call `util_uname` with the same flag (`-s`, `-a`, `-m`, `-o`, `-r`, or none). **MUST NOT** invoke the `uname` binary anywhere else in the ship unit. The setup existence check `command -v uname` **MAY** stay; it does not run `uname`. Test injection is §2.3. Platform meaning stays on `requirement-grok-setup`. Cache-kind meaning stays on `requirement-shell-cli-storage`.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Ship unit | `src/grok-cli` |
| Interpreter | `/bin/sh` |
| Domain prefix | `gc_` |
| Version SSOT | `VERSION=` hard-assign in `src/grok-cli` (do not pin a stale number here) |
| Host read | `util_uname` (rule 9). Real `uname` only inside that function |

### 2.2 Why This Requirement Exists (CIAO)

- **Principle 2 – Intentional**: Style is law so later hops do not dump raw lessons.  
- **Principle 5 – Output SSOT**: `out_*` only.  
- **Principle 16 – Interactive**: TTY measured outside functions.

### 2.3 Well-known test-purpose switches `--uname-s` and `--uname-a`

`util_uname` is the only host read. Tests that need another machine’s answer pass these well-known test-purpose switches. They do not plant a PATH file named `uname`.

| Switch | What `util_uname` prints |
|--------|--------------------------|
| `--uname-s WORD` | the injected `uname -s` line |
| `--uname-a WORD` | the injected `uname -a` line |

1. `app_main` **MUST** parse both switches **before** `util_resolve_storage`, so cache kind sees `--uname-s`. The switch may sit before or after the verb: `grok-cli --uname-s MINGW64_NT-10.0 setup` and `grok-cli setup --uname-s MINGW64_NT-10.0` are the same injection.
2. `WORD` is the next argv field, one field. A line with spaces is quoted by the caller: `--uname-a "Linux localhost 0.0 x86_64 Android"`.
3. A missing `WORD`, an empty `WORD`, or a `WORD` that starts with `-` **MUST** `out_die`. The text names the switch and includes `Next:`.
4. `WORD` is data. **MUST NOT** `eval` it, pass it to `sh -c`, or splice it into a command string.
5. With the switch absent, `util_uname` runs the real `uname` with the same arguments and returns that text.
6. `-m`, `-o`, `-r`, and a call with no flag **always** run the real `uname`. There is no `--uname-m`, `--uname-o`, or `--uname-r`.
7. `GROK_CLI_CACHE_HOST` still wins over an injected `-s` for cache kind only (`requirement-shell-cli-storage`). Platform detection and Git Bash detection use the injected `-s`.
8. Android detection stays the substring `Android` on the combined `uname -a` and `uname -o` text (`requirement-shell-termux-coding`). A test injects that substring with `--uname-a`. It does not replace `uname -o`.
9. Human help lists both switches under the test-purpose heading, apart from operational verbs. JSON help names the switches and does not print a sample host line as a command. Dual mention: `requirement-shell-cli-interface`.
10. The operand is not a command token. `grok-cli --uname-s Linux` with no verb is still empty argv (`requirement-shell-cli-zero-arguments`).
11. A test that needs a foreign `uname -s` or `uname -a` **MUST** pass these switches. **MUST NOT** create, replace, or chmod a PATH file whose basename is `uname`.
12. These two switches are the well-known test-purpose switches for any command. The well-known test-purpose verb is `rc-test` (`requirement-shell-path-and-shell-support`).

| Token | Class |
|-------|--------|
| `--uname-s WORD` | Well-known test-purpose switch. Overlays the `uname -s` line for this run |
| `--uname-a WORD` | Well-known test-purpose switch. Overlays the `uname -a` line for this run |
| `rc-test` | Well-known test-purpose verb. Its switches live on `requirement-shell-path-and-shell-support` |
| `--debug` | Global diagnostic switch. No operand. Elapsed text is `requirement-shell-internal-volatile-timer` |
| `HOME` | Login-home environment variable, set before start |
| `GROK_HOME` | Grok directory override. Default `$HOME/.grok` |
| `GROK_CLI_ROOT` | Durable store. Default `/var/grok-cli` |
| `--allow-test-local` | Global test-mode flag |

Sample:

```sh
grok-cli --uname-s MINGW64_NT-10.0 setup
grok-cli --uname-a "Linux localhost 0.0 x86_64 Android" setup
grok-cli --json setup --uname-s MINGW64_NT-10.0
grok-cli --uname-s Linux
grok-cli rc-test --rc-root "$tmpdir" --rc bashrc --case create
grok-cli --debug menu
```

The first three lines inject a host line. `grok-cli --uname-s Linux` has no verb, so it is empty argv. `rc-test` is the test-purpose verb on a throw-away folder. `--debug menu` turns on diagnostics.

---

## Under command line for normal user only

When grok-cli runs on Termux, Git Bash, Windows cmd, or the same class (this login only — no root, no dedicated system account):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** only | Enable **admin privilege** (`sudo`, write `/etc`) or a **dedicated system user** |
| Treat admin-privilege and dedicated-account work as **unused** | Wrap `apt` / `dnf` / `yum`; `useradd`; recommend `sudo curl \| sh` |
| Termux: `pkg` as this login stays ordinary-user work | Recommend `sudo curl \| sh` as the install path |
| Git Bash and Windows cmd: same ceiling | Invoke Termux `pkg` because those hosts were detected |

Detect: Termux — `util_uname -a` / `util_uname -o` contains Android, or `PREFIX` / `TERMUX_VERSION` is set. Git Bash — `MSYSTEM` or `util_uname -s` is MINGW*/MSYS*. Windows cmd — `OS=Windows_NT` after excluding Git Bash, Cygwin, and WSL. Those `uname` reads go through `util_uname` (rule 9).

**This requirement:** fail-closed elevation helpers stay **unused** on this class. Do not implement a sudo ladder here.

---

## 3. Design Principles

- **Caution:** Assume unset HOME and missing sudo.  
- **Intentional:** One ship unit.  
- **Anti-fragile:** Isolated tests.  
- **Over-protect:** Fail closed; no OS-tool sudoers.

---

## 4. Protection Rule

**MUST NOT** add `set -e` as the only error policy, drop prefixes, treat coding skills as product law in place of this file, capture `prompt_ask` / `read` helpers with `$()`, fold Termux `PREFIX`/`pkg`/`noexec` bodies into this file instead of pointing at `requirement-shell-termux-coding`, strip the **Under command line for normal user only** section, call the `uname` binary outside `util_uname`, eval a `--uname-s` / `--uname-a` operand, add `--uname-m` / `--uname-o` / `--uname-r`, satisfy an Android or Git Bash test by creating a PATH file named `uname`, or class `--debug`, `HOME`, `GROK_HOME`, `GROK_CLI_ROOT`, or `--allow-test-local` as a test-purpose switch.

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | `sh -n src/grok-cli` passes (TP-CLI-01) |
| AC-2 | `set -u` survives unset HOME (TP-CLI-11) |
| AC-3 | Domain functions use `gc_` |
| AC-4 | Ship unit has no `$(prompt_ask` / `$(prompt_yes_no` (TP-CLI-15) |
| AC-5 | Termux host writing is pointed at `requirement-shell-termux-coding` (not duplicated here) |
| AC-6 | With neither switch, host reads go through `util_uname` and match this host’s real `uname -s` / `uname -m` (TP-UNAME-01) |
| AC-7 | `--uname-s MINGW64_NT-10.0` selects the `windows-*` setup artifact on a Linux host, and the test does not create a file named `uname` (TP-UNAME-02) |
| AC-8 | `--uname-a` text that contains `Android` takes the Android setup branch on a non-Android host (TP-UNAME-03) |
| AC-9 | A missing, empty, or dash-leading operand of `--uname-s` or `--uname-a` dies with `Next:` (TP-UNAME-04) |

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-01**, **TP-CLI-11**, **TP-CLI-15** | `tests/test_cli.sh` | have |
| **TP-VCLI-15**, **TP-VCLI-19**–**25** | `tests/test_grok_setup.sh` | have — Termux slice (`requirement-shell-termux-coding`) |
| **TP-UNAME-01** .. **TP-UNAME-04** | `tests/test_grok_setup.sh` | have — switches wired; tests do not plant a PATH file named `uname` |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-termux-coding.md` | Termux/Android host writing (pointed from rule 8) |
| `docs/requirements/requirement-shell-modular-function-design.md` | Prefix table |
| `./src/grok-cli` | Implementation (`util_uname`) |
| `docs/requirements/requirement-shell-cli-interface.md` | Lists `--uname-s` / `--uname-a`; behavior is this file |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Operand is not a command token |
| `docs/requirements/requirement-grok-setup.md` | What an injected `-s` / `-a` selects |
| `docs/requirements/requirement-shell-cli-storage.md` | Cache kind; `GROK_CLI_CACHE_HOST` still wins |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-11-17 | Active 1.2.0 | `util_uname`; `--uname-s` / `--uname-a` inject `uname -s` / `uname -a` |
| 2026-11-18 | Active 1.2.1 | Those two switches are the well-known test-purpose switches; fenced sample; `--debug`, `HOME`, and `GROK_HOME` stay in their own classes |
| 2026-11-18 | Active 1.2.2 | Sample of `rc-test` uses `--rc-root` and `--rc` |

**Last Updated**: 2026-11-18  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
