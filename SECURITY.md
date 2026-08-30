# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.3.0 (current) | Yes |
| 1.2.2 | Yes |
| 1.2.1 | Yes |
| 1.2.0 | Yes |
| 1.1.0 | Yes |
| 1.0.0 | Yes |

## Reporting a Vulnerability

Please **do not** open a public issue for security-sensitive reports when a private channel is available.

**Maintainer contact (email):** `wongcf22@gmail.com`

- Source of contact: product **author-email** SSOT in [`LICENSE.md`](./LICENSE.md) (Copyright line).  
- Prefer email (or private GitHub security advisories when enabled) for vulnerability details, reproduction steps, and impact.  
- Do not include exploit weaponization guides in public channels.

## Security Design Principles (CIAO)

This project follows **[CIAO](https://github.com/cloudgen/ciao)** / **[CIAO-Lite](https://github.com/cloudgen/ciao-lite)** defensive design. Security-relevant intent:

| Letter | Principle | Security application |
|--------|-----------|----------------------|
| **C** | **Caution** | Fail closed without a valid grok session; fail closed without allowlisted `sudo grok-cli backup` for `/var/grok-cli`. Never print tokens. |
| **I** | **Intentional** | Session check and `sync-auth` stay the invoking login; only deposit/chown/chmod is elevated. `print-sudoers` never writes `/etc`. |
| **A** | **Anti-fragile** | `GROK_HOME` / `GROK_CLI_ROOT` overrides keep tests off production dest; SUDO_USER home used when re-exec'd as root. |
| **O** | **Over-protect** | Narrow Cmnd only (`NOPASSWD: /usr/local/bin/grok-cli backup`); no `cp`/`chmod`/`chown` sudoers tools; Protection Zones. |

Full principles: [CIAO](https://github.com/cloudgen/ciao) · [CIAO-Lite](https://github.com/cloudgen/ciao-lite).

This section is **design posture**, not a third-party certification claim.

## Scope notes

- Elevation is limited to allowlisted `grok-cli backup` under product law.  
- **`setup`** fetches xAI’s published installer (`https://x.ai/cli/install.sh`) as the invoking login (no sudo). It does **not** install grok-cli and does **not** grant extra sudoers. Treat the vendor script as third-party code.  
- Operators must admin-install sudoers fragments after review (`visudo -c`, mode `0440`) **or** have sudoer-adm approve the JSON request.  
- **Install trust tiers for elevation:**
  - **Production:** global managed binary (`/usr/local/bin/grok-cli`, typically root-owned). Prefer `sudo grok-cli install` before durable sudoers.  
  - **Test mode only:** local `~/.local/bin/grok-cli` is **user-rewritable**. Do **not** treat local-only sudoers as production-secure.  
  - `print-sudoers` refuses non-production tiers unless `--allow-test-local` / `ALLOW_TEST_LOCAL_SUDOERS=1`.  
  - **Per-user host paths:** draft `~/.config/grok-cli/sudoers.fragment-<user>` installs to `/etc/sudoers.d/grok-cli-<user>`.  
- **Shared store residual:** `/var/grok-cli/auth.*` are **world-readable** (`0644`) so `sync-auth` needs no sudo. Anyone who can read the host can use those grok credentials. That is intentional for this product (shared login on a host) and is **not** equivalent to keeping tokens `0600` in a private home.  
- Home copies from `sync-auth` return `auth.json` to mode `0600`.  
- Related docs: [`README.md`](./README.md), [`LICENSE.md`](./LICENSE.md), `docs/requirements/requirement-three-layer-privilege-model.md`, `docs/requirements/requirement-grok-auth-backup.md`.
