# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.8.8] - 2026-09-05

### Fixed

- **Login check was a file guess.** `check-session`, `backup`, and the menu **logged in** / **logged out** line used to read `~/.grok/auth.json` (refresh token / future `expires_at`). That can look valid while grok cannot talk to xAI (revoked session, Termux DNS, missing wrapper). They now run **`grok -p hello` first** (stdin closed; `timeout` when present; grok’s answer is not printed). Missing grok → Next `grok-cli setup` then `grok login`. Probe fail → Next `grok login`. Core tests inject a fake `GROK_BIN` (no public network). Law: `requirement-grok-auth-backup` **1.2.0**. Suite **TP-GROK-CLI-03**–**05** · **35**–**38** · **TP-CLI-17**.

## [1.8.7] - 2026-09-04

### Added

- **Termux CLI coding-style law:** `requirement-shell-termux-coding` — how grok-cli is written on Termux/Android (`PREFIX`, Termux `pkg` never sudo, `noexec` tmp, do not assume `/usr/local/bin` or `/var`). Path classes on `requirement-project-folder` **1.2.0**. POSIX coding-style **points** (`requirement-shell-script-coding` **1.1.0**). `setup` procedure stays `requirement-grok-setup` **2.6.1**.

### Fixed

- **`setup` Termux DNS:** vendor grok (musl) reads `/etc/resolv.conf`, which on Termux has no `nameserver`, so `grok login` failed with `dns error` for `auth.x.ai`. Write `~/.grok/resolv.conf` and rewrite the wrapper as `proot -b thatfile:/etc/resolv.conf` (still no vendor byte-patch). If proot cannot bind, INFO still points at `XAI_API_KEY`. Law: `requirement-grok-setup` **2.6.0**. Suite **TP-VCLI-25**.

## [1.8.6] - 2026-09-04

### Fixed

- **`setup` download diagnosis:** curl failures now name **HTTP status** (`HTTP 404`, `HTTP 000` + curl exit). The xAI `linux-aarch64` grok 1.0.13 artifact is a valid static ELF `ET_EXEC` (not a truncated download). On Android `e_type` 2 refusal, leave `~/.grok/downloads/grok-{{os}}-{{arch}}.failed` instead of deleting it. `proot` smoke/wrapper now unsets `LD_PRELOAD` (termux-exec otherwise re-hits `e_type` 2). Law: `requirement-grok-setup` **2.5.0**. Suite **TP-VCLI-19** · **TP-VCLI-21** · **TP-VCLI-24**.

## [1.8.5] - 2026-09-04

### Fixed

- **`setup` on Termux:** when the vendor grok still cannot exec (`e_type` 2) and `proot` is missing, run `pkg install -y proot` (Android + Termux `pkg` only; no sudo; stdin closed) then retry the proot wrapper. Do not call `pkg` on non-Android. A failed `pkg` still fail-closes with Next `pkg install proot`. Law: `requirement-grok-setup` **2.4.0**. Suite **TP-VCLI-22** · **TP-VCLI-23**.

## [1.8.4] - 2026-09-04

### Fixed

- **`setup` on Termux/Android ET_EXEC:** the vendor `linux-aarch64` grok is a static Linux executable (`e_type` 2). Android `linker64` (via termux-exec) refuses it, so `--version` failed even after a correct-arch download. Retry with `TERMUX_EXEC_OPTOUT=1` / `LD_PRELOAD` unset, then `proot` if present; on success place a POSIX wrapper under `~/.grok/bin` (vendor file unchanged). If both fail: Next `pkg install proot`, then `grok-cli setup --force`. Law: `requirement-grok-setup` **2.3.0**. Suite **TP-VCLI-19** · **TP-VCLI-20** · **TP-VCLI-21**.

## [1.8.3] - 2026-09-04

### Fixed

- **`setup` on Termux/aarch64:** do not treat an x86_64 `grok` (execute bit on, `scp` from a linux-x86_64 host) as already installed. Skip only if `grok --version` succeeds on this host; refuse a downloaded ELF whose `e_machine` does not match `uname` (EM_X86_64 vs aarch64). Next: run `grok-cli setup --force` on the phone, do not scp grok from an x86_64 machine. Law: `requirement-grok-setup` **2.2.0**. Suite **TP-VCLI-17** · **TP-VCLI-18**.

## [1.8.2] - 2026-09-03

### Changed

- **Main menu short desc:** header board title is **Alternative online installer for xAI grok** (`APP_DESC` / `SHORT_DESCRIPTION`). No longer the generic “numbered list of live commands”. Law: `requirement-shell-cli-default-interaction` **2.3.0**. Suite **TP-CLI-17**.
- **README pitch:** product is an alternative online installer for xAI grok (vs `https://x.ai/cli/install.sh`); Termux-friendly `setup`; auth backup/sync is optional later work.

## [1.8.1] - 2026-09-03

### Changed

- **Main menu look** is **default CLI main menu style**: explain text after `: ` is *italic* and light gray (SGR **3** + **37**) via `out_menu_choice` (replaces `out_menu_row` / SGR 90). Number and command name stay unstyled. Header **grok-cli**(*version*) is unchanged. Law: `requirement-shell-cli-default-interaction` **2.2.0** · `requirement-shell-output-requirements` **1.1.0**. Suite **TP-CLI-17**.

## [1.8.0] - 2026-09-03

### Changed

- **Main menu:** header is **grok-cli**(*version*) (`APP_NAME(APP_VERSION)`). The next line is **logged in** or **logged out**. `check-session` is no longer a numbered row (the command still exists). Numbered rows start at **backup** (**1**); family **sudoers** is **5**. Explain text after `: ` is light gray *italic* on a TTY. Law: `requirement-shell-cli-default-interaction` **2.1.0**. Suite **TP-CLI-13** · **TP-CLI-17**.

### Fixed

- **Menu locators:** live AC/TP/lesson rows now name **3** for `sync-auth-from-remote` (pick **4** is `add-crontab`). Historical 1.7.1 changelog wording is unchanged.
- **`setup` download vs smoke:** the version pointer may land in product storage; the chmod’d/smoked binary is a `mktemp` sibling under `~/.grok/downloads` (not cache/`/tmp`/`/dev/shm`).
- **Menu nametag:** `APP_VERSION` is always Config `VERSION` (an inherited env value cannot relabel the header).
- **`setup` smoke `[ERROR]`:** a full stop after the happened clause before “This did not install”.

## [1.7.3] - 2026-09-02

### Fixed

- **`setup` on Termux/Android:** smoke `--version` on the file under `~/.grok/downloads` (same as xAI’s installer), not the cache folder / `/tmp` / `/dev/shm` which may be `noexec`. Failure now includes the smoke exit status and a short stderr snippet. Law: `requirement-grok-setup` **2.1.0**. Suite **TP-VCLI-15** · **TP-VCLI-16**.

## [1.7.2] - 2026-09-02

### Fixed

- **`prompt_ask` call shape:** assign `PROMPT_ASK_VALUE` in the current shell. **MUST NOT** `_x=$(prompt_ask …)` (T1-PROMPT-CAPTURE). Menu pick 4 and draft chooser updated. Static **TP-CLI-15**. Law: `requirement-shell-script-coding` **1.0.2**.

## [1.7.1] - 2026-09-02

### Fixed

- **Menu pick 4 (`sync-auth-from-remote`)** no longer freezes with no prompt. `prompt_ask` keeps UI off captured stdout (`>&2`) and reads `/dev/tty` when it opens, so `_spec=$(prompt_ask …)` shows `Remote (user@host, IPv4, domain, or user@domain):` instead of a silent hang (INC-20260902-001). Law: `requirement-grok-auth-backup` **1.1.1**. Suite **TP-GROK-CLI-34**.

## [1.7.0] - 2026-09-02

### Added

- **Online install** from selfmanaged, specialized onto grok-cli: `curl -fsSL https://raw.githubusercontent.com/cloudgen/grok-cli/main/src/grok-cli | sh`. Companion `${SCRIPT_URL}.sha256`. Verbs `version-check`, `self-update`, `self-uninstall`.
- **Empty argv:** TTY still opens the numbered menu. Off-TTY empty argv is Type O install-ensure (**not** help), so the pipe one-liner works. Checkout `install` remains an offline copy. Dual-mode matrix: `requirement-shell-online-install` **1.0.0**. Suite **TP-ONL-01..04** · **TP-CLI-07** / **13**.

## [1.6.0] - 2026-09-02

### Changed

- **`setup`**: install peer `grok` by the studied xAI procedure (platform detect, channel version pointer, `grok-{version}-{os}-{arch}` artifact, place under `~/.grok/downloads` and `~/.grok/bin`). **Does not** download or execute `https://x.ai/cli/install.sh` and **does not** require bash. Idempotent if `grok` is already present; `--force` fetches again. Core tests use a fake `curl` (no public network). Law: `requirement-grok-setup` **2.0.0**. Suite **TP-VCLI-01..09 · 11..14**.

## [1.5.0] - 2026-09-02

### Added

- **`sync-auth-from-remote`**: `scp` a remote host’s `/var/grok-cli/auth.*` into this login’s `~/.grok` (dest `auth.json` mode `0600`, no sudo). SPEC forms: `user@IPv4`, IPv4, domain-name, `user@domain-name` (documentation examples `192.0.2.10` / `host.example.com`). BatchMode scp (no password hang). Main menu row **4**; `add-crontab` **5**; family `sudoers` **6**. Law: `requirement-grok-auth-backup` **1.1.0**. Suite **TP-GROK-CLI-30..33**.

## [1.4.0] - 2026-09-02

### Added

- **`add-crontab`**: install this login’s crontab jobs matching the studied host timers — `*/30 * * * * sudo /usr/local/bin/grok-cli backup` and `45 * * * * /usr/local/bin/grok-cli sync-auth`. Uses `id -un` (any login with the matching `/etc/sudoers.d/grok-cli-<user>` NOPASSWD backup grant). Does not write `/etc`. Re-run does not duplicate. Main menu row **4**; family `sudoers` is **5**. Law: `requirement-grok-crontab` **1.0.0**. Suite **TP-GROK-CLI-26..29**.

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
