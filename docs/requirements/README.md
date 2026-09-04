# Requirements

Authoritative specialized product law for **grok-cli** lives here.

**Current state (2026-09-02):** Specialized **software-development** product. Left genesis. Bootstrap: **cli-template → folder-backup → grok-cli** (domain) **plus** selfmanaged online package. Case 3: TTY empty argv and `menu`/`main` show the numbered list; off-TTY empty argv is Type O install-ensure (not help). `setup` installs peer `grok` (not `install.sh`). Dual-mode install: `curl|sh` primary; checkout `install` secondary.

## Product identity (summary)

| Field | Value |
|-------|--------|
| Product / `APP_NAME` | `grok-cli` |
| Version SSOT | ship unit `VERSION=` (do not pin a stale number here) |
| Ship unit | `src/grok-cli` |
| Default install | `~/.local/bin/grok-cli` |
| Install mode | **Dual-mode** (channel primary; checkout `install` secondary) |
| Online channel | `requirement-shell-online-install` · `requirement-shell-self-management` · `requirement-shell-automatic-checksum` |
| Auth ops | `requirement-grok-auth-backup` — session check / deposit / sync-auth |
| Crontab ops | `requirement-grok-crontab` — `add-crontab` per-login timers |
| Domain surface | `requirement-domain-grok-cli` — four pillars |
| Peer grok install | `requirement-grok-setup` — `setup` fetches xAI channel + artifact (does not exec `install.sh`) |
| Termux host writing | `requirement-shell-termux-coding` — `PREFIX`, Termux `pkg`, `noexec` tmp; folder classes on `requirement-project-folder` |
| JSON sudoer file | `requirement-sudoer-json-file` — grant is `grok-cli backup` only; no `cp`/`mkdir`/`chmod` |

## Class requirement gate

| Class | Required class file |
|-------|---------------------|
| software-development | `requirement-class-software-dev.md` (**Active**) |
| genesis-template | N/A — this workspace is no longer genesis |

## Purpose

- **Plan** designs work by reading and updating these docs.  
- **Implement** delivers code that **traces** to these requirements.  
- **Review** verifies delivery against requirements and CIAO checklists.

## Layout

| Path | Role |
|------|------|
| `docs/requirements/index.md` | Registry of all requirements — keep in sync |
| `docs/requirements/requirement-*.md` | CIAO-style project requirements |

## Status values

Typical: `draft` · `Active` · `approved` · `in-progress` · `done` · `deprecated` · `superseded`

## Rules

1. Never invent paths — verify on disk.  
2. Class files only via class process; non-class via create-specific process.  
3. Never dump harness inventories into this versioned surface.  
4. Online install requirements are **Active** (dual-mode). Do not drop them without updating this registry and the dual-mode matrix.  
5. Sole domain SSOT: `requirement-domain-grok-cli.md`.
