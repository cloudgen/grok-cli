**file**: docs/requirements/requirement-grok-setup.md  
**Status**: Active (Version 2.9.0)  
**Area**: domain  
**Key**: `requirement-grok-setup`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **operations Single Source of Truth** for grok-cli **`setup`** and **`run`**: Type 0 commands that **install** the peer xAI Grok Build CLI (`grok`) by performing the **same procedure** xAI’s published installer uses (platform detect, channel pointer, artifact fetch, place under `~/.grok`, PATH), **without downloading or executing** `https://x.ai/cli/install.sh`, and **start** that peer with auto-update off so Termux/PRoot is not left hanging.

Operators can then `grok-cli run` (or `grok login` / set `XAI_API_KEY`) and use `grok-cli check-session` / `backup`. A PATH line written to `~/.bashrc` does **not** apply to the current session; that is not an install failure.

This does **not** install grok-cli itself (checkout `install` and channel `curl|sh` are other requirements). This does **not** own grok-cli’s `SCRIPT_URL`. This does **not** byte-patch the vendor binary.

**Termux / Android host writing** (detect, `PREFIX`, `pkg` policy, `noexec`, FHS-not-assumed) is **`requirement-shell-termux-coding`**. Path **classes** (`PREFIX` tree, `~/.grok/downloads`) are **`requirement-project-folder`**. This file keeps the **`setup` procedure**.

### 1.1 Human-facing

**In one sentence:** you type `grok-cli setup` so this login downloads the matching `grok` program from xAI under `~/.grok`, then `grok-cli run` so grok starts without auto-update.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Run setup without sudo; start grok without auto-update | `grok-cli setup` · `grok-cli run` |
| The other role | xAI publishes the `grok` **binary** and a version pointer; grok-cli does not ship grok | `https://x.ai/cli/stable` then `https://x.ai/cli/grok-{{version}}-{{os}}-{{arch}}` |
| Not this file | grok-cli’s own copy-to-bin; sudo backup; session parse; executing xAI’s `install.sh` | `grok-cli install` · `grok-cli backup` |

| Includes | Excludes |
|----------|----------|
| Detect OS/arch; fetch channel version; fetch artifact; smoke `--version` from `~/.grok/downloads` (not `/tmp` or the cache folder); place `~/.grok/downloads` + `~/.grok/bin`; skip if `grok` already **runs on this host**; refuse wrong ELF; Android ET_EXEC retry (TERMUX_EXEC_OPTOUT / Termux `pkg install -y proot` / `proot` wrapper with `--kill-on-exit` and `grok -p` SIGKILL); `--force`; rewrite a stale Android wrapper on skip (no network); **`run`** starts grok with `--no-auto-update` | Downloading or running `install.sh`; installing grok-cli; `self-update`; empty-argv install-ensure; sudo; `pkg`/`apt` on non-Android; hanging `pkg` prompts; byte-patching the vendor binary (DNS string or ELF `e_type`); smoking a file that lives only in cache/`/tmp`/`/dev/shm`; treating an x86_64 scp as installed on aarch64; leaving `grok -p` hung so the operator must Ctrl-Z; starting grok under `--json` |
| Fail closed if curl/uname/download/smoke fails | Hitting the public network from Core tests |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/grok-cli` | ship unit | live `setup` / `run` |
| `grok-cli help` | command | listed `setup` and `run` rows |
| `grok` | peer CLI after setup | `grok-cli run` · `grok login` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| First machine | grok-cli fetches the version pointer and the matching binary, then links `grok` | `grok-cli setup` |
| grok already there | success, no download | `grok-cli setup` |
| Replace grok | fetch again | `grok-cli setup --force` |
| Start grok | grok starts with auto-update off (Termux does not hang) | `grok-cli run` |
| One-shot prompt | same, plus grok `-p hello` | `grok-cli run -p hello` |
| Sign in after | session files appear under `~/.grok` | `grok login` then `grok-cli check-session` |

Jargon: this is ordinary-user work, not a root host bootstrap and not grok-cli’s own installer.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Verb

1. **MUST** route **`setup`** from `app_main`.  
2. **MUST** be Type 0 (invoking login). **MUST NOT** require `sudo` to fetch or place the peer binary.  
3. **MUST** appear in `help` with one-line purpose.  
4. **MUST NOT** appear on the TTY numbered main menu (install/setup excluded).  
5. Dual mention: this file **and** `requirement-shell-cli-interface`. Domain catalog: `requirement-domain-grok-cli`.

### 2.2 Peer probe

6. Peer name **MUST** be `grok` (override `GROK_BIN` = absolute executable).  
7. Probe: `GROK_BIN` when set and executable, else `command -v grok`, else `$(GROK_HOME)/bin/grok`, else `${USER_BIN}/grok`. Disk search is required because PATH edits in `~/.bashrc` do not apply to the current session.  
8. Probe **MUST NOT** mean “grok-cli is installed.”

### 2.3 Idempotent skip

9. Probe success means the peer path is executable **and** `grok --version` succeeds on **this** host. When the file is ELF and `od` can read `e_machine`, a mismatch with this host (x86_64 vs aarch64) is **not** probe success — do not exec that file. A file that only has the execute bit (for example an x86_64 grok **scp**’d onto aarch64 Termux) is **not** already installed. Probe success and **no** `--force` → exit 0, no network. Human success + JSON `status=already_installed`. Unusable existing grok → fetch the matching `{{os}}-{{arch}}` artifact (INFO that the old file cannot run here).  
10. `--force` → fetch even if probe succeeds.  
11. `--json` / off-TTY **MUST NOT** hang.

### 2.4 Procedure (studied from xAI `install.sh`; grok-cli **MUST** perform these steps itself)

`setup` **MUST NOT** download, save, or execute `{{GROK_VENDOR_BASE_URL}}/install.sh` (default `https://x.ai/cli/install.sh`). It **MUST** reproduce the installer procedure in the ship unit (POSIX `/bin/sh`). **MUST NOT** require `bash`.

Studied installer behavior that this procedure **MUST** keep:

| Step | Studied installer | grok-cli `setup` |
|------|-------------------|------------------|
| OS | `uname -s`: Darwin → `macos`; Linux → `linux`; else fail | Same; **Windows/MINGW out of scope** (fail closed) |
| Arch | `uname -m`: `x86_64`/`amd64` → `x86_64`; `arm64`/`aarch64` → `aarch64`; else fail | Same |
| Rosetta | macOS `x86_64` + `hw.optional.arm64=1` → install `aarch64` | Same when `sysctl` is present |
| Channel | `GROK_CHANNEL` default `stable`; allow `stable` \| `alpha` \| `enterprise` | Same |
| Version pointer | GET `{{base}}/{{channel}}`; first line is `X.Y.Z` or `X.Y.Z-suffix` | Same; optional pin `GROK_SETUP_VERSION` skips the pointer |
| Base URL | Primary `https://x.ai/cli`; fallback GCS `https://storage.googleapis.com/grok-build-public-artifacts/cli` | Same (`GROK_VENDOR_BASE_URL` / `GROK_VENDOR_FALLBACK_URL`) |
| Artifact | `{{base}}/grok-{{version}}-{{os}}-{{arch}}`; try `.zst` if `zstd`, then `.gz` if `gzip`, then uncompressed | Same |
| Place | `$HOME/.grok/downloads/grok-{{os}}-{{arch}}` (download + smoke a `mktemp` sibling **in that directory**, not cache/`/tmp`/`/dev/shm`); `chmod +x`; smoke `--version`; relative symlink `$HOME/.grok/bin/grok` and `agent` | Same (`GROK_HOME` / `GROK_BIN_DIR`). Cache folder **MUST NOT** be the smoke path (Termux/Android `noexec`). Android ET_EXEC that only runs via opt-out or `proot`: POSIX wrapper at `bin/grok` (vendor file unchanged) |
| PATH now | If a dir already on PATH is writable: `$HOME/.local/bin` then `/usr/local/bin` | Same (`USER_BIN` then `GLOBAL_BIN`); **also** `${PREFIX}/bin` when `PREFIX` is set (Termux) |
| PATH later | Append `# >>> grok installer >>>` block to bash/zsh/fish rc | **MUST** for bash (`~/.bashrc`); **SHOULD** for zsh/fish |
| Completions / `config.toml` | Best-effort | **SHOULD** (must not fail setup if they fail) |
| Deployment key / managed config | Optional enterprise | **MUST NOT** unless `GROK_DEPLOYMENT_KEY` is set; **MUST NOT** print the key |
| Auth for install | Optional | Optional; runtime login is `grok login` / `XAI_API_KEY` |

12. Default **base** **MUST** be `https://x.ai/cli` (`GROK_VENDOR_BASE_URL` override for tests). Fallback **MUST** be `https://storage.googleapis.com/grok-build-public-artifacts/cli` (`GROK_VENDOR_FALLBACK_URL`).  
13. **MUST** `curl -fsSL` the **version pointer** (`{{base}}/{{channel}}`) into a temp file under product storage (cache/persistence). **MUST** write the **artifact** (the file that is chmod’d and smoked) as a `mktemp` sibling under `{{GROK_HOME}}/downloads`. **MUST NOT** pipe a failed or empty download into a decoder or into `exec`. **MUST NOT** place the chmod’d/smoked artifact only in the cache folder, `/tmp`, or `/dev/shm`.  
14. Curl non-zero or empty pointer/artifact → fail closed **before** placing links. The blocking error **MUST** include the HTTP status code from curl (`%{http_code}`) when curl ran (e.g. `HTTP 404`, `HTTP 000` when no response). **MUST NOT** report only “check network” with no status.  
15. Missing `curl` or `uname` → fail closed. Missing `bash` is **not** a failure.  
16. After a successful place, re-probe using rule 7 (PATH **and** well-known dirs). Binary present on disk → exit 0. If this session cannot `command -v grok`, that is expected: a PATH line in `~/.bashrc` does not apply until a new session. **MUST** say so as INFO (open a new terminal, then `grok login`). **MUST NOT** print `[ERROR]` for that stale-PATH case. **MUST NOT** tell the operator to add `${USER_BIN}` (`~/.local/bin`) when grok was placed under `~/.grok/bin`. Binary absent on disk → fail closed.  
17. **MUST NOT** copy `src/grok-cli` or write `grok-cli` as the peer binary.  
18. Smoke: the downloaded file **MUST** run `--version` successfully before it replaces the previous download. Failure → keep the existing install, fail closed (unless rule 18c finds a working Android exec method). The smoke path **MUST** be under `{{GROK_HOME}}/downloads` (or a `mktemp` sibling there). **MUST NOT** smoke a file that lives only in the cache folder, `/tmp`, or `/dev/shm` — those mounts may be `noexec` (common on Termux/Android). The blocking error **MUST** include the smoke exit status and a short captured stderr snippet when present (same `Next:` as the error table).  
18b. After download, if the file is ELF and `od` can read `e_machine`, **MUST** fail closed when `e_machine` does not match the detected arch (**MUST NOT** place). Smoke stderr that names `EM_X86_64` / `EM_AARCH64` **MUST** be reported as a wrong-architecture failure. **MUST NOT** treat that as a generic “check the download” miss.  
18c. After a failed **direct** smoke on Android (Termux), **MUST** retry `--version` with `TERMUX_EXEC_OPTOUT=1` and `LD_PRELOAD` unset. Termux’s exec interceptor loads files through Android `linker64`, which refuses ELF `ET_EXEC` (`e_type` 2); xAI’s `linux-aarch64` grok is that kind of static Linux executable (verified channel artifact: ELF64 aarch64, statically linked, `e_type` 2 — not a truncated download). If that retry succeeds, **MUST** place a POSIX wrapper at `{{GROK_HOME}}/bin/grok` (and `agent`) that execs the **unmodified** vendor file the same way. If that retry fails and `proot` is on PATH, **MUST** retry `proot {{file}} --version` with the **same** `LD_PRELOAD` unset / `TERMUX_EXEC_OPTOUT=1` (Termux wiki: proot under `libtermux-exec` re-hits `e_type` 2). On success, place a wrapper that unsets `LD_PRELOAD` then execs `proot` plus the vendor file. **MUST NOT** byte-patch ELF `e_type` (or any other vendor bytes) to pass the linker. If every retry fails, fail closed; the blocking `Next:` for an `e_type` / ET_EXEC refusal **MUST** be `pkg install proot`, then `{{APP_NAME}} setup --force` (or run grok on a Linux host). **MUST NOT** use “check the download” as that Next — the artifact was the matching `{{os}}-{{arch}}` file. **MUST NOT** delete the smoked file: **MUST** leave it under `{{GROK_HOME}}/downloads` as `grok-{{os}}-{{arch}}.failed` and name that path in the error.  
18d. After the opt-out retry in 18c fails, if `proot` is **not** on PATH and this host is Android **and** Termux `pkg` is available (`${PREFIX}/bin/pkg` when `PREFIX` is set, else `command -v pkg`), **MUST** run `pkg install -y proot` (stdin closed; `DEBIAN_FRONTEND=noninteractive`) and then retry the `proot` smoke (still with `LD_PRELOAD` unset). **MUST NOT** `sudo pkg`. **MUST NOT** run `pkg` or `apt` when `uname` is not Android (FreeBSD `pkg` is a different tool). **MUST NOT** hang under `--json` / off-TTY waiting for a `pkg` prompt. A failed `pkg install` is **not** itself a blocking error — **MUST** print WARN with exit/stderr snippet, then fall through to the 18c Next. **MUST NOT** install `proot` when opt-out already made `--version` succeed, or when `proot` is already on PATH.  
18e. The Android wrapper **MUST** let `grok -p` return to the shell. When the method is `proot`, the wrapper **MUST** pass `proot --kill-on-exit` when `proot --help` advertises that option (long option only — **MUST NOT** pass `-k`, which is `--kernel-release`). When argv includes `-p` / `--single` / `--prompt-file` / `--prompt-json`, the wrapper **MUST** pass grok `--no-auto-update` unless the operator already did, **MUST NOT** `exec` (stay parent), **MUST** SIGKILL the grok/proot child on SIGINT/SIGTERM (Ctrl-C), **and MUST** include the **PRoot-exit reaper** (`proot-exit-reaper`): treat **guest disappearance** (or idle stdout) as done, match leftovers by **args/exe** not truncated `comm`, kill only **new** `runsvdir` PIDs, then SIGKILL PRoot if it still will not exit. `--kill-on-exit` **MUST NOT** be treated as a guest-exit detector (PRoot often cannot determine grok exited). Interactive `grok` (no `-p`) **MUST** still `exec` so the TUI owns the TTY. **MUST NOT** byte-patch the vendor file. On Android, if grok already **runs** and `bin/grok` is a POSIX wrapper that lacks `--kill-on-exit`, `--no-auto-update`, **or** `proot-exit-reaper`, `setup` **MUST** rewrite that wrapper from the existing vendor file with **no** network (**MUST NOT** require `--force` for this heal). JSON status stays `already_installed`. Writing SSOT for the hang class: `requirement-shell-termux-coding` 2.4c.  
18f. Routed verb **`run`** **MUST** start the peer grok with `--no-auto-update` unless the operator already passed that flag, then remaining grok argv (`{{APP_NAME}} run -p hello` → `grok --no-auto-update -p hello`). Missing grok → Next `{{APP_NAME}} setup`. `--json` **MUST NOT** exec grok (Next `{{APP_NAME}} run`). **MUST** `exec` the peer so grok owns the TTY. Dual mention `requirement-shell-cli-interface` · `requirement-domain-grok-cli`.  
19. Version string **MUST** match `X.Y.Z` or `X.Y.Z-suffix` (`[A-Za-z0-9._]+`). Invalid pointer → fail closed.  
20. Relative symlink **MUST** be used when `bin` and `downloads` share a parent (default `~/.grok/bin` → `../downloads/grok-{{os}}-{{arch}}`), **except** when rule 18c requires an Android exec wrapper: then `bin/grok` is that POSIX script (vendor file under `downloads` stays unmodified; `agent` **MAY** be a symlink to `grok`).  
21. **MUST NOT** byte-patch the vendor binary (including the 16-byte `/etc/resolv.conf` string).  
21b. After a successful Android place, probe `{{GROK_SETUP_RESOLV_FILE}}` (default `/etc/resolv.conf`). If it is missing or has no `nameserver` line, **MUST** write `{{GROK_HOME}}/resolv.conf` with `nameserver` lines taken from `${PREFIX}/etc/resolv.conf` when present, else Android `getprop net.dns1` / `net.dns2`, else `1.1.1.1` and `8.8.8.8`. If `proot` is missing, apply rule 18d (`pkg install -y proot`). If `proot {{vendor}} --version` then succeeds, **MUST** rewrite `bin/grok` as a wrapper that runs `proot -b {{GROK_HOME}}/resolv.conf:/etc/resolv.conf {{vendor}}` with `LD_PRELOAD` unset (musl in the vendor grok reads `/etc/resolv.conf`; Termux’s copy has no nameserver, so `grok login` fails with `dns error` unless this bind is in place). **MUST NOT** treat a missing system resolv as an install failure. If proot cannot be used, **MUST** INFO that DNS may fail and Next is `export XAI_API_KEY`, or `grok login` from a host with working DNS. If the bind wrapper was written, Next remains `grok login`.  
22. Core tests **MUST** inject a fake `curl` (no public network). Overrides `GROK_VENDOR_BASE_URL` / `GROK_VENDOR_FALLBACK_URL` **MAY** be used in tests.

### 2.5 Errors

Blocking copy **MUST** say what happened and **`Next:`**.

| Case | Next |
|------|------|
| No curl | install curl, then `grok-cli setup` |
| No uname | install coreutils/uname, then `grok-cli setup` |
| Unsupported OS or arch | use linux or macos on x86_64 or aarch64, then `grok-cli setup` |
| Invalid channel | set `GROK_CHANNEL` to stable, alpha, or enterprise, then `grok-cli setup` |
| Version pointer failed | check network to x.ai, then `grok-cli setup` (happened sentence **MUST** include `HTTP NNN` or curl exit when curl ran) |
| Binary download failed | check network to x.ai, then `grok-cli setup` (happened sentence **MUST** include `HTTP NNN` or curl exit when curl ran) |
| Smoke `--version` failed | check the download, then `grok-cli setup` (happened sentence **MAY** include `exit N` and stderr) |
| Android refused the vendor grok (`e_type` 2 / static `ET_EXEC`; direct `--version` failed and opt-out / auto-`pkg` / `proot` retries failed) | `pkg install proot`, then `grok-cli setup --force` (or run grok on a Linux host). Happened sentence **MUST** name `{{GROK_HOME}}/downloads/grok-{{os}}-{{arch}}.failed`. **MUST NOT** Next: “check the download” |
| Downloaded or existing grok is the wrong ELF architecture | run `grok-cli setup --force` on this device (do not scp grok from an x86_64 host onto aarch64 Termux) |
| Place finished, `grok` missing on disk | check disk under `~/.grok`, then `grok-cli setup` |
| `grok` on disk, this session PATH stale | not an error: open a new terminal, then `grok login` |

JSON `message` **MUST** match the human sentence.

### 2.6 Invocation samples (dual mention)

```text
grok-cli setup
grok-cli setup --force
grok-cli setup --json
grok-cli run
grok-cli run -p hello
```

### 2.7 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Product | `grok-cli` |
| Verb | `setup` (place) · `run` (start without auto-update) |
| Handler | `gc_setup` · `gc_run_grok` |
| Peer | `grok` (xAI Grok Build CLI) |
| Base URL | `https://x.ai/cli` (`GROK_VENDOR_BASE_URL`) |
| Fallback URL | `https://storage.googleapis.com/grok-build-public-artifacts/cli` (`GROK_VENDOR_FALLBACK_URL`) |
| Channel | `GROK_CHANNEL` default `stable` |
| Version pin | `GROK_SETUP_VERSION` optional |
| Artifact | `{{base}}/grok-{{version}}-{{os}}-{{arch}}` (optional `.zst` / `.gz`) |
| Place | `{{GROK_HOME}}/downloads` `mktemp` sibling → smoke `--version` → `{{GROK_HOME}}/downloads/grok-{{os}}-{{arch}}` → `{{GROK_HOME}}/bin/grok` and `agent` (Android ET_EXEC: POSIX wrapper when opt-out/`proot` is the working exec; `proot --kill-on-exit` + `-p` SIGKILL; heal stale wrapper on skip) |
| PATH candidates | `USER_BIN` (`{{HOME}}/.local/bin`), `GLOBAL_BIN` (`/usr/local/bin`), `${PREFIX}/bin` when `PREFIX` is set |
| Overrides | `GROK_VENDOR_BASE_URL`, `GROK_VENDOR_FALLBACK_URL`, `GROK_CHANNEL`, `GROK_SETUP_VERSION`, `GROK_BIN`, `GROK_BIN_DIR`, `GROK_HOME`, `GROK_SETUP_RESOLV_FILE` (resolv probe; default `/etc/resolv.conf`) |
| Privilege | Type 0 |
| grok-cli install class | **not this file** — dual-mode owned by `requirement-shell-online-install` |
| Menu | setup excluded; this-login-only lists `run` first (`requirement-shell-cli-default-interaction`) |
| `install.sh` | **forbidden** as a fetch/exec target |
| Egress | version pointer + artifact (+ compressed suffixes) on the two bases above; **not** `/install.sh`. Termux `pkg install -y proot` (packages.termux.org / mirror) **only** on Android when rule 18d applies. Core tests fake `pkg` |

### 2.8 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Fail closed on missing curl/empty download/failed smoke; Core tests never need the public net; do not exec a third-party script.  
- **CIAO Principle 2 – Intentional**: Peer install is a named verb with a named procedure, not grok-cli’s own `install`, and not “pipe vendor bash”.  
- **CIAO Principle 10 – Least privilege**: Only the named HTTPS bases and artifact paths; no sudo for setup.  
- **CIAO Principle 16 – Interactive vs non-interactive**: No hang under `--json` / pipes.

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

**This requirement:** `setup` and `run` stay this login. Termux `pkg` is ordinary-user work. Do not use sudo. On this class the numbered list puts **`run` first**.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Temp-file fetch; never exec `install.sh`; never place a binary that fails `--version`.  
- **Intentional:** `setup` ≠ `install`; procedure is in the ship unit.  
- **Anti-fragile:** Skip when `grok` exists; rewrite a stale Android wrapper on that skip (no `--force`); URL/channel overrides for tests; GCS fallback.  
- **Over-protect:** Menu still hides setup; setup does not own grok-cli’s channel; no vendor-binary byte-patch (DNS string or ELF `e_type`).

---

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Make `setup` install grok-cli or set grok-cli’s `SCRIPT_URL`.  
2. Treat x.ai artifact fetch as grok-cli’s own `self-update` / Type O empty-argv.  
3. Require sudo for setup.  
4. Download, save, or execute `install.sh` (or pipe it to `bash` / `sh`).  
5. Require `bash` for setup.  
6. Put setup on the TTY main menu.  
7. Require public network for Core tests.  
8. Print tokens or `GROK_DEPLOYMENT_KEY`.  
9. Freeze a session Unix login or `/home/<login>/…` in this file.  
10. Print `[ERROR]` when grok is on disk but this session has not yet read a PATH line from `~/.bashrc`.  
11. Tell the operator to add `~/.local/bin` to PATH when grok was placed under `~/.grok/bin`.  
12. Byte-patch the vendor binary (including swapping `/etc/resolv.conf` for another 16-byte path, or changing ELF `e_type` from 2 to 3 so Android `linker64` will load it).  
13. Smoke `--version` from the cache folder, `/tmp`, or `/dev/shm` instead of a file under `{{GROK_HOME}}/downloads`.  
14. Treat a grok file that cannot run on this host (wrong ELF machine, exec format error) as `already_installed`.  
15. Place a downloaded ELF whose `e_machine` does not match the detected `{{os}}-{{arch}}`.  
16. Treat an Android `e_type` / ET_EXEC refusal as a generic “check the download” miss.  
17. Skip the Android opt-out / `proot` smoke retries when direct `--version` fails on Android.  
18. Run `pkg` / `apt` on a non-Android host, `sudo pkg`, or a `pkg` prompt that can hang `--json` / off-TTY.  
19. Skip Termux `pkg install -y proot` when Android opt-out failed, `proot` is missing, and Termux `pkg` is on PATH.  
20. Run `proot` against the vendor grok while Termux `LD_PRELOAD` (libtermux-exec) is still set.  
21. Delete the smoked Android download on `e_type` / ET_EXEC failure (operator cannot inspect `~/.grok/downloads`).  
22. Hide the HTTP status (or curl exit) on a failed version-pointer or artifact fetch.  
23. Leave Android grok without a `proot -b …:/etc/resolv.conf` bind when the probe resolv has no nameserver and proot can run the vendor file (musl then fails `grok login` with dns error).

24. Strip the **Under command line for normal user only** section, or enable admin privilege / a dedicated system user on Termux / Git Bash / Windows cmd.  
25. Leave the Android `proot` wrapper as bare `exec proot {{vendor}}` so `grok -p` hangs after the answer until Ctrl-Z.  
26. Pass `proot -k` meaning kill-on-exit (`-k` is `--kernel-release`).  
27. Require `setup --force` (a re-download) to rewrite a stale Android wrapper that already runs.  
28. Exec grok under `--json` for **`run`**, skip `--no-auto-update` when the operator did not pass it, or fail missing grok without Next `{{APP_NAME}} setup`.  
29. Treat `--kill-on-exit` as a grok-exit detector, omit `proot-exit-reaper` from the Android `-p` wrapper, match leftovers by truncated `comm`, or require `--force` to heal a wrapper that lacks the reaper.  

**Violating this rule is a critical setup / install-class regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | `setup` and `run` are routed and listed in help |
| AC-2 | Already-present `grok` is exit 0 with no curl |
| AC-3 | `--force` fetches the channel pointer and/or artifact (not `install.sh`) |
| AC-4 | Curl/uname/download/smoke failures are operator-readable and non-zero |
| AC-5 | Successful fake fetch places `grok` under `~/.grok/bin`, not grok-cli |
| AC-6 | TTY menu has no setup row |
| AC-7 | `setup` does not install grok-cli and does not own grok-cli’s `SCRIPT_URL` |
| AC-8 | Vendor dir install with stale session PATH is exit 0, not `[ERROR]` |
| AC-9 | Curl log **MUST NOT** contain `install.sh` |
| AC-10 | Missing `bash` **MUST NOT** fail setup |
| AC-11 | Smoke `--version` runs a file under `{{GROK_HOME}}/downloads`, not the cache folder |
| AC-12 | Smoke `--version` failure is operator-readable (`Next:` + happened sentence; captured exit/stderr when present) |
| AC-13 | Existing grok that cannot run on this host is **not** `already_installed`; setup fetches the matching artifact |
| AC-14 | Downloaded ELF `e_machine` mismatch fails closed and does not place `~/.grok/bin/grok` |
| AC-15 | Android `e_type` 2 smoke failure (after opt-out/`proot` retries) is operator-readable with Next `pkg install proot` (not “check the download”) |
| AC-16 | Android smoke that succeeds only with TERMUX_EXEC_OPTOUT or `proot` places a POSIX wrapper; the vendor file under `downloads` is unchanged |
| AC-17 | Termux Android, opt-out fail, `proot` missing, `pkg` present: setup runs `pkg install -y proot` and, if that places a runnable `proot`, installs grok via the proot wrapper |
| AC-18 | Termux `pkg install` failure is not a hang; setup still fail-closes with Next `pkg install proot` |
| AC-19 | Android ET_EXEC smoke failure leaves `{{GROK_HOME}}/downloads/grok-{{os}}-{{arch}}.failed` and names that path |
| AC-20 | `proot` smoke and wrapper run with `LD_PRELOAD` unset (Termux exec interceptor off) |
| AC-21 | Failed version-pointer or artifact fetch names `HTTP NNN` (or curl exit) in the happened sentence |
| AC-22 | Android + no nameserver on the resolv probe + proot can run grok: `{{GROK_HOME}}/resolv.conf` exists and `bin/grok` contains `proot -b` bind to `/etc/resolv.conf` |
| AC-23 | Android `proot` wrapper source contains `--kill-on-exit` (not `-k`) |
| AC-24 | Android wrapper injects `--no-auto-update` for `-p` / `--single` and SIGKILLs the child on SIGINT |
| AC-25 | Already-installed Android `proot` wrapper that lacks `--kill-on-exit` is rewritten with no curl; JSON/human still `already_installed` |
| AC-26 | `run` execs peer grok with `--no-auto-update` (unless already in argv); missing grok Next `setup`; `--json` does not exec |
| AC-27 | Android `proot` wrapper source contains `proot-exit-reaper` (guest-death reaper; args/exe match) (TP-VCLI-29) |
| AC-28 | Already-installed wrapper that has `--kill-on-exit` but lacks `proot-exit-reaper` is rewritten with no curl (TP-VCLI-30) |

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention of `setup` and `run` / dispatch |
| `docs/requirements/requirement-domain-grok-cli.md` | Domain catalog |
| `docs/requirements/requirement-grok-auth-backup.md` | Session after `grok login` |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Menu excludes setup; this-login-only lists `run` first |
| `docs/requirements/requirement-shell-termux-coding.md` | Termux host writing (detect/`pkg`/`noexec`) |
| `docs/requirements/requirement-project-folder.md` | Termux path classes (`PREFIX`, `~/.grok`) |
| `./src/grok-cli` | Implementation |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-25 | Active (1.0.0) | `setup` curled xAI `install.sh` |
| 2026-08-30 | Active (1.1.0) | Stale session PATH after vendor `.bashrc` update is INFO, not ERROR; probe `~/.grok/bin` |
| 2026-09-02 | Active (2.0.0) | Inlined studied installer procedure; **MUST NOT** fetch or exec `install.sh`; no bash required |
| 2026-09-02 | Active (2.1.0) | Smoke `--version` from `{{GROK_HOME}}/downloads` (not cache/`noexec` tmp); captured exec text on failure (Termux/Android); rule 13 pointer vs artifact split |
| 2026-09-04 | Active (2.2.0) | Skip only if grok **runs** on this host; refuse wrong ELF `e_machine` (x86_64 scp onto aarch64 Termux) |
| 2026-09-04 | Active (2.3.0) | Android ET_EXEC (`e_type` 2): retry TERMUX_EXEC_OPTOUT / `proot`; wrapper not byte-patch; Next is `pkg install proot` |
| 2026-09-04 | Active (2.4.0) | Termux: if opt-out fails and `proot` is missing, `pkg install -y proot` then retry (no sudo, no hang, not on non-Android) |
| 2026-09-04 | Active (2.5.0) | `proot` smoke unsets `LD_PRELOAD`; Android fail keeps `grok-{{os}}-{{arch}}.failed`; curl failures name HTTP status; channel artifact is valid static ET_EXEC |
| 2026-09-04 | Active (2.6.0) | Android DNS: write `{{GROK_HOME}}/resolv.conf` and `proot -b` over `/etc/resolv.conf` (no vendor byte-patch) so `grok login` can resolve auth.x.ai |
| 2026-09-04 | Active (2.6.1) | Dual mention: Termux host writing → `requirement-shell-termux-coding`; path classes → `requirement-project-folder` |
| 2026-09-07 | Active (2.7.0) | Android wrapper: `proot --kill-on-exit`; `grok -p` `--no-auto-update` + SIGKILL on Ctrl-C; heal stale wrapper on skip (no `--force`) |
| 2026-09-07 | Active (2.8.0) | Verb `run`: start peer grok with `--no-auto-update` (Termux hang) |
| 2026-09-07 | Active (2.9.0) | Android `-p` wrapper: PRoot-exit reaper (guest already exited; args/exe match); heal if marker missing |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-VCLI-01**–**09**, **11**–**30** | `tests/test_grok_setup.sh` | have |
| **TP-GROK-CLI-46** | `tests/test_domain_grok_cli.sh` | have — `run` injects `--no-auto-update` |
| **TP-CLI-04** (help lists setup and run) | `tests/test_cli.sh` | have |
| **TP-CLI-13** (menu excludes setup) | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-07 (2.9.0 — PRoot-exit reaper on Android `-p` wrapper)  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
