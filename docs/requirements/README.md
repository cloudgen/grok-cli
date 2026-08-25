# Requirements

Authoritative specialized product law for **grok-cli** lives here.

**Current state (2026-08-25):** Specialized **software-development** product. Left genesis. Bootstrap chain is **cli-template → folder-backup → grok-cli**. Registry is populated — see `index.md` (CLI default-interaction is case 3: TTY empty argv and `menu`/`main` show the numbered list; off-TTY empty argv stays Type N help). `setup` installs peer `grok` from x.ai (not grok-cli).

## Product identity (summary)

| Field | Value |
|-------|--------|
| Product / `APP_NAME` | `grok-cli` |
| Version SSOT | ship unit `VERSION=` (do not pin a stale number here) |
| Ship unit | `src/grok-cli` |
| Default install | `~/.local/bin/grok-cli` |
| Install mode | **Local-only** |
| Auth ops | `requirement-grok-auth-backup` — session check / deposit / sync-auth |
| Domain surface | `requirement-domain-grok-cli` — four pillars |
| Peer grok install | `requirement-grok-setup` — `setup` curls xAI installer |
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
4. Online install requirements stay **absent** unless product mode is explicitly changed.  
5. Sole domain SSOT: `requirement-domain-grok-cli.md`.
