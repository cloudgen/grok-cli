# grok-cli - Grok auth backup to /var/grok-cli and unprivileged sync-auth

![Version](https://img.shields.io/badge/Version-1.0.0-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20(Caution%20%E2%80%A2%20Intentional%20%E2%80%A2%20Anti--fragile%20%E2%80%A2%20Over--engineered)-purple.svg)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/cloudgen/grok-cli?style=flat-square)](https://github.com/cloudgen/grok-cli)

**grok-cli** checks that grok is logged in with a valid session, then copies `~/.grok/auth.*` into `/var/grok-cli` as `root:root` so other logins can read them. A normal login installs the program locally, writes a grant file you can read, and submits it. Only an approved passwordless `sudo grok-cli backup` (JSON request approved by **sudoer-adm**) can push and chmod that store. Without sudo, any login can `sync-auth` from `/var/grok-cli` into their own `~/.grok`. There is no online `curl|sh` install.

| You (your own login) | Admin / already root | Not this |
|----------------------|----------------------|----------|
| Install to `~/.local/bin`, generate and submit a grant, run `check-session` / `backup` / `sync-auth` once the grant exists | Install into `/usr/local/bin` and install the sudoers fragment | No download-and-run install channel; a normal login does not write `/etc`; `sync-auth` never uses sudo |

## Features

- **Local self-management**: `install`, `uninstall`, `where-is-me`, `version`, `about`, `help`, `menu`
- **Session gate**: `check-session` — confirm grok is logged in (`~/.grok/auth.json`)
- **Backup**: `backup` → check session → elevated deposit of `auth.*` into `/var/grok-cli` → `chown root:root` → `chmod 0644`
- **sync-auth**: copy `/var/grok-cli/auth.*` into `~/.grok` as the invoking login (mode `0600` on `auth.json`; **no sudo**)
- **Narrow sudoers**: `print-sudoers` emits `NOPASSWD: /usr/local/bin/grok-cli backup` only (admin installs to `/etc/sudoers.d/`)
- **Sudoer approval submit**: `generate-sudoer-request` writes a local JSON grant you can review; then `submit-sudoer-request` lets sudoer-cli allocate a JSON request into `/var/sudoer-cli/sudoer-request`
- **Fail-closed**: missing login, unauthorized deposit, unreadable store
- **CIAO / CIAO-Lite** defensive design (Protection Zones, `out_*` output SSOT)

## Quick Installation

**Local (your own login, no root needed):**

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

This product is **local-only** for its install *channel* (no default `SCRIPT_URL` online install).

**Source repository:** [cloudgen/grok-cli](https://github.com/cloudgen/grok-cli)  
Config identity: `REPO_USER=cloudgen`, `REPO_NAME=grok-cli` (override with env if needed; does not enable online install while `SCRIPT_URL` is empty).

## Usage

```sh
grok-cli help
grok-cli menu
grok-cli about
grok-cli --json about

grok-cli check-session
grok-cli backup
grok-cli sync-auth

grok-cli print-sudoers
grok-cli generate-sudoer-request
grok-cli submit-sudoer-request
grok-cli uninstall --force
```

**Environment (selected):**

| Variable | Role |
|----------|------|
| `GROK_HOME` | Grok auth directory (default `~/.grok` of the invoking login) |
| `GROK_CLI_ROOT` | Durable store (default `/var/grok-cli`) |
| `ALLOW_TEST_LOCAL_SUDOERS` | `1` = allow test-mode sudoers emit without `--allow-test-local` |
| `SUDOER_CLI` | Override path to `sudoer-cli` |
| `SUDOER_ADM_USER` | Approver login to detect (default `sudoer-adm`) |

## Examples

```sh
# Confirm grok is logged in, then push auth.* into the shared store
grok-cli check-session
grok-cli backup

# Another login on the same host, no sudo:
grok-cli sync-auth
```

## Platform Compatibility

| Platform | Status |
|----------|--------|
| Linux, `/bin/sh` (dash/bash) | Supported |
| `python3` (optional) | Used for JSON session parse when present |
| `sudo` + narrow sudoers | Required for non-root deposit into `/var/grok-cli` |
| macOS / BSD | Not primary; GNU `date -d` / `stat -c` assumptions may differ |

## Related Projects

- [folder-backup](https://github.com/cloudgen/folder-backup) — architecture parent (folder archive backup)
- [CIAO Defensive Programming](https://github.com/cloudgen/ciao)
- [CIAO-Lite](https://github.com/cloudgen/ciao-lite)
- [cli-template](https://github.com/cloudgen/cli-template) — Type 0 local-only template (hop 0)

## Contributing

Keep changes surgical. Honor **CIAO-Lite Protection Zones** in `src/grok-cli`. Product behavior must stay consistent with live `docs/requirements/requirement-*.md`. Run `sh tests/run.sh` before proposing commits.

## License

MIT License — see [`LICENSE.md`](./LICENSE.md).

## Last Update

2026-08-23 — version **1.0.0**: specialized from sibling folder-backup; grok session gate; backup `~/.grok/auth.*` to `/var/grok-cli` as root:root; unprivileged `sync-auth`; JSON grant is `grok-cli backup` only (sudoer-adm).
