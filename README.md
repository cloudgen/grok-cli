# grok-cli - Alternative online installer for xAI grok

![Version](https://img.shields.io/badge/Version-1.8.2-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20(Caution%20%E2%80%A2%20Intentional%20%E2%80%A2%20Anti--fragile%20%E2%80%A2%20Over--engineered)-purple.svg)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/cloudgen/grok-cli?style=flat-square)](https://github.com/cloudgen/grok-cli)

**grok-cli** is an alternative online installer for xAI’s `grok` CLI. The official one-liner on [x.ai](https://x.ai) (`curl -fsSL https://x.ai/cli/install.sh | bash`) is not intended for systems such as Termux. This program fetches the same vendor `grok` binary from xAI’s CLI channel and places it under `~/.grok` — it does **not** download or run `install.sh`.

| You | Official x.ai installer | Not this |
|-----|-------------------------|----------|
| Install grok-cli, then `grok-cli setup` (no sudo) | `curl -fsSL https://x.ai/cli/install.sh \| bash` on macOS / Linux / Windows | A second grok binary; executing x.ai’s `install.sh`; claiming official Termux support |

After `setup`, open a new terminal if `grok` is not on this session’s PATH, then `grok login` (or set `XAI_API_KEY`). Sharing `~/.grok/auth.*` across logins on one host is optional later work (`backup` / `sync-auth`), not the reason this tool exists.

## Features

- **Alternative grok install**: `setup` — detect OS/arch, read xAI’s channel version pointer, fetch the matching `grok` artifact, smoke `--version` from `~/.grok/downloads` (not `/tmp` or the cache folder; those may be `noexec` on Termux/Android), place `~/.grok/bin/grok`. Skip if grok already works; `--force` fetches again. POSIX `/bin/sh` (does **not** require bash). Does **not** run `install.sh`. Does **not** byte-patch the vendor binary.
- **Termux-aware place**: also uses `${PREFIX}/bin` when `PREFIX` is set; missing `/etc/resolv.conf` is INFO, not an install failure when `--version` succeeded.
- **This program’s online install**: `curl|sh` channel, `version-check`, `self-update`, `self-uninstall`
- **Local self-management**: `install`, `uninstall`, `where-is-me`, `version`, `about`, `help`, `menu`
- **Session gate** (after grok is signed in): `check-session`
- **Optional shared auth on a host**: `backup` deposits `~/.grok/auth.*` into `/var/grok-cli` as `root:root` `0644`; `sync-auth` copies that store into this login’s `~/.grok` with **no sudo**; `sync-auth-from-remote` uses `scp`; `add-crontab` adds this login’s timers after **this** login’s backup grant exists
- **Narrow sudoers** (only if you use `backup`): `print-sudoers` emits `NOPASSWD: /usr/local/bin/grok-cli backup`; `generate-sudoer-request` / `submit-sudoer-request` for sudoer-adm
- **Fail-closed**: missing login, unauthorized deposit, unreadable store, failed grok download/smoke
- **CIAO / CIAO-Lite** defensive design (Protection Zones, `out_*` output SSOT)

## Quick Installation

**Official grok installer** (macOS / Linux / Windows; not intended for Termux):

```sh
curl -fsSL https://x.ai/cli/install.sh | bash
```

**This project** (POSIX `/bin/sh`; Termux-friendly procedure — still the vendor `grok` binary):

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli | sh
grok-cli setup
```

Then open a **new terminal** if this session cannot find `grok`, and run `grok login`.

**Global grok-cli (root):**

```sh
sudo curl -fsSL https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli | sudo sh
```

**Integrity (automatic, no env pin):** SHA-256. The program fetches the companion `${SCRIPT_URL}.sha256` itself and prints **link**, **value**, and **result**.

| Result | What happens |
|--------|----------------|
| Match | Install continues |
| Mismatch | Abort (non-zero) |
| Missing sidecar | Warn and continue |

Companion file in-repo: `src/grok-cli.sha256`  
Companion URL: `https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli.sha256`

**From a checkout (offline copy of grok-cli, no network):**

```sh
sh src/grok-cli install
# or force refresh after updates
sh src/grok-cli install --force

# Ensure ~/.local/bin is on PATH, then:
grok-cli version
grok-cli setup
```

**Global grok-cli from checkout** (preferred before durable sudoers / production elevation):

```sh
sudo sh src/grok-cli install
# or: grok-cli install --global   # needs write access to /usr/local/bin
# Managed binary mode is always 0755 so every user can run the shell ship unit.
```

**Optional — sudoers** (only if a non-root login will deposit into root-owned `/var/grok-cli`):

```sh
grok-cli print-sudoers-install-script
# Admin (account with sudo rights) — handoff script (path printed by CLI):
sudo sh /dev/shm/grok-cli-<user>-sudoers-admin.sh install

# Or JSON grant for sudoer-adm:
grok-cli generate-sudoer-request
grok-cli submit-sudoer-request
```

Local `~/.local/bin` install is **not** production-secure for host elevation — the user can change the binary. Prefer global install for any host that keeps `/etc/sudoers.d/grok-cli-<user>`. See [`SECURITY.md`](./SECURITY.md).

This product is **dual-mode**: primary install is the curl one-liner; `sh src/grok-cli install` copies the running checkout.

**Source repository:** [cloudgen/grok-cli](https://github.com/cloudgen/grok-cli)  
Config identity: `REPO_USER=cloudgen`, `REPO_NAME=grok-cli`. Default channel: `SCRIPT_URL=https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli`.

After install, on a terminal:

```text
$ grok-cli menu
[INFO] **grok-cli**(*1.8.2*) — Alternative online installer for xAI grok
logged out
1. backup: *Push ~/.grok/auth.* to /var/grok-cli*
2. sync-auth: *Copy /var/grok-cli/auth.* into ~/.grok*
3. sync-auth-from-remote: *Copy a remote host's auth.* into ~/.grok*
4. add-crontab: *Add backup and sync-auth jobs to this login's crontab*
5. sudoers: *Grant and drafts*
9. Exit
```

Choose a number, or type the command name. `9` exits. The line under the title is **logged in** or **logged out**. On a real terminal the descriptions after the colon are gray and italic. `setup` is not on this list — type `grok-cli setup`.

## Usage

| How you run it | What you get |
|----------------|--------------|
| `grok-cli` at a real terminal | Numbered start list (`backup` is **1**; login status is under the title; **9** leaves). Same as `grok-cli menu`. |
| `curl -fsSL … \| sh` or `grok-cli` in a script (no args) | Install-ensure: places `~/.local/bin/grok-cli` or reports already installed. **Not** help. **Not** the menu. |
| `grok-cli help` or `grok-cli --json` (no command) | Help / JSON help |
| `grok-cli menu` in a script | Help (the list is TTY-only) |

```sh
grok-cli                 # numbered list on a real terminal; install-ensure in a script / pipe
grok-cli help
grok-cli menu            # same numbered list as empty argv on a TTY
grok-cli about
grok-cli --json about
grok-cli version-check
grok-cli self-update

grok-cli setup                 # install grok from x.ai (not grok-cli; not install.sh)
grok-cli check-session
grok-cli backup
grok-cli sync-auth
grok-cli sync-auth-from-remote user@192.0.2.10
grok-cli add-crontab

grok-cli print-sudoers
grok-cli generate-sudoer-request
grok-cli submit-sudoer-request
grok-cli uninstall --force
grok-cli self-uninstall --force
```

**Environment (selected):**

| Variable | Role |
|----------|------|
| `SCRIPT_URL` | grok-cli install channel (default github raw `src/grok-cli`) |
| `GROK_HOME` | Grok auth directory (default `~/.grok` of the invoking login) |
| `GROK_VENDOR_BASE_URL` | xAI grok channel/artifact base (default `https://x.ai/cli`) |
| `GROK_CHANNEL` | grok channel (`stable` / `alpha` / `enterprise`; default `stable`) |
| `GROK_BIN` | Override path to peer `grok` |
| `GROK_CLI_ROOT` | Durable auth store (default `/var/grok-cli`; optional sharing) |
| `ALLOW_TEST_LOCAL_SUDOERS` | `1` = allow test-mode sudoers emit without `--allow-test-local` |
| `SUDOER_CLI` | Override path to `sudoer-cli` |
| `SUDOER_ADM_USER` | Approver login to detect (default `sudoer-adm`) |

## Examples

```sh
# Place xAI grok (skip if already installed)
grok-cli setup
# open a new terminal if grok is not on this session PATH yet
grok login

# Optional: confirm session, then share auth.* on this host
grok-cli check-session
grok-cli backup

# Another login on the same host, no sudo:
grok-cli sync-auth

# Pull the shared store from another host (openssh scp; no sudo):
grok-cli sync-auth-from-remote user@192.0.2.10

# After sudoer-adm approves THIS login's backup grant:
grok-cli add-crontab
```

## Platform Compatibility

| Platform | Status |
|----------|--------|
| Linux, `/bin/sh` (dash/bash) | Supported |
| Termux / Android userspace | Supported for **this installer** (`setup` smokes under `~/.grok/downloads`, honors `$PREFIX/bin`, does not require bash). The vendor `linux` `grok` binary must still execute as-is; missing `/etc/resolv.conf` is not an install failure — use `XAI_API_KEY` or a host with working DNS if login fails. **Not** official x.ai Termux support. |
| `python3` (optional) | Used for JSON session parse when present |
| `sudo` + narrow sudoers | Required only for non-root `backup` into `/var/grok-cli` |
| macOS | `setup` follows xAI’s Darwin/arch detect; GNU `date -d` / `stat -c` assumptions may differ for other verbs |
| Windows | Out of scope (fail closed in `setup`) |

## Related Projects

- Official grok install: [x.ai](https://x.ai) — `curl -fsSL https://x.ai/cli/install.sh | bash`
- [selfmanaged](https://github.com/cloudgen/selfmanaged) — online `curl\|sh` package specialized onto grok-cli
- [folder-backup](https://github.com/cloudgen/folder-backup) — architecture parent (folder archive backup)
- [CIAO Defensive Programming](https://github.com/cloudgen/ciao)
- [CIAO-Lite](https://github.com/cloudgen/ciao-lite)
- [cli-template](https://github.com/cloudgen/cli-template) — Type 0 template (hop 0)

## Contributing

Keep changes surgical. Honor **CIAO-Lite Protection Zones** in `src/grok-cli`. Product behavior must stay consistent with live `docs/requirements/requirement-*.md`. Run `sh tests/run.sh` before proposing commits.

## License

MIT License — see [`LICENSE.md`](./LICENSE.md).

## Last Update

2026-09-03 — README rewritten for the installer intention (alternative to x.ai `install.sh`; Termux-friendly `setup`; auth backup is optional later work). Version **1.8.2**.  
2026-09-03 — version **1.8.2**: main-menu short desc is **Alternative online installer for xAI grok**.  
2026-09-03 — version **1.8.1**: numbered menu descriptions are italic + light gray (SGR 3+37); default CLI main menu style.  
2026-09-03 — version **1.8.0**: main menu header **grok-cli**(*version*); **logged in** / **logged out** under the title; `check-session` is no longer a numbered row.  
2026-09-02 — version **1.7.3**: `setup` smokes grok from `~/.grok/downloads` (Termux/Android `noexec` tmp) and prints the exec error.  
2026-09-02 — version **1.7.2**: `prompt_ask` sets `PROMPT_ASK_VALUE` in the current shell (no `$()` of `read` helpers).  
2026-09-02 — version **1.7.1**: TTY menu pick 4 (`sync-auth-from-remote`) shows the SPEC prompt instead of hanging (INC-20260902-001).  
2026-09-02 — version **1.7.0**: online `curl|sh` install; off-TTY empty argv is ensure, TTY empty argv stays the menu.  
2026-09-02 — version **1.6.0**: `setup` installs peer `grok` by the studied xAI channel + artifact procedure (does not run `install.sh`).  
2026-09-02 — version **1.5.0**: `sync-auth-from-remote` pulls `/var/grok-cli/auth.*` from another host via scp.  
2026-09-02 — version **1.4.0**: `add-crontab` installs this login’s backup/sync-auth crontab jobs after **this** login’s sudoers grant exists.  
2026-08-30 — version **1.3.0**: storage = cache folder **and** persistence `${HOME}/.local/grok-cli`; `about` prints both.  
2026-08-30 — version **1.2.2**: `about` Cache folder preferred `/dev/shm/cache/cache-grok-cli`; fallback under XDG `cache-grok-cli` (not Storage (effective)/(fallback)).  
2026-08-23 — version **1.1.0**: empty argv on a real terminal opens the numbered start list (same as `menu`); off-TTY empty argv still prints help; Type N (no install).  
2026-08-23 — version **1.0.0**: specialized from sibling folder-backup; grok session gate; backup `~/.grok/auth.*` to `/var/grok-cli` as root:root; unprivileged `sync-auth`; JSON grant is `grok-cli backup` only (sudoer-adm).
