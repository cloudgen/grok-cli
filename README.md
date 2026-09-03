# grok-cli - Grok auth backup to /var/grok-cli and unprivileged sync-auth

![Version](https://img.shields.io/badge/Version-1.8.1-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20(Caution%20%E2%80%A2%20Intentional%20%E2%80%A2%20Anti--fragile%20%E2%80%A2%20Over--engineered)-purple.svg)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/cloudgen/grok-cli?style=flat-square)](https://github.com/cloudgen/grok-cli)

**grok-cli** checks that grok is logged in with a valid session, then copies `~/.grok/auth.*` into `/var/grok-cli` as `root:root` so other logins can read them. A normal login installs the program locally, writes a grant file you can read, and submits it. Only an approved passwordless `sudo grok-cli backup` (JSON request approved by **sudoer-adm**) can push and chmod that store. Without sudo, any login can `sync-auth` from `/var/grok-cli` into their own `~/.grok`. Install with a one-liner (`curl|sh`) or from a checkout.

| You (your own login) | Admin / already root | Not this |
|----------------------|----------------------|----------|
| Install to `~/.local/bin`, generate and submit a grant, run `check-session` / `backup` / `sync-auth` / `add-crontab` once the grant exists | Install into `/usr/local/bin` and install the sudoers fragment | A normal login does not write `/etc`; `sync-auth` never uses sudo |

## Features

- **Local self-management**: `install`, `uninstall`, `where-is-me`, `version`, `about`, `help`, `menu`
- **Online self-management**: `curl|sh` channel, `version-check`, `self-update`, `self-uninstall`
- **Peer grok install**: `setup` — detect platform, fetch xAI’s channel version pointer and the matching `grok` binary, place it under `~/.grok/bin` (does **not** install grok-cli; does **not** run `install.sh`; skip if `grok` is already present). A PATH line in `~/.bashrc` does not apply to the current session.
- **Session gate**: `check-session` — confirm grok is logged in (`~/.grok/auth.json`)
- **Backup**: `backup` → check session → elevated deposit of `auth.*` into `/var/grok-cli` → `chown root:root` → `chmod 0644`
- **sync-auth**: copy `/var/grok-cli/auth.*` into `~/.grok` as the invoking login (mode `0600` on `auth.json`; **no sudo**)
- **sync-auth-from-remote**: `scp` a remote host’s `/var/grok-cli/auth.*` into `~/.grok`. SPEC: `user@192.0.2.10`, `192.0.2.10`, `host.example.com`, or `user@host.example.com`. No sudo.
- **add-crontab**: install this login’s crontab jobs (`*/30` `sudo /usr/local/bin/grok-cli backup`; minute 45 `sync-auth`) after **this** login’s passwordless backup grant exists. Does not write `/etc`. Re-run does not duplicate.
- **Narrow sudoers**: `print-sudoers` emits `NOPASSWD: /usr/local/bin/grok-cli backup` only (admin installs to `/etc/sudoers.d/`)
- **Sudoer approval submit**: `generate-sudoer-request` writes a local JSON grant you can review; then `submit-sudoer-request` lets sudoer-cli allocate a JSON request into `/var/sudoer-cli/sudoer-request`
- **Fail-closed**: missing login, unauthorized deposit, unreadable store
- **CIAO / CIAO-Lite** defensive design (Protection Zones, `out_*` output SSOT)

## Quick Installation

**Online (recommended):**

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli | sh
```

**Global (root):**

```sh
sudo curl -fsSL https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli | sudo sh
```

Companion digest (fetched automatically): `https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli.sha256`

**From a checkout (offline copy, no network):**

```sh
# From this repository checkout
sh src/grok-cli install
# or force refresh after updates
sh src/grok-cli install --force

# Ensure ~/.local/bin is on PATH, then:
grok-cli version
```

**Global (preferred before durable sudoers / production elevation):**

```sh
sudo sh src/grok-cli install
# or: grok-cli install --global   # needs write access to /usr/local/bin
# Managed binary mode is always 0755 so every user can run the shell ship unit.
```

**Sudoers (required for non-root deposit of root-owned `/var/grok-cli`):**

```sh
grok-cli print-sudoers-install-script
# Admin (account with sudo rights) — handoff script (path printed by CLI):
sudo sh /dev/shm/grok-cli-<user>-sudoers-admin.sh install

# Or JSON grant for sudoer-adm:
grok-cli generate-sudoer-request
grok-cli submit-sudoer-request
```

**Security note:** Local `~/.local/bin` install is **not** production-secure for host elevation — the user can change the binary. Prefer global install for any host that keeps `/etc/sudoers.d/grok-cli-<user>`. See [`SECURITY.md`](./SECURITY.md).

This product is **dual-mode**: primary install is the curl one-liner; `sh src/grok-cli install` copies the running checkout.

**Source repository:** [cloudgen/grok-cli](https://github.com/cloudgen/grok-cli)  
Config identity: `REPO_USER=cloudgen`, `REPO_NAME=grok-cli`. Default channel: `SCRIPT_URL=https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli`.

After install, on a terminal:

```text
$ grok-cli menu
[INFO] **grok-cli**(*1.8.1*) — numbered list of live commands
logged out
1. backup: *Push ~/.grok/auth.* to /var/grok-cli*
2. sync-auth: *Copy /var/grok-cli/auth.* into ~/.grok*
3. sync-auth-from-remote: *Copy a remote host's auth.* into ~/.grok*
4. add-crontab: *Add backup and sync-auth jobs to this login's crontab*
5. sudoers: *Grant and drafts*
9. Exit
```

Choose a number, or type the command name. `9` exits. The line under the title is **logged in** or **logged out**. On a real terminal the descriptions after the colon are gray and italic.

## Starting grok-cli

| How you run it | What you get |
|----------------|--------------|
| `grok-cli` at a real terminal | Numbered start list (`backup` is **1**; login status is under the title; **9** leaves). Same as `grok-cli menu`. |
| `curl -fsSL … \| sh` or `grok-cli` in a script (no args) | Install-ensure: places `~/.local/bin/grok-cli` or reports already installed. **Not** help. **Not** the menu. |
| `grok-cli help` or `grok-cli --json` (no command) | Help / JSON help |
| `grok-cli menu` in a script | Help (the list is TTY-only) |

## Usage

```sh
grok-cli                 # numbered list on a real terminal; install-ensure in a script / pipe
grok-cli help
grok-cli menu            # same numbered list as empty argv on a TTY
grok-cli about
grok-cli --json about
grok-cli version-check
grok-cli self-update

grok-cli setup                 # install grok from x.ai (not grok-cli)
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
| `GROK_CLI_ROOT` | Durable store (default `/var/grok-cli`) |
| `GROK_VENDOR_BASE_URL` | xAI grok channel/artifact base (default `https://x.ai/cli`) |
| `GROK_CHANNEL` | grok channel (`stable` / `alpha` / `enterprise`; default `stable`) |
| `GROK_BIN` | Override path to peer `grok` |
| `ALLOW_TEST_LOCAL_SUDOERS` | `1` = allow test-mode sudoers emit without `--allow-test-local` |
| `SUDOER_CLI` | Override path to `sudoer-cli` |
| `SUDOER_ADM_USER` | Approver login to detect (default `sudoer-adm`) |

## Examples

```sh
# Place xAI grok (skip if already installed), sign in, then push auth.*
grok-cli setup
# open a new terminal if grok is not on this session PATH yet
grok login
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
| `python3` (optional) | Used for JSON session parse when present |
| `sudo` + narrow sudoers | Required for non-root deposit into `/var/grok-cli` |
| macOS / BSD | Not primary; GNU `date -d` / `stat -c` assumptions may differ |

## Related Projects

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
