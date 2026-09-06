**file**: docs/requirements/requirement-shell-termux-coding.md  
**Status**: Active (Version 1.1.0)  
**Area**: shell  
**Key**: `requirement-shell-termux-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **product Single Source of Truth** for **how grok-cli is written** when the host is **Termux / Android userspace**. It owns host-writing rules: detect Android, honor `PREFIX`, use Termux `pkg` (never sudo), do not exec from `noexec` mounts, and do not assume a Linux FHS tree.

This is **not** a second language coding-style file. POSIX `/bin/sh` style (`set -u`, prefixes, `out_*`) stays on **`requirement-shell-script-coding`**, which **points** here for the Termux/Android slice. Without this file, later verbs would copy Ubuntu paths (`/usr/local/bin`, `apt`, `/tmp` as exec) and break on a phone.

**Own-or-point:**

| Slice | Owner |
|-------|--------|
| POSIX writing (`set -u`, prefixes, no `$()` of `read`) | `requirement-shell-script-coding` |
| Path **classes** (PREFIX tree, `~/.grok`, bins, deposit) | `requirement-project-folder` |
| Cache vs persistence resolvers | `requirement-shell-cli-storage` |
| grok-cli checkout `install` dest | `requirement-shell-local-self-management` |
| `setup` procedure (channel, artifact, wrapper, `pkg install proot`, resolv bind) | `requirement-grok-setup` |
| `/var/grok-cli` deposit + **session procedure** (`grok -p hello`) | `requirement-grok-auth-backup` |
| **This file** | How every CLI path **must be written** so those peers still work on Termux |

### 1.1 Human-facing

**In one sentence:** when you change the grok-cli program file, write it so a Termux phone still works — use `$PREFIX`, install extra tools with `pkg` (never sudo), and run downloaded programs from `~/.grok/downloads`, not from `/tmp`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Maintainer editing `src/grok-cli`; operator on a phone running `setup` | `grok-cli setup` on Termux aarch64 |
| The other role | Termux supplies `PREFIX`, `pkg`, and `termux-exec`; xAI supplies the grok binary | `${PREFIX}/bin/pkg` · `~/.grok/bin/grok` |
| Not this file | xAI download steps; JSON sudoer grant; language prefixes | `requirement-grok-setup` · `requirement-sudoer-json-file` · `requirement-shell-script-coding` |

| Includes | Excludes |
|----------|----------|
| Detect Android; honor `PREFIX`; Termux `pkg` rules; `noexec` exec paths; FHS-not-assumed; `LD_PRELOAD` / `TERMUX_EXEC_OPTOUT`; one Android detect helper | Channel URLs and artifact names (`requirement-grok-setup`); cache resolver shapes (`requirement-shell-cli-storage`); grant JSON; `out_*` catalog |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/grok-cli` | program file people install | live Termux helpers |
| `grok-cli setup` | command on the phone | `pkg` / wrapper / resolv bind |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Add a helper that runs a downloaded file | Do not `chmod +x` something only under `/tmp` or the cache folder — those mounts often refuse exec on Termux. Smoke from `~/.grok/downloads`. | Edit `src/grok-cli`; run `grok-cli setup` |
| Need a Termux package | Call `pkg install -y` as this login (stdin closed). Do not `sudo pkg`. Do not call `pkg` on a Linux laptop. | `grok-cli setup` (installs `proot` when needed) |

Jargon: you run these commands **as yourself** on the phone. Shared `/var/grok-cli` backup still needs a Linux host with sudo — this file does not invent a Termux substitute for that folder.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Detect Termux / Android

1. **MUST** treat the host as Android/Termux when `uname -a` or `uname -o` contains `Android`.  
2. **MUST** treat `PREFIX` as the Termux prefix **when it is set** (directory that holds `bin/`, `etc/`). **MUST NOT** hard-code `/data/data/com.termux/files/usr` (or any other session device path) in the ship unit or in this file’s Implementation Notes as the only prefix.  
3. **MUST** keep **one** Android detect helper in the ship unit (today `gc_setup_host_is_android`). New verbs **MUST** reuse it (or a single `util_*` successor). **MUST NOT** copy a second `uname` Android check.  
4. **MUST NOT** treat “`pkg` is on PATH” alone as Termux — FreeBSD `pkg` is a different tool (rule 2.3).

### 2.2 Special folder structure (refer; path-class SSOT is `requirement-project-folder`)

Writers **MUST** use these classes. Exact default strings live on **`requirement-project-folder`**.

| Class | Termux / Android | Linux FHS peer (do not assume on Termux) |
|-------|------------------|------------------------------------------|
| Prefix root | `${PREFIX}` when set | `/usr` |
| Package + PATH bin | `${PREFIX}/bin` | `/usr/bin` and `/usr/local/bin` |
| Termux etc | `${PREFIX}/etc` (resolv often lives here) | `/etc` |
| Login home | `${HOME}` (Termux app home) | `${HOME}` |
| Peer grok home | `{{GROK_HOME}}` default `${HOME}/.grok` | same shape |
| Exec-capable download | `{{GROK_HOME}}/downloads` | same — **this** is the smoke dir |
| Peer grok on PATH | `{{GROK_HOME}}/bin` plus a writable PATH dir (`USER_BIN`, `GLOBAL_BIN`, `${PREFIX}/bin`) | `USER_BIN` then `GLOBAL_BIN` |
| grok-cli user bin | `${HOME}/.local/bin` (`USER_BIN`) | same |
| grok-cli global bin | `${GLOBAL_BIN}` default `/usr/local/bin` — **often missing** | `/usr/local/bin` |
| Cache / tmp | `/dev/shm`, `/tmp` — often **`noexec`** | often exec |
| Shared auth deposit | `/var/grok-cli` — **often absent** (no root) | `/var/grok-cli` |
| Host resolv probe | `/etc/resolv.conf` often missing or has **no** `nameserver` | usual glibc resolv |

Rules:

5. **MUST NOT** hard-code the Termux app-files root (`/data/data/com.termux/…`) as a product path.  
6. **MUST NOT** treat missing `/usr/local/bin`, `/var`, or `/etc/resolv.conf` as a programming error when the verb does not need them.  
7. **MUST NOT** invent a Termux-local substitute for `/var/grok-cli` (or for host sudoers under `/etc`) without a new Active requirement. On a phone without root, `backup` **MUST** fail closed per `requirement-grok-auth-backup` (honest Next).  
8. grok-cli **install** dest **MUST** stay `USER_BIN` for a normal (non-root) login — **MUST NOT** retarget grok-cli into `${PREFIX}/bin` as if it were a Termux package. `${PREFIX}/bin` is a **PATH candidate** for the peer `grok` link (`requirement-grok-setup`) and for `pkg` / `proot`.

### 2.3 Special installations (refer; `setup` procedure SSOT is `requirement-grok-setup`)

9. Extra Termux packages **MUST** use Termux **`pkg`**: `${PREFIX}/bin/pkg` when `PREFIX` is set and that path is executable, else `command -v pkg`.  
10. **MUST** run `pkg install -y {{package}}` with stdin closed and `DEBIAN_FRONTEND=noninteractive`. **MUST NOT** `sudo pkg`. **MUST NOT** hang under `--json` / off-TTY waiting for a `pkg` prompt.  
11. **MUST NOT** run `pkg` or `apt` when `uname` is not Android.  
12. **MUST NOT** `pkg upgrade`, and **MUST NOT** install packages this product’s law does not name. Named package today: **`proot`** (only when `requirement-grok-setup` rule 18d / 21b applies).  
13. A failed `pkg install` **MUST NOT** be a silent success. Follow the owning verb’s error table (`setup`: WARN then the `pkg install proot` Next).  
14. Core tests **MUST** fake `pkg` / `proot` / Android `uname`. **MUST NOT** hit packages.termux.org from Core tests.

### 2.4 Exec, linker, and `noexec` (writing rules)

15. Shebang **MUST** stay `#!/bin/sh`. Termux’s exec interceptor rewrites `/bin/sh` to `${PREFIX}/bin/sh`. **MUST NOT** require `bash`.  
16. **MUST NOT** smoke or `exec` a newly placed binary from the cache folder, `/tmp`, or `/dev/shm` — those mounts are often `noexec` on Termux/Android. Smoke path for peer grok: `{{GROK_HOME}}/downloads` (`requirement-grok-setup`).  
17. Execute-bit-on **MUST NOT** mean “runs on this host.” Probe success is a successful `--version` (or the owning verb’s equivalent) **on this host**. Wrong ELF `e_machine` (x86_64 file on aarch64 Termux) is not installed.  
18. On Android, after a direct exec of a static Linux `ET_EXEC` fails, writers **MUST** follow `requirement-grok-setup` 18c–18d / 21b (opt-out, `pkg` `proot`, wrapper, resolv bind). **MUST NOT** byte-patch vendor ELF (`e_type` or the `/etc/resolv.conf` string).  
19. When execing that vendor file or `proot`, **MUST** unset `LD_PRELOAD` and set `TERMUX_EXEC_OPTOUT=1` for that exec, then restore. **MUST NOT** leave `LD_PRELOAD` cleared for the rest of the CLI.  
20. **MUST NOT** run `proot` against the vendor grok while Termux `LD_PRELOAD` (libtermux-exec) is still set.

### 2.4b Session probe (writing rules; procedure SSOT is `requirement-grok-auth-backup`)

A credential file on the phone can look valid while grok cannot reach `auth.x.ai` (no nameserver, wrapper missing, `ET_EXEC`). Writers **MUST** exec the **resolved peer** (`{{GROK_HOME}}/bin/grok` wrapper when that is what `setup` placed).

21b. The session probe **MUST** be `grok -p hello` with stdin closed. **MUST NOT** hang under `--json` / off-TTY / the numbered menu. When `timeout` is on PATH, **MUST** bound the probe.  
22b. **MUST** exec the path `gc_resolve_grok_peer` returns (the POSIX wrapper when setup wrote one). **MUST NOT** smoke `grok -p hello` from cache/`/tmp`/`/dev/shm`.  
23b. **MUST NOT** print grok’s answer. Core tests **MUST** fake `GROK_BIN` (no xAI).  
24b. A `dns error` from the probe is a **session** failure (`requirement-grok-auth-backup`), not an install failure. Next stays `grok login` (or `export XAI_API_KEY`). Do **not** invent a Termux `/var/grok-cli`.

### 2.5 PATH and bins (writing rules)

25. PATH candidates when placing a **peer grok** link: `USER_BIN` (`${HOME}/.local/bin`), then `GLOBAL_BIN` (`/usr/local/bin`), then `${PREFIX}/bin` **when `PREFIX` is set**. Skip a candidate that is missing or not writable. Missing `GLOBAL_BIN` on Termux is **not** a blocking error for a user-bin install.  
26. A PATH line written to `~/.bashrc` does **not** apply to the current session. **MUST NOT** print `[ERROR]` for that stale-PATH case when the binary is on disk (`requirement-grok-setup`).

### 2.6 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Product | `grok-cli` |
| Ship unit | `src/grok-cli` |
| Android detect | `gc_setup_host_is_android` |
| Exec interceptor off/on | `gc_setup_termux_exec_off` / `gc_setup_termux_exec_restore` |
| Termux `pkg` helper | `gc_setup_ensure_termux_proot` (named package: `proot`) |
| Prefix env | `PREFIX` (set by Termux; tests **MAY** export a fake prefix dir) |
| Peer grok home | `GROK_HOME` default `${HOME}/.grok` |
| Smoke / download dir | `${GROK_HOME}/downloads` |
| Peer bin | `${GROK_HOME}/bin/grok` (wrapper or relative symlink) |
| Resolv bind file | `${GROK_HOME}/resolv.conf` when the host probe has no `nameserver` |
| grok-cli user bin | `${HOME}/.local/bin/grok-cli` |
| grok-cli global bin | `/usr/local/bin/grok-cli` (Linux multi-user; often absent on Termux) |
| Deposit | `/var/grok-cli` — not a Termux substitute |
| Session probe | `gc_grok_prompt_hello` (`grok -p hello`; stdin closed; fake `GROK_BIN` in Core tests) |
| Core tests | `tests/test_grok_setup.sh` fakes Android `uname`, `pkg`, `proot`; `tests/test_domain_grok_cli.sh` fakes `GROK_BIN` |

**Detect helper (complete sample — live copy is the ship unit):**

```sh
gc_setup_host_is_android() {
    case "$(uname -a 2>/dev/null) $(uname -o 2>/dev/null)" in
        *Android*) return 0 ;;
    esac
    return 1
}
```

**pkg install shape (complete sample — live copy is the ship unit):**

```sh
# stdin closed; no sudo; Android only
pkg install -y proot </dev/null
```

**Forbidden (MUST NOT):**

```sh
sudo pkg install proot
apt-get install proot
pkg install -y proot          # on non-Android (FreeBSD pkg)
chmod +x /tmp/grok && /tmp/grok --version
# hard-coded Termux app-files root as the only prefix
PREFIX=/data/data/com.termux/files/usr
```

### 2.7 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Assume `/tmp` is `noexec`, `/var` is missing, and `pkg` is not apt.  
- **CIAO Principle 2 – Intentional**: Termux writing is named law, not a comment inside `setup` only.  
- **CIAO Principle 10 – Least privilege**: No sudo for Termux packages; no root-by-convenience on a phone.  
- **CIAO Principle 17 – Defensive storage**: Exec from `~/.grok/downloads`, not cache/tmp.  
- **CIAO Principle 21 – Dual policies**: Portable detect/`PREFIX` rules here; grok-cli helper names in Implementation Notes.

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

**This requirement:** this file is the Termux writing SSOT. Shared `/var/grok-cli` deposit stays **unused** on the phone.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** FHS paths are optional on Termux; fail closed when a verb truly needs them.  
- **Intentional:** One detect helper; one `pkg` policy; setup procedure stays on `requirement-grok-setup`.  
- **Anti-fragile:** Skip `pkg` when opt-out already works; fake `pkg` in Core tests.  
- **Over-protect:** Do not byte-patch vendor grok; do not invent `/var` on the phone.

---

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Treat this file as a second POSIX language coding-style REQ, or drop `requirement-shell-script-coding`.  
2. Duplicate the full `setup` channel/artifact/wrapper/resolv procedure here (that stays `requirement-grok-setup`).  
3. Hard-code `/data/data/com.termux/files/usr` (or a session device path) as the product prefix.  
4. `sudo pkg`, run `pkg`/`apt` on non-Android, or hang on a `pkg` prompt under `--json`.  
5. Smoke or exec a vendor binary only from the cache folder, `/tmp`, or `/dev/shm`.  
6. Byte-patch vendor ELF (`e_type` or `/etc/resolv.conf` string).  
7. Run `proot` while Termux `LD_PRELOAD` is still set.  
8. Retarget grok-cli `install` into `${PREFIX}/bin` as a Termux package.  
9. Invent a Termux-local `/var/grok-cli` or `/etc/sudoers.d` substitute without a new Active requirement.  
10. Copy a second Android `uname` detect instead of reusing the one helper.  
11. Hit packages.termux.org from Core tests.  
12. Require `bash` because Termux happens to ship it.  
13. Treat `auth.json` parse as logged-in on Termux without `grok -p hello` (DNS / wrapper / `ET_EXEC` would stay hidden).  
14. Hang the session probe or the numbered menu waiting for an interactive `grok login`.

15. Strip the **Under command line for normal user only** section, or enable admin privilege / a dedicated system user on Termux / Git Bash / Windows cmd.  

**Violating this rule is a critical Termux-host / install-class regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Android detect is a single helper; `uname -o`/`-a` containing `Android` is enough |
| AC-2 | `PREFIX` when set is used for `pkg`, `proot`, `${PREFIX}/bin` PATH candidate, and `${PREFIX}/etc/resolv.conf` — no hard-coded Termux app-files root |
| AC-3 | Termux `pkg install -y` is Android-only, no sudo, stdin closed; Core tests fake `pkg` |
| AC-4 | Peer grok smoke path is under `{{GROK_HOME}}/downloads`, not cache/`/tmp`/`/dev/shm` |
| AC-5 | Android ET_EXEC path uses opt-out / `proot` / wrapper without byte-patch (`requirement-grok-setup`) |
| AC-6 | grok-cli user install dest remains `USER_BIN`; missing `GLOBAL_BIN` is not a user-install failure |
| AC-7 | Ship unit shebang is `#!/bin/sh` (no bash required) |
| AC-8 | No Termux-local substitute for `/var/grok-cli` in the ship unit |
| AC-9 | Session probe is `grok -p hello` on the resolved peer, stdin closed, Core tests fake `GROK_BIN` |

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-script-coding.md` | POSIX language coding-style (points here) |
| `docs/requirements/requirement-project-folder.md` | Path classes including Termux PREFIX tree |
| `docs/requirements/requirement-grok-setup.md` | `setup` procedure (pkg/proot/wrapper/resolv) |
| `docs/requirements/requirement-shell-cli-storage.md` | Cache resolver (not an exec path) |
| `docs/requirements/requirement-shell-local-self-management.md` | grok-cli `install` dest |
| `docs/requirements/requirement-grok-auth-backup.md` | `/var/grok-cli` deposit + live session probe (no Termux substitute) |
| `./src/grok-cli` | Implementation |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-09-04 | Active (1.0.0) | Termux/Android host writing SSOT: PREFIX, pkg, noexec, FHS-not-assumed; points at setup/folder/storage |
| 2026-09-05 | Active (1.1.0) | Session probe writing: exec resolved peer `grok -p hello` (stdin closed; no hang; fake in Core tests) |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-VCLI-15**, **TP-VCLI-16** | `tests/test_grok_setup.sh` | have — smoke under `~/.grok/downloads` (not cache/`noexec` tmp) |
| **TP-VCLI-17**, **TP-VCLI-18** | `tests/test_grok_setup.sh` | have — wrong ELF / cannot-run is not already installed |
| **TP-VCLI-19**–**25** | `tests/test_grok_setup.sh` | have — Android ET_EXEC, `pkg install -y proot`, `LD_PRELOAD` unset, resolv bind |
| **TP-LC-01** | `tests/test_local_lifecycle.sh` | have — grok-cli install → `USER_BIN` (not PREFIX) |
| **TP-CLI-01** | `tests/test_cli.sh` | have — `sh -n`; shebang `/bin/sh` |
| **TP-GROK-CLI-35**–**38** | `tests/test_domain_grok_cli.sh` | have — live `grok -p hello` fake peer; no xAI; no hang |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-06  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
