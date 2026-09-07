**file**: docs/requirements/requirement-shell-termux-coding.md  
**Status**: Active (Version 1.6.0)  
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
| **This file** | How every CLI path **must be written** so those peers still work on Termux; **PRoot exit hang** writing (guest already exited; PRoot still waits) |

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
| One-shot `grok -p` under PRoot | grok already printed; PRoot did not notice. If `proot` is on PATH, use the reaper (guest death + new `runsvdir`); else the simple `grok -p hello`. | `grok-cli check-session` · `grok-cli run -p hello` |

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
18. On Android, after a direct exec of a static Linux `ET_EXEC` fails, writers **MUST** follow `requirement-grok-setup` 18c–18e / 21b (opt-out, `pkg` `proot`, wrapper, `--kill-on-exit`, `grok -p` SIGKILL, resolv bind). **MUST NOT** byte-patch vendor ELF (`e_type` or the `/etc/resolv.conf` string).  
19. When execing that vendor file or `proot`, **MUST** unset `LD_PRELOAD` and set `TERMUX_EXEC_OPTOUT=1` for that exec, then restore. **MUST NOT** leave `LD_PRELOAD` cleared for the rest of the CLI.  
20. **MUST NOT** run `proot` against the vendor grok while Termux `LD_PRELOAD` (libtermux-exec) is still set.  
20b. The Android `proot` wrapper **MUST** pass `proot --kill-on-exit` when advertised (never `-k`). For `-p` / `--single` it **MUST** pass grok `--no-auto-update` and SIGKILL the child on Ctrl-C so the operator is not stuck until Ctrl-Z. Procedure SSOT is `requirement-grok-setup` 18e. **`--kill-on-exit` is not enough** while leftover `runsvdir` stay tracees (rule 20c).

### 2.4b Session probe (writing rules; procedure SSOT is `requirement-grok-auth-backup`)

A credential file on the phone can look valid while grok cannot reach `auth.x.ai` (no nameserver, wrapper missing, `ET_EXEC`). Writers **MUST** exec the **resolved peer** (`{{GROK_HOME}}/bin/grok` wrapper when that is what `setup` placed).

21b. The session probe **MUST** be `grok -p hello` with stdin closed. **MUST NOT** hang under `--json` / off-TTY / the numbered menu. **MUST** bound the probe even when `timeout` is missing. When GNU `timeout` is on PATH, **MUST** use kill-after (`timeout -k`) so a `proot` child that ignores SIGTERM cannot freeze the menu. When that `timeout` is missing or does not support kill-after, **MUST** still bound with a POSIX watchdog (`kill` then `kill -9`). Procedure SSOT remains `requirement-grok-auth-backup`.  
21c. **Dispatch (mandatory):** if `command -v proot` succeeds, the probe **MUST** use the **PRoot reaper** path (rule 20c / sample below). If `proot` is **not** on PATH, the probe **MUST** run the **simple** `grok -p hello` (existing bounded helper). **MUST NOT** wait on the PRoot PID as the only done signal. Dual mention: `requirement-grok-auth-backup` · `requirement-domain-grok-cli`.  
22b. **MUST** exec the path `gc_resolve_grok_peer` returns (the POSIX wrapper when setup wrote one). **MUST NOT** smoke `grok -p hello` from cache/`/tmp`/`/dev/shm`.  
23b. **MUST NOT** print grok’s answer. Core tests **MUST** fake `GROK_BIN` (no xAI).  
24b. A `dns error` from the probe is a **session** failure (`requirement-grok-auth-backup`), not an install failure. Next stays `grok login` (or `export XAI_API_KEY`). Do **not** invent a Termux `/var/grok-cli`.

### 2.4c PRoot exit hang (writing rules)

On-device study (Termux aarch64, `proot` 5.1, `termux-services` + `runit`): the hang is **not** “PRoot cannot see grok exit” and **not** leftover grok helpers. `grok-linux-aarch64` **does** `_exit` after the reply. PRoot’s loop is `wait4(-1, …, __WALL)` (`wchan=do_wait`): it does not return until **every remaining tracee is dead**, including daemons that reparent to PID 1. `grok --help` never takes env-capture and **does** exit — proof PRoot can exit when it has no leftover daemons.

Causal chain (measured):

```text
grok -p hello
  → wrapper execs proot (no rootfs) over grok-linux-aarch64
    → grok-linux starts two `bash -lc` env-capture processes
      → login bash sources ${PREFIX}/etc/profile
        → profile.d/start-services.sh
          → (service-daemon start &)
            → start-stop-daemon -S -b … runsvdir ${SVDIR}
              → runsvdir double-forks, PPID=1, STILL a PRoot tracee
    → grok-linux prints the reply and _exit()s
    → proot wait4(-1, __WALL)   # leftover runsvdir still alive
```

Two login shells ⇒ two extra `runsvdir` per `grok -p`. They race the Termux pidfile and usually cannot see the already-running host `runsvdir`, so they start extras. Isolation: `proot … bash -lc` hangs the same way; `bash -c` and `bash --noprofile --norc -lc` do not. Unsetting `SVDIR` in the parent does **not** help (`start-services.sh` re-exports it).

20c. Writers **MUST** treat **guest disappearance**, **any non-empty stdout** (session probe does not print the answer), or **stderr guest-death** (empty stdout after SIGHUP / spawn panic) as done. Then: kill only **new** `runsvdir` PIDs (snapshot before start); if PRoot still will not exit, SIGKILL PRoot **immediately** (do not wait on the PRoot PID first). Print the reply from captured files even if PRoot is SIGKILL’d. **MUST NOT** require `_sz > 0` as the only idle trigger.  
20c1. The PRoot collector **MUST** run in a new session when `setsid` is on PATH. The reaper **MUST** ignore `SIGTSTP`. The parent **MUST** trap INT/TERM/TSTP around `wait` and SIGKILL the collector so Ctrl-Z cannot stop the watchdog (INC-20260907-004). **MUST** `wait` the reaper first.  
20d. Leftover discovery **MUST** match **args / exe paths** (`…/runsvdir`, `…/grok-linux-aarch64`). **MUST NOT** match `ps -o comm=` — Termux truncates `comm` to `/data/data/com.`.  
20e. Nested PRoot **MUST NOT** run: if `TERMUX_EXEC__PROC_SELF_EXE` already contains `proot`, exec the vendor Linux file directly (inner PRoot + guest go to `ptrace_stop`). `/proc` TracerPid seen from inside grok’s PRoot is **not** trustworthy.  
20f. **MUST NOT** kill Termux’s own `runsvdir` that existed before this grok start (sshd / ssh-agent live there).  
20g. When `PREFIX` is set and `${PREFIX}/etc/profile.d/start-services.sh` exists, the Android `proot` wrapper **MUST** bind a no-op over that file (`proot -b /dev/null:${PREFIX}/etc/profile.d/start-services.sh`) so login-shell env capture does not spawn extra `runsvdir`. **MUST NOT** edit Termux’s `start-services.sh`. **MUST NOT** hard-code the Termux app-files root. The reaper (20c) remains the safety net. Setup procedure SSOT: `requirement-grok-setup` 18e.

**Suggested sample (complete — live copy is `gc_grok_p_once_run` in the ship unit).** Dispatch first; reaper only when `proot` is on PATH:

```sh
# Dispatch: proot present → reaper; else simple grok -p hello
if command -v proot >/dev/null 2>&1; then
    gc_grok_p_once_run   # collector + reaper; sets _ec; writes $_out
else
    # simple one-shot (GNU timeout -k or POSIX watchdog)
    gc_grok_prompt_run_simple
fi
```

```sh
# Match exe path, not truncated comm. Snapshot runsvdir before start.
# Collector = grok/proot PID. Reaper: guest gone or stdout idle
# → kill only NEW runsvdir → SIGKILL collector if still alive.
list_runsvdir() {
    ps -eo pid= -o args= | awk '
        $2 ~ /\/runsvdir$/ || $2 == "runsvdir" { print $1 }
    ' | sort
}
find_linux_child() {
    ps -eo pid= -o ppid= -o args= | awk -v pp="$COLLECTOR" '
        $2 == pp && ($3 ~ /\/grok-linux-aarch64$/ || $3 == "grok-linux-aarch64") {
            print $1; exit
        }
    '
}
# After grok-linux was seen then gone (or idle stdout):
#   reap_new_runsvdir
#   wait briefly; if COLLECTOR still alive: kill then kill -9
# Always cat captured stdout (even after SIGKILL).
```

**Invocation:** `{{APP_NAME}} check-session` · `{{APP_NAME}} run -p hello` · menu session line (same probe).

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
| PRoot dispatch | `command -v proot` → `gc_grok_p_once_run`; else simple bounded `grok -p hello` |
| Reaper marker | wrapper source contains `proot-exit-reaper` |
| start-services bind | wrapper source contains `profile.d/start-services.sh` and binds `/dev/null` over it when `PREFIX` is set |
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
14. Hang the session probe or the numbered menu waiting for an interactive `grok login`, or freeze them because `timeout` is missing or `proot`/grok ignores SIGTERM (no kill-after / no watchdog).  
14b. Leave the operator-facing `bin/grok` wrapper as bare `exec proot` so `grok -p` hangs after the answer until Ctrl-Z, or pass `proot -k` as kill-on-exit.  
14c. Treat leftover grok helpers as the hang cause, or claim “PRoot cannot see grok exit”, when grok-linux already `_exit`’d and leftover `runsvdir` from `bash -lc` → `start-services.sh` are the remaining tracees.  
14d. Match leftovers by truncated `comm`, wait on the PRoot PID as the only done signal, skip the reaper when `proot` is on PATH, skip the simple `grok -p hello` path when `proot` is not, or run nested PRoot.  
14f. Put the PRoot collector and reaper in the TTY process group so Ctrl-Z stops the watchdog, or require non-empty stdout before the reaper may SIGKILL.  
14e. Edit Termux’s `start-services.sh`, skip the `/dev/null` bind over `${PREFIX}/etc/profile.d/start-services.sh` when that file exists, hard-code the Termux app-files root, or kill Termux’s own pre-existing `runsvdir`.

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
| AC-10 | Hanging peer (SIGTERM ignored) does not freeze `check-session` or the Termux numbered menu (TP-GROK-CLI-44 · TP-GROK-CLI-45 · TP-CLI-21) |
| AC-11 | Probe source dispatches: `command -v proot` → `gc_grok_p_once_run`; else simple `grok -p hello` (TP-GROK-CLI-47 · TP-GROK-CLI-48) |
| AC-12 | Android `proot` wrapper source contains `proot-exit-reaper` and matches args/exe not `comm` (TP-VCLI-29 · TP-VCLI-30) |
| AC-13 | Android `proot` wrapper binds `/dev/null` over `${PREFIX}/etc/profile.d/start-services.sh` when `PREFIX` is set (TP-VCLI-31) |
| AC-14 | PRoot reaper: `setsid` collector, ignore TSTP, wait reaper first, empty-stdout still reaps (TP-GROK-CLI-49 · TP-CLI-23) |

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
| 2026-09-07 | Active (1.2.0) | Probe always bounded; GNU `timeout -k` or POSIX watchdog so Termux `proot` ignoring SIGTERM cannot freeze the menu |
| 2026-09-07 | Active (1.3.0) | Android wrapper `--kill-on-exit` + `grok -p` SIGKILL (setup 18e); dual mention |
| 2026-09-07 | Active (1.4.0) | PRoot exit hang: guest already exited; reaper + `command -v proot` dispatch vs simple `grok -p hello` |
| 2026-09-07 | Active (1.5.0) | On-device chain: `bash -lc` env capture → `start-services.sh` → leftover `runsvdir`; bind `/dev/null` over that profile snippet |
| 2026-09-07 | Active (1.6.0) | Reaper: `setsid` collector, ignore TSTP, wait reaper first, empty-stdout still reaps (INC-20260907-004) |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-VCLI-15**, **TP-VCLI-16** | `tests/test_grok_setup.sh` | have — smoke under `~/.grok/downloads` (not cache/`noexec` tmp) |
| **TP-VCLI-17**, **TP-VCLI-18** | `tests/test_grok_setup.sh` | have — wrong ELF / cannot-run is not already installed |
| **TP-VCLI-19**–**30** | `tests/test_grok_setup.sh` | have — Android ET_EXEC, `pkg install -y proot`, `LD_PRELOAD` unset, resolv bind, `--kill-on-exit` / `-p` SIGKILL, `proot-exit-reaper`, heal stale wrapper |
| **TP-LC-01** | `tests/test_local_lifecycle.sh` | have — grok-cli install → `USER_BIN` (not PREFIX) |
| **TP-CLI-01** | `tests/test_cli.sh` | have — `sh -n`; shebang `/bin/sh` |
| **TP-GROK-CLI-35**–**38** | `tests/test_domain_grok_cli.sh` | have — live `grok -p hello` fake peer; no xAI; no hang |
| **TP-GROK-CLI-44**, **TP-GROK-CLI-45** | `tests/test_domain_grok_cli.sh` | have — SIGTERM-ignoring grok fail-closes (`timeout -k` / watchdog) |
| **TP-CLI-21** | `tests/test_cli.sh` | have — Termux menu with hanging grok still prints the list |
| **TP-GROK-CLI-47**, **TP-GROK-CLI-48** | `tests/test_domain_grok_cli.sh` | have — probe dispatch `command -v proot` → reaper; else simple `-p` |
| **TP-VCLI-29**, **TP-VCLI-30** | `tests/test_grok_setup.sh` | have — wrapper `proot-exit-reaper`; heal stale wrapper without reaper |
| **TP-VCLI-31** | `tests/test_grok_setup.sh` | have — wrapper binds `/dev/null` over `profile.d/start-services.sh` |
| **TP-GROK-CLI-49** | `tests/test_domain_grok_cli.sh` | have — reaper `setsid` / ignore TSTP / wait reaper first; self-update heal source |
| **TP-VCLI-32** | `tests/test_grok_setup.sh` | have — `self-update` already-at-remote heals stale wrapper |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-07 (1.6.0 — setsid collector, ignore TSTP, wait reaper first, empty-stdout reap)  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
