# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
