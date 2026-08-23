**file**: docs/requirements/requirement-shell-interactive-vs-noninteractive.md  
**Status**: Active (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-interactive-vs-noninteractive`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for how grok-cli behaves in **interactive** (human + TTY) versus **non-interactive** (automation, CI/CD, pipes, `--json` / often `--quiet`) environments.

---

### 1.1 Human-facing

Without a TTY, grok-cli will not wait for yes/no. Use `--force` for uninstall and draft remove. The numbered start list (`grok-cli menu` / `main`, when claimed) also **MUST NOT** appear off-TTY — that is `requirement-shell-cli-default-interaction` (not empty argv).

| You | Another role | Not this |
|-----|--------------|----------|
| CI uses `--force` / `--json` | Interactive confirm on a real TTY | Live `[ -t` inside helpers |

**Includes:** TTY/JSON/quiet confirm policy. **Excludes:** sudo password prompts.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Remove a draft in CI | Non-interactive needs `--force` | `grok-cli remove-project-sudoers --force` |


## 2. Core Rules / Requirements (Mandatory)

### 2.1 Definitions

| Mode | Definition |
|------|------------|
| **Interactive** | Human + usable TTY; confirmations allowed when not overridden by machine flags |
| **Non-interactive** | No human available: CI, scripts, pipes, `--json` (and often `--quiet`). **Must never hang** waiting for input |

### 2.2 Detection (mode SSOT)

| Signal | Variable / check | Meaning |
|--------|------------------|---------|
| TTY | `TTY=1` when stdin **and** stdout are terminals | Interactive UX possible |
| Quiet | `QUIET=1` | Suppress non-essential human chatter |
| JSON | `JSON=1` (implies quiet) | Machine output; no human hang |
| Debug | `DEBUG=1` | Extra stderr diagnostics |
| Force | `FORCE=1` | Skip confirms / force reinstall where documented |

Rules:

1. **Measure `[ -t 0 ]` and `[ -t 1 ]` for interactive capability in the main process, outside functions** (script top-level or a direct setter that assigns `TTY`). Default `TTY=0`; set `TTY=1` only when both are terminals.  
2. `prompt_*`, `out_*` confirm paths, and `about` **MUST consume `TTY`**. **MUST NOT** re-test live `[ -t` inside those helpers as the policy gate.  
3. Prompt decisions **MUST** use shared `prompt_*` helpers — not ad-hoc `read` in domain logic.  
4. After flags are parsed in `app_main`, subsequent code **MUST** see updated mode globals.  
5. Do **not** invent a second parallel mode system per command.

**Complete `prompt_yes_no` sample** (consume `TTY` / `JSON` / `QUIET`; not live `[ -t`):

```sh
prompt_yes_no() {
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${TTY:=0}"
    message="$1"
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        return 1
    fi
    if [ "${TTY}" -ne 1 ]; then
        return 1
    fi
    out_msg_n "${message} (y/N)? "
    answer=""
    read -r answer || true
    case "${answer}" in
        [Yy]*|[Yy][Ee][Ss]*) return 0 ;;
        *) return 1 ;;
    esac
}
```

**Complete `prompt_ask` sample** (same consume-`TTY` rule):

```sh
prompt_ask() {
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${TTY:=0}"
    message="${1-}"
    default="${2-}"
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ] || [ "${TTY}" -ne 1 ]; then
        printf '%s' "${default}"
        return 0
    fi
    out_msg_n "${message}: "
    answer=""
    read -r answer || true
    if [ -z "${answer}" ]; then
        printf '%s' "${default}"
    else
        printf '%s' "${answer}"
    fi
}
```

### 2.3 Behavioral matrix (this product)

| Action | Interactive | Non-interactive |
|--------|-------------|-----------------|
| `uninstall` | Confirm unless `--force` | **Fail closed** without `--force` (`confirm_required`) |
| `install` | May inform; no required confirm for first install | Proceed without hang |
| `backup` | May show progress via `out_*` | No prompts; fail loud on missing operands / sudo failure |
| `print-sudoers` | Print fragment | Print fragment (stdout/file); no `/etc` write |
| `generate-sudoer-request` | May show path + verify via `out_*` | No prompts; write + verify; no hang |
| `submit-sudoer-request` | May show detect/submit via `out_*` | No prompts; fail closed if sudoer-cli / inbound missing; no hang |
| Missing required operand | Clear error | Clear error; non-zero exit |

### 2.4 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product** | `grok-cli` |
| **No curl\|sh auto-install path** | Local-only; non-interactive does not mean Type O install-ensure |
| **Prompt helper** | `prompt_yes_no` for uninstall (and any future destructive confirm) |

### 2.5 Why This Requirement Exists (CIAO)

- **Principle 16 – Interactive vs Non-Interactive**  
- **Principle 1 – Caution**: Never hang automation  
- **Principle 14 – Traceability**: Errors visible under quiet/json contracts

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail closed on destructive ops without force in non-interactive.  
- **Intentional:** One mode SSOT.  
- **Anti-fragile:** CI-safe.  
- **Over-protect:** No bare `read` in domain paths.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Hang on stdin in non-interactive/json modes.  
2. Auto-yes destructive uninstall without `--force` in non-interactive mode.  
3. Scatter unguarded `read` calls outside `prompt_*`.  
4. Re-test live `[ -t 0 ]` / `[ -t 1 ]` inside `prompt_*` as the interactive-capability gate (helpers consume `TTY`).  
4. Treat non-interactive as license to skip required validation.

**Violating this rule is a critical interaction-mode regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Non-interactive uninstall without force fails closed |
| AC-2 | JSON mode never prompts |
| AC-3 | Backup never hangs waiting for optional confirm by default |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-cli-interface` | Flags |
| `requirement-shell-local-self-management` | Uninstall confirm |
| `requirement-shell-output-requirements` | Quiet/json emission |
| `docs/requirements/index.md` | Registry |

---

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active | Interactive vs non-interactive for folder-backup |

---

**Last Updated**: 2026-08-15  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
