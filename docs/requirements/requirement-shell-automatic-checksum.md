**file**: docs/requirements/requirement-shell-automatic-checksum.md  
**Status**: Active (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-automatic-checksum`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **integrity Single Source of Truth** for grok-cli channel downloads: after fetching `SCRIPT_URL`, grok-cli **MUST** fetch `${SCRIPT_URL}.sha256` (SHA-256). Human mode **MUST** show companion **link**, expected **value**, and **result**. Match continues. Mismatch aborts. Missing sidecar warns and continues. Optional `CHECKSUM` env is a strict pin (not help/about UX).

### 1.1 Human-facing

**In one sentence:** the one-liner checks a sibling `.sha256` file next to the script when that file exists.

| Box | Meaning | Example |
|-----|---------|---------|
| You | Run curl install as usual | the README one-liner |
| The other role | Publisher ships `src/grok-cli.sha256` | same directory as the ship unit |
| Not this file | Pinning a hex in help | `CHECKSUM` is CI-only |

| Includes | Excludes |
|----------|----------|
| Automatic companion; optional pin | Printing `CHECKSUM` on help/about |

---

## 2. Core Rules / Requirements (Mandatory)

1. Algorithm **MUST** be SHA-256 (`util_sha256_file`).  
2. Automatic mode when `CHECKSUM` is unset: GET `${SCRIPT_URL}.sha256`.  
3. Human: print link, expected, result.  
4. Match → continue. Mismatch → abort non-zero. Missing sidecar → warn, continue.  
5. `CHECKSUM` set → download **MUST** match that hex; mismatch aborts.  
6. **MUST NOT** list `CHECKSUM` on help/about.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Companion path | `src/grok-cli.sha256` (bare hex) |
| URL | `${SCRIPT_URL}.sha256` |

### 2.2 Why This Requirement Exists (CIAO)

- **Principle 1 – Caution**: Do not place a mismatched download.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Mismatch aborts.  
- **Intentional:** Automatic is default.  
- **Anti-fragile:** Missing sidecar does not block a first publish.  
- **Over-protect:** Pin is secondary.

---

## 4. Protection Rule (Sacred)

**MUST NOT**: skip verify while this REQ is Active; print live digest pins as the only Install story; treat same-channel SHA-256 as a signed release.

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Match of companion → install continues |
| AC-2 | Mismatch → non-zero |
| AC-3 | Missing sidecar → warn + continue |
| AC-4 | help/about omit `CHECKSUM` |

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-online-install.md` | Download owner |
| `./src/grok-cli` | Implementation |
| `./src/grok-cli.sha256` | Companion file |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-ONL-02** | `tests/test_online_install.sh` | have |

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-09-02 | Active (1.0.0) | Companion digest for channel install |

**Last Updated**: 2026-09-02  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
