**file**: docs/requirements/requirement-grok-setup.md  
**Status**: Active (Version 2.1.0)  
**Area**: domain  
**Key**: `requirement-grok-setup`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **operations Single Source of Truth** for grok-cli **`setup`**: a Type 0 command that **installs the peer xAI Grok Build CLI (`grok`)** by performing the **same procedure** xAI’s published installer uses (platform detect, channel pointer, artifact fetch, place under `~/.grok`, PATH), **without downloading or executing** `https://x.ai/cli/install.sh`.

Operators can then `grok login` (or set `XAI_API_KEY`) and use `grok-cli check-session` / `backup`. A PATH line written to `~/.bashrc` does **not** apply to the current session; that is not an install failure.

This does **not** install grok-cli itself (checkout `install` and channel `curl|sh` are other requirements). This does **not** own grok-cli’s `SCRIPT_URL`. This does **not** byte-patch the vendor binary.

### 1.1 Human-facing

**In one sentence:** you type `grok-cli setup` so this login downloads the matching `grok` program from xAI’s CLI channel and places it under `~/.grok`; setup runs `--version` on the file under `~/.grok/downloads` first, because some phones will not execute a file from `/tmp` or the cache folder; then you `grok login`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Run setup without sudo | `grok-cli setup` |
| The other role | xAI publishes the `grok` **binary** and a version pointer; grok-cli does not ship grok | `https://x.ai/cli/stable` then `https://x.ai/cli/grok-{{version}}-{{os}}-{{arch}}` |
| Not this file | grok-cli’s own copy-to-bin; sudo backup; session parse; executing xAI’s `install.sh` | `grok-cli install` · `grok-cli backup` |

| Includes | Excludes |
|----------|----------|
| Detect OS/arch; fetch channel version; fetch artifact; smoke `--version` from `~/.grok/downloads` (not `/tmp` or the cache folder); place `~/.grok/downloads` + `~/.grok/bin`; skip if `grok` already works; `--force` | Downloading or running `install.sh`; installing grok-cli; `self-update`; empty-argv install-ensure; sudo; byte-patching DNS; smoking a file that lives only in cache/`/tmp`/`/dev/shm` |
| Fail closed if curl/uname/download/smoke fails | Hitting the public network from Core tests |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/grok-cli` | ship unit | live `setup` |
| `grok-cli help` | command | listed `setup` row |
| `grok` | peer CLI after setup | `grok login` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| First machine | grok-cli fetches the version pointer and the matching binary, then links `grok` | `grok-cli setup` |
| grok already there | success, no download | `grok-cli setup` |
| Replace grok | fetch again | `grok-cli setup --force` |
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

9. Probe success and **no** `--force` → exit 0, no network. Human success + JSON `status=already_installed`.  
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
| Place | `$HOME/.grok/downloads/grok-{{os}}-{{arch}}` (download + smoke a `mktemp` sibling **in that directory**, not cache/`/tmp`/`/dev/shm`); `chmod +x`; smoke `--version`; relative symlink `$HOME/.grok/bin/grok` and `agent` | Same (`GROK_HOME` / `GROK_BIN_DIR`). Cache folder **MUST NOT** be the smoke path (Termux/Android `noexec`) |
| PATH now | If a dir already on PATH is writable: `$HOME/.local/bin` then `/usr/local/bin` | Same (`USER_BIN` then `GLOBAL_BIN`); **also** `${PREFIX}/bin` when `PREFIX` is set (Termux) |
| PATH later | Append `# >>> grok installer >>>` block to bash/zsh/fish rc | **MUST** for bash (`~/.bashrc`); **SHOULD** for zsh/fish |
| Completions / `config.toml` | Best-effort | **SHOULD** (must not fail setup if they fail) |
| Deployment key / managed config | Optional enterprise | **MUST NOT** unless `GROK_DEPLOYMENT_KEY` is set; **MUST NOT** print the key |
| Auth for install | Optional | Optional; runtime login is `grok login` / `XAI_API_KEY` |

12. Default **base** **MUST** be `https://x.ai/cli` (`GROK_VENDOR_BASE_URL` override for tests). Fallback **MUST** be `https://storage.googleapis.com/grok-build-public-artifacts/cli` (`GROK_VENDOR_FALLBACK_URL`).  
13. **MUST** `curl -fsSL` the **version pointer** (`{{base}}/{{channel}}`) into a temp file under product storage (cache/persistence). **MUST** write the **artifact** (the file that is chmod’d and smoked) as a `mktemp` sibling under `{{GROK_HOME}}/downloads`. **MUST NOT** pipe a failed or empty download into a decoder or into `exec`. **MUST NOT** place the chmod’d/smoked artifact only in the cache folder, `/tmp`, or `/dev/shm`.  
14. Curl non-zero or empty pointer/artifact → fail closed **before** placing links.  
15. Missing `curl` or `uname` → fail closed. Missing `bash` is **not** a failure.  
16. After a successful place, re-probe using rule 7 (PATH **and** well-known dirs). Binary present on disk → exit 0. If this session cannot `command -v grok`, that is expected: a PATH line in `~/.bashrc` does not apply until a new session. **MUST** say so as INFO (open a new terminal, then `grok login`). **MUST NOT** print `[ERROR]` for that stale-PATH case. **MUST NOT** tell the operator to add `${USER_BIN}` (`~/.local/bin`) when grok was placed under `~/.grok/bin`. Binary absent on disk → fail closed.  
17. **MUST NOT** copy `src/grok-cli` or write `grok-cli` as the peer binary.  
18. Smoke: the downloaded file **MUST** run `--version` successfully before it replaces the previous download. Failure → keep the existing install, fail closed. The smoke path **MUST** be under `{{GROK_HOME}}/downloads` (or a `mktemp` sibling there). **MUST NOT** smoke a file that lives only in the cache folder, `/tmp`, or `/dev/shm` — those mounts may be `noexec` (common on Termux/Android). The blocking error **MUST** include the smoke exit status and a short captured stderr snippet when present (same `Next:` as the error table).  
19. Version string **MUST** match `X.Y.Z` or `X.Y.Z-suffix` (`[A-Za-z0-9._]+`). Invalid pointer → fail closed.  
20. Relative symlink **MUST** be used when `bin` and `downloads` share a parent (default `~/.grok/bin` → `../downloads/grok-{{os}}-{{arch}}`).  
21. **MUST NOT** byte-patch the vendor binary (including the 16-byte `/etc/resolv.conf` string). If `/etc/resolv.conf` is missing or has no `nameserver` line (common on Termux, where `/etc` is a read-only system tree), **MUST** print INFO that DNS may fail and that `XAI_API_KEY` or a host with working DNS is the next step — **MUST NOT** treat that as an install failure when `--version` succeeded.  
22. Core tests **MUST** inject a fake `curl` (no public network). Overrides `GROK_VENDOR_BASE_URL` / `GROK_VENDOR_FALLBACK_URL` **MAY** be used in tests.

### 2.5 Errors

Blocking copy **MUST** say what happened and **`Next:`**.

| Case | Next |
|------|------|
| No curl | install curl, then `grok-cli setup` |
| No uname | install coreutils/uname, then `grok-cli setup` |
| Unsupported OS or arch | use linux or macos on x86_64 or aarch64, then `grok-cli setup` |
| Invalid channel | set `GROK_CHANNEL` to stable, alpha, or enterprise, then `grok-cli setup` |
| Version pointer failed | check network to x.ai, then `grok-cli setup` |
| Binary download failed | check network to x.ai, then `grok-cli setup` |
| Smoke `--version` failed | check the download, then `grok-cli setup` (happened sentence **MAY** include `exit N` and stderr; Android **MAY** add that the vendor `{{os}}-{{arch}}` binary must execute as-is) |
| Place finished, `grok` missing on disk | check disk under `~/.grok`, then `grok-cli setup` |
| `grok` on disk, this session PATH stale | not an error: open a new terminal, then `grok login` |

JSON `message` **MUST** match the human sentence.

### 2.6 Invocation samples (dual mention)

```text
grok-cli setup
grok-cli setup --force
grok-cli setup --json
```

### 2.7 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Product | `grok-cli` |
| Verb | `setup` |
| Handler | `gc_setup` |
| Peer | `grok` (xAI Grok Build CLI) |
| Base URL | `https://x.ai/cli` (`GROK_VENDOR_BASE_URL`) |
| Fallback URL | `https://storage.googleapis.com/grok-build-public-artifacts/cli` (`GROK_VENDOR_FALLBACK_URL`) |
| Channel | `GROK_CHANNEL` default `stable` |
| Version pin | `GROK_SETUP_VERSION` optional |
| Artifact | `{{base}}/grok-{{version}}-{{os}}-{{arch}}` (optional `.zst` / `.gz`) |
| Place | `{{GROK_HOME}}/downloads` `mktemp` sibling → smoke `--version` → `{{GROK_HOME}}/downloads/grok-{{os}}-{{arch}}` → `{{GROK_HOME}}/bin/grok` and `agent` |
| PATH candidates | `USER_BIN` (`{{HOME}}/.local/bin`), `GLOBAL_BIN` (`/usr/local/bin`), `${PREFIX}/bin` when `PREFIX` is set |
| Overrides | `GROK_VENDOR_BASE_URL`, `GROK_VENDOR_FALLBACK_URL`, `GROK_CHANNEL`, `GROK_SETUP_VERSION`, `GROK_BIN`, `GROK_BIN_DIR`, `GROK_HOME` |
| Privilege | Type 0 |
| grok-cli install class | **not this file** — dual-mode owned by `requirement-shell-online-install` |
| Menu | setup excluded |
| `install.sh` | **forbidden** as a fetch/exec target |
| Egress | version pointer + artifact (+ compressed suffixes) on the two bases above; **not** `/install.sh` |

### 2.8 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Fail closed on missing curl/empty download/failed smoke; Core tests never need the public net; do not exec a third-party script.  
- **CIAO Principle 2 – Intentional**: Peer install is a named verb with a named procedure, not grok-cli’s own `install`, and not “pipe vendor bash”.  
- **CIAO Principle 10 – Least privilege**: Only the named HTTPS bases and artifact paths; no sudo for setup.  
- **CIAO Principle 16 – Interactive vs non-interactive**: No hang under `--json` / pipes.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Temp-file fetch; never exec `install.sh`; never place a binary that fails `--version`.  
- **Intentional:** `setup` ≠ `install`; procedure is in the ship unit.  
- **Anti-fragile:** Skip when `grok` exists; URL/channel overrides for tests; GCS fallback.  
- **Over-protect:** Menu still hides setup; setup does not own grok-cli’s channel; no DNS byte-patch.

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
12. Byte-patch the vendor binary (including swapping `/etc/resolv.conf` for another 16-byte path).  
13. Smoke `--version` from the cache folder, `/tmp`, or `/dev/shm` instead of a file under `{{GROK_HOME}}/downloads`.

**Violating this rule is a critical setup / install-class regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | `setup` is routed and listed in help |
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

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention / dispatch |
| `docs/requirements/requirement-domain-grok-cli.md` | Domain catalog |
| `docs/requirements/requirement-grok-auth-backup.md` | Session after `grok login` |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Menu excludes setup |
| `./src/grok-cli` | Implementation |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-25 | Active (1.0.0) | `setup` curled xAI `install.sh` |
| 2026-08-30 | Active (1.1.0) | Stale session PATH after vendor `.bashrc` update is INFO, not ERROR; probe `~/.grok/bin` |
| 2026-09-02 | Active (2.0.0) | Inlined studied installer procedure; **MUST NOT** fetch or exec `install.sh`; no bash required |
| 2026-09-02 | Active (2.1.0) | Smoke `--version` from `{{GROK_HOME}}/downloads` (not cache/`noexec` tmp); captured exec text on failure (Termux/Android); rule 13 pointer vs artifact split |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-VCLI-01**–**09**, **11**–**16** | `tests/test_grok_setup.sh` | have |
| **TP-CLI-04** (help lists setup) | `tests/test_cli.sh` | have |
| **TP-CLI-13** (menu excludes setup) | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-03  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
