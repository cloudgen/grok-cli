**file**: docs/requirements/requirement-shell-output-requirements.md  
**Status**: Active (Version 1.1.0)  
**Area**: shell  
**Key**: `requirement-shell-output-requirements`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **all CLI output** of grok-cli: human messages, machine JSON, channel split (stdout vs stderr), and mode behavior (normal / quiet / JSON / debug).

Inherited architecture from bootstrap parent **cli-template** (`out_*` family); retargeted for this product’s identity and domain messages.

---

### 1.1 Human-facing

All grok-cli messages go through `out_*`. `--json` is machine stdout; errors still on stderr.

| You | Another role | Not this |
|-----|--------------|----------|
| Scripts use `--json` | Humans see `[ERROR]` / `[OK]` | Raw `echo` for product messages |

**Includes:** quiet/json/debug. **Excludes:** sudoers body.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Script a version | JSON on stdout | `grok-cli --json version` |


## 2. Core Rules / Requirements (Mandatory)

### 2.1 Sacred core rule

**All user-facing and machine-facing product output MUST go through the centralized output system.**

| Forbidden outside the output module | Prefer |
|-------------------------------------|--------|
| Raw `echo` / bare `printf` for **user messages** | `out_info`, `out_success`, `out_warn`, `out_error`, `out_plain`, … |
| Direct `printf` of JSON from command logic | `out_json` / `out_json_error` |
| Ad-hoc `echo >&2` diagnostics | `out_warn` / `out_error` / `out_debug` |
| Second parallel print helper that bypasses mode guards | Extend `out_text` / wrappers only |

### 2.1.1 Allowed `printf` / `echo` exceptions

| Exception class | Rule |
|-----------------|------|
| **A. Inside output SSOT** | Only `out_text`, `out_json`, and `out_json_error` may `printf` to fd 1/2 for product human or JSON lines |
| **B. Function return-via-stdout** | Helpers may `printf '%s' "$value"` solely for `$(…)` capture (data return, not UI) |
| **B2. Identity nametag (`util_app_ident`)** | Class B return of live `APP_NAME(APP_VERSION)`. TTY SGR 1/3 is part of that token (consumed by `out_info "$(util_app_ident) …"`). Not a second human printer. |
| **C. File I/O (redirected)** | Writing config/sudoers draft files is file mutation; user-visible status still via `out_*` |
| **D. Tool protocol / computation pipes** | e.g. feeding `tar`/`gzip`/`sha256sum` via pipes; product status still via `out_*` |
| **E. Command-sub fallbacks** | Logic defaults only (`id -un \|\| echo "unknown"`) |

### 2.2 Output function catalog

| Function | Purpose | Typical channel | Quiet | JSON |
|----------|---------|-----------------|-------|------|
| `out_text` | SSOT for human levels | Level-dependent | Filters | Suppress all human levels |
| `out_info` | Informational | stdout | Suppress | Suppress human |
| `out_success` | Success / OK | stdout | Suppress | Suppress human |
| `out_warn` | Warning | stderr | Should still show | Prefer structured status when designed |
| `out_error` | Error | stderr | Always show (human) | Prefer `out_json_error` / `out_die` |
| `out_die` | Fatal + exit 1 | stderr (+ JSON error when JSON) | Always | Emits JSON error then exits |
| `out_plain` | Plain text, no prefix | stdout | Suppress under quiet | Suppress under JSON |
| `out_menu_choice` | Numbered menu row; TTY explain *italic* + light gray (SGR 3+37; default CLI main menu style) | stdout | Suppress under quiet | Suppress under JSON |
| `out_msg_n` | Prompt fragment without newline | stdout (current-shell prompts; **MUST NOT** `$()` `prompt_ask`) | Suppress under quiet/json | Never for machines |
| `out_json` | Machine success/status object | stdout | N/A | Only when `JSON=1` |
| `out_json_error` | Machine error object | as designed for fatal path | N/A | Only when `JSON=1` |

### 2.3 Channel contract

| Channel | Allowed content (via `out_*` only) |
|---------|-------------------------------------|
| **stdout (fd 1)** | Human info/success/plain in normal mode; **exactly one** JSON value in JSON mode for success/status |
| **stderr (fd 2)** | Errors, warnings, debug/diagnostics |

Rules:

1. Fatal paths use `out_die` / `out_json_error`.  
2. JSON mode: no colors, banners, or progress mixed into stdout JSON.  
3. Capture pattern: `grok-cli --json <cmd> 2>err.log`.  
4. **No secrets** on either channel (tokens, passwords, private keys, full private key material).  
5. Class-B `$()` is for **pure data** helpers that never `read`. **MUST NOT** capture `prompt_ask` / `prompt_yes_no` / any `read` helper (INC-20260902-001).

### 2.4 Mode behavior

| Mode | Contract |
|------|----------|
| Normal (TTY) | Prefixed human messages; colors only when TTY and not quiet/json |
| Quiet | Suppress info/success/plain; still show errors (and should show warnings) |
| JSON | Force quiet; structured JSON only on success path; structured errors on failure |
| Debug | Extra diagnostics on stderr; suppressed under JSON purity rules for stdout |

### 2.5 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product** | `grok-cli` |
| **Ship unit** | `src/grok-cli` |
| **Human prefixes** | `[INFO]`, `[OK]`, `[WARN]`, `[ERROR]` (or equivalent consistent set) |
| **Domain messages** | Backup progress/results and sudoers-print status **must** use `out_*` |
| **Bootstrap inheritance** | Same `out_*` family as cli-template |

### 2.6 Why This Requirement Exists (CIAO)

- **Principle 5 – Single Source of Output**  
- **Principle 14 – Security & Traceability** (stdout vs stderr)  
- **Principle 1 – Caution** (fail loud, never silent corruption of JSON pipes)

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Never hide fatal errors under quiet.  
- **Intentional:** One emitter family.  
- **Anti-fragile:** JSON/human/quiet all work offline.  
- **Over-protect:** Do not “simplify” by scattering echo.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Introduce a second product messaging stack beside `out_*`.  
2. Print user-facing banners with raw `echo` outside allowed exceptions.  
3. Mix human text into JSON stdout success paths.  
4. Log secrets or private key material.  
5. Remove quiet/json contracts for “simplicity.”  
6. Capture `prompt_ask` / any `read` helper with `$()` (INC-20260902-001).  
7. Draw a claimed numbered menu off **default CLI main menu style** — **MUST NOT** print numbered-menu explain unstyled on a TTY (it **MUST** be *italic* and light gray via `out_menu_choice`, SGR **3** + **37**). **MUST NOT** a second house look (`out_menu_row`, SGR 90).

**Violating this rule is a critical output SSOT regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | All product messages route through `out_*` |
| AC-2 | JSON mode produces structured success/error without human interleave |
| AC-3 | Quiet still surfaces errors |
| AC-4 | Domain backup messaging uses the same SSOT |
| AC-5 | Ship unit does not `$()` `prompt_ask` (INC-20260902-001; TP-CLI-15) |
| AC-6 | Numbered TTY menu explain is italic + light gray via `out_menu_choice` (SGR 3+37; TP-CLI-17) |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-cli-interface` | Modes and flags |
| `requirement-shell-cli-default-interaction` | Numbered TTY menu look (`out_menu_choice`) |
| `requirement-shell-interactive-vs-noninteractive` | Prompt vs auto |
| `requirement-domain-grok-cli` | Domain message payloads |
| `requirement-operator-readable-error` | Operator error **wording** (human-intro style) |
| `docs/requirements/index.md` | Registry |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active | Output SSOT for folder-backup |
| 2026-09-02 | Active (1.0.1) | `prompt_ask` UI off class-B capture fd; INC-20260902-001 |
| 2026-09-02 | Active (1.0.2) | Ban `$()` of `prompt_ask`; class B is data-only |
| 2026-09-03 | Active (1.0.3) | `out_menu_row`: numbered list explain text is light gray italic on TTY |
| 2026-09-03 | Active (1.1.0) | `out_menu_choice` (replaces `out_menu_row`); TTY explain SGR **3** + **37**; default CLI main menu style |

---

**Last Updated**: 2026-09-03 (1.1.0 — `out_menu_choice`; SGR 3+37)  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
