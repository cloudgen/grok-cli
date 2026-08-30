# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.3.0] - 2026-08-30

### Added

- **Persistence storage.** Storage law covers two classes: **cache folder** (`/dev/shm/cache/cache-grok-cli` preferred, XDG `cache-grok-cli` fallback) and **persistence storage** `${HOME}/.local/grok-cli`. `about` prints **Persistence storage**; JSON adds `persistence_storage`. Not `~/.local/bin` (install) and not `/var/grok-cli` (Type 1 deposit). Law: `requirement-shell-cli-storage` **1.2.0**. Suite **TP-CLI-06 / 12**.

## [1.2.2] - 2026-08-30

### Changed

- **Cache folder labels and preferred path.** `about` prints **Cache folder (preferred)** and **Cache folder (fallback)** (not Storage (effective)/(fallback)). Preferred leaf is `/dev/shm/cache/cache-grok-cli` so it is not confused with a ram-drive project tree. Fallback is `${XDG_CACHE_HOME}/cache-grok-cli`. JSON adds `cache_preferred` / `cache_fallback`. Law: `requirement-shell-cli-storage` **1.1.0**. Suite **TP-CLI-06 / 12**.

## [1.2.1] - 2026-08-30

### Fixed

- **`setup`**: after the xAI installer writes grok under `~/.grok/bin` and a PATH line in `~/.bashrc`, do not print `[ERROR] grok is not on PATH` and do not send the operator to `~/.local/bin`. grok on disk is success; this session still needs a new terminal before `grok login`.

## [1.2.0] - 2026-08-25

### Added

- **`setup`**: download xAI’s grok installer (`https://x.ai/cli/install.sh`) and run it so the peer `grok` CLI is on PATH. Idempotent if `grok` is already present; `--force` fetches again. Does not install grok-cli and does not add a grok-cli online-install channel. Core tests use a fake `curl` (no public network).

## [1.1.0] - 2026-08-23

### Changed

- Empty argv on a real terminal now opens the numbered start list (same handler as `grok-cli menu` / `main`). Off-TTY empty argv still prints help. `--json` with no command still prints JSON help. Local-only Type N is unchanged: empty argv never install-ensures.

## [1.0.0] - 2026-08-23

### Added

- Product **grok-cli** specialized from sibling **folder-backup** (chain: cli-template → folder-backup → grok-cli).
- **`check-session`**: fail closed unless grok is logged in with a valid `~/.grok/auth.json` session.
- **`backup`**: after a valid session, copy `~/.grok/auth.*` into `/var/grok-cli`, `chown root:root`, `chmod 0644`. Non-root re-execs passwordless `sudo /usr/local/bin/grok-cli backup` after sudoer-adm approves the JSON grant.
- **`sync-auth`**: copy `/var/grok-cli/auth.*` into `~/.grok` as the invoking login (`auth.json` mode `0600`). Does not use sudo.
- JSON sudoer file grants **`grok-cli backup` only** (no OS-tool `cp`/`chmod`, no `restore`).
- Suite **TP-GROK-CLI-*** plus inherited Type 0 **TP-CLI-*** / **TP-LC-***.

### Removed

- Folder archive `backup <folder>` / `restore` / tar.gz retention (daily 5 / total 30).
