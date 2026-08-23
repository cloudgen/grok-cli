**file**: docs/requirements/requirement-class-software-dev.md  
**Status**: Active (Version 1.2.0 – grok-cli identity retarget)  
**Area**: class  
**Key**: `requirement-class-software-dev`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

Declare this workspace as a **software-development** project class and hold the **residual collection** of software-engineering stack facts **not already owned** by more specific Active peer requirements: primary language, toolchain policy, package/test tooling, and runtime OS family.

This file is **class law + residual SSOT**, not a second copy of Type 0 lifecycle, domain backup, output, or storage tables (those stay on peer requirements).

### 1.1 Human-facing

This file says the workspace is a **shippable program** (grok-cli) and records leftover stack facts that no other requirement already owns.

| You | Another role | Not this |
|-----|--------------|----------|
| Read this file to learn the project class and leftover stack (language, tools, “no dest approver”) | Peer requirements own backup ops, install, sudoers grant body, and CLI verbs | A dest approval machine, a second class file, or online-install law |

**Includes:** class membership, residual stack, honest “none” for dest approver and dest fences.  
**Excludes:** inventing an approver account; inventing dest fence rows; duplicating peer backup/install tables.

| Step | What it means | What you type |
|------|---------------|---------------|
| Classify | Agents treat this tree as software-development, not a blank seed. | Open `docs/requirements/requirement-class-software-dev.md` |
| Own-or-point | Stack facts live here until a peer requirement takes them. | Follow the residual ownership table in this file |

---

## 2. Core Rules (Mandatory)

### 2.0 Project class membership

1. **MUST** treat this workspace as **software-development** (shippable software), not genesis-template and not server-maintenance.  
2. **MUST** use basename **`requirement-class-software-dev.md`** as the sole Active class-law file for this class.  
3. **MUST NOT** register an Active `requirement-class-server-maintenance.md` while class is software-development.  
4. **MUST** retain portable harness knowledge; specialized product knowledge lives in this and peer `requirement-*.md` files.  
5. **MUST** apply software-development SSOT/gate posture when claimed (identity, ship unit, precommit when git is used — as applicable).  
5a. When git is used on a **multi-vault host**, **MUST** treat forge push identity as **product repository-user SSOT** (Config `REPO_USER` / project-repository owner), not ambient default SSH face: agents **MUST** run precommit / SSH-profile gates (pre-git report; vault bind via activate or one-shot identity for push). Host vault basenames are **not** product law — portable process lives in harness skills (`skill-commit-check`, `skill-ssh-user-profile`).  
6. **MUST NOT** invent hollow product docs solely to look specialized; collect real values or defer explicitly.

### 2.1 Residual collection principle (SSOT hygiene)

7. **MUST** treat this file as the **default home** for software-stack facts **not owned** by another Active requirement.  
8. **MUST NOT** duplicate full normative tables that already live in a more specific Active requirement. Prefer a **one-line pointer** to the peer requirement key.  
9. When a new specialized requirement **takes ownership** of a topic previously only listed here, **MUST** update this file in the **same change**: remove or shrink the residual entry and point to the new owner.  
10. **MUST NOT** leave contradictory stack facts across this file and peer requirements.

### 2.2 Programming language(s)

11. **MUST** declare at least one **primary programming language** for the ship unit.  
12. **SHOULD** list secondary languages only when they are real product law.  
13. **MUST** state whether the product is primarily: interpreted, compiled, polyglot, or package-multi-language.  
14. **MUST NOT** freeze a marketing product name as if it were the language name.

### 2.3 Compilers, interpreters, and toolchains

15. **MUST** declare the **target toolchain class** used to build or run the product.  
16. **MUST** state version policy as one of: unconstrained · minimum version · range · pinned.  
17. **SHOULD** record whether cross-compilation is in scope.  
18. **MUST** fail closed in CI/docs claims: do not claim “supports all compilers” without tests or explicit unconstrained policy.

### 2.4 Project / package / build tools

19. **MUST** declare the **primary project or package tool** used for dependencies and builds.  
20. **MUST** declare how dependencies are resolved when the ecosystem supports lockfiles.  
21. **SHOULD** name the test runner and linter/formatter **classes** when they are project law.  
22. **MUST NOT** require a secret token or private registry password in this file.

### 2.5 Runtime and platform (residual)

23. **MUST** declare the intended **primary runtime/OS family** when not fully owned by another architecture requirement.  
24. **SHOULD** declare minimum CPU/arch support only when it is real product law.  
25. **MUST** separate **developer machine** toolchain requirements from **end-user runtime** requirements when they differ.

### 2.6 No-hardcode / dual policy (class file)

26. **MUST NOT** hard-code a single product/app brand, one org’s production hostname, or personal owner identity as universal core law.  
27. **MUST** put live product name, repo slug, and concrete stack choices in **Implementation Notes** after collection — complete when Status is Active.  
28. **MUST NOT** store secrets, PATs, or toy credentials in this file.

### 2.7 Implementation Notes (this project)

| Field | Value (grok-cli) |
|-------|---------------------|
| **Project display name** | `grok-cli` |
| **Project class** | software-development |
| **Class requirement basename** | `requirement-class-software-dev.md` |
| **Primary language(s)** | `posix-sh` (`/bin/sh`) |
| **Language role** | primary only — single-file shell ship unit under `src/` |
| **Execution model** | **interpreted** — no compile step |
| **Toolchain / interpreter** | POSIX `/bin/sh` (dash/bash-as-sh compatible subset); no compiler |
| **Toolchain version policy** | **unconstrained** among POSIX sh implementations that pass product tests when present |
| **Cross-compile in scope?** | no |
| **Primary project/package tool** | **none** — no language module system; ship unit is the source |
| **Lockfile policy** | not used |
| **Test runner** | POSIX shell suite under `tests/` when present (`tests/run.sh` pattern) |
| **Linter/formatter** | none as project law (shellcheck optional for maintainers) |
| **Primary runtime / OS family** | POSIX Linux (and compatible UNIX where `/bin/sh` + `tar` + `gzip`/`tar -z` + `mktemp` exist) |
| **Architectures supported** | any arch with POSIX sh and the external tools the script invokes |
| **Git surface** | used when product is published |
| **Ship unit / install** | yes — `src/grok-cli` → `${USER_BIN}/grok-cli` (default `~/.local/bin/grok-cli`); **local-only** install (no online channel) |
| **Product version SSOT** | `VERSION="1.0.0"` hard-assign in `src/grok-cli` |
| **Bootstrap origin** | sibling product **folder-backup**; chain cli-template → folder-backup → grok-cli (domain retarget) |

**Residual ownership table:**

| Topic | Owner | Notes |
|-------|-------|--------|
| Project class membership | **this file** | Fixed |
| Primary language + toolchain policy | **this file** | posix-sh, unconstrained |
| Package/build tool + lockfile | **this file** | none / not used |
| Bootstrap lineage / keep-extend | `requirement-bootstrap-chain` | A=cli-template → B + domain extend |
| Project layout / ship path | `requirement-project-folder` | `src/` + bin targets |
| Type 0 CLI surface / flags / dispatch | `requirement-shell-cli-interface` | Do not duplicate |
| Empty argv Type N help | `requirement-shell-cli-zero-arguments` | Local-only |
| Local self-managed lifecycle | `requirement-shell-local-self-management` | install / uninstall / where-is-me |
| Output SSOT (`out_*`) | `requirement-shell-output-requirements` | Do not duplicate |
| Operator-readable error wording | `requirement-operator-readable-error` | Human-intro-style `[ERROR]` copy; do not duplicate |
| Scratch/cache storage resolve | `requirement-shell-cli-storage` | Do not duplicate |
| Idempotency / re-run safety | `requirement-shell-idempotency` | Do not duplicate |
| Interactive vs non-interactive | `requirement-shell-interactive-vs-noninteractive` | Do not duplicate |
| Modular prefixes / single-file layout | `requirement-shell-modular-function-design` | Do not duplicate |
| POSIX sh coding style | `requirement-shell-script-coding` | `set -u`, `out_*`, fail-closed elev; do not duplicate |
| Privilege layers + sudoers **files** (emit/install/fail-closed) | `requirement-three-layer-privilege-model` | Type 0 + narrow Type 1 deposit; §2.3 sudoers workflow SSOT |
| JSON sudoer file (grant body) | `requirement-sudoer-json-file` | `{{PRJ_NAME}}` only; no `cp`/`mkdir`/OS-tool commands |
| Grok auth **backup operations** | `requirement-grok-auth-backup` | Session check / deposit / sync-auth (not domain) |
| Domain surface (verbs, help, about) | `requirement-domain-grok-cli` | Four pillars only; ops pointer |
| Actor / role / subject / approver | **this file** (residual) | **considered — no dest approver and no approval subject**. This product has no dest approval machine. **MUST NOT** invent an approver. |
| Dest fence conditions | **this file** (residual) | **considered — no dest fence conditions**. No dest Fence table. **MUST NOT** invent a dest fence. |
| Online install / remote self-management / companion checksum | **intentionally absent** | Absent on A; remain absent on B |

---

## 3. Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional**: Class and stack choices are explicit, not assumed from folder names.  
- **CIAO Principle 5 – SSOT**: Residual stack facts have one home until specialized requirements take ownership.  
- **CIAO Principle 1 – Caution**: Toolchain policies are declared; agents do not invent compilers or online install.  
- **CIAO Principle 21 – Dual Policies**: Portable core; filled Implementation Notes.  
- **CIAO Principle 4 (O) + Principle 20**: Protection Rule against dual stack SSOTs and wrong-class pollution.

---

## 4. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Assume toolchain and package tools are missing until declared and verified.  
- **Intentional**: Residual collection is deliberate — not a dump of every possible tool.  
- **Anti-fragile**: Unconstrained POSIX sh policy survives multi-env runs when tests pass.  
- **Over-protect**: Protection rule prevents dual stack SSOTs and genesis/class confusion.

---

## 5. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Delete this file while the workspace remains **software-development** with other Active product requirements.  
2. Rename the specialized basename away from `requirement-class-software-dev.md` without an explicit class-model change.  
3. Hard-code secrets, personal owner identity, or production host FQDNs into core rules as universal law.  
4. Duplicate full peer requirement bodies into this residual section.  
5. Leave Implementation Notes as hollow stubs when Status claims Active.  
6. Reintroduce Active **online-install** / remote **self-update** / **self-uninstall** / channel **checksum** law without explicit user order (product is **local-only** by design).  
7. Treat this file as server-maintenance allowlist law, or register an Active server-maintenance class file in parallel.  
8. Invent a second primary language SSOT that contradicts peer modular/CLI requirements.

**Violating any of these is considered a critical regression.**

---

## 6. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Active registered `requirement-class-software-dev.md` matches software-development class |
| AC-2 | Primary language + toolchain policy + package tool declared in Implementation Notes (complete) |
| AC-3 | Residual ownership table honest: no silent dual SSOT with peer REQs |
| AC-4 | Core rules remain free of frozen secret/host hardcodes |
| AC-5 | No class file conflict with `requirement-class-server-maintenance` |
| AC-6 | Ship unit identity (posix-sh single-file, local install) consistent with peer shell REQs |
| AC-7 | Online install package **absent** from Active registry by design |

---

## 7. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-bootstrap-chain` | Lineage A=cli-template → B=grok-cli (domain retarget) |
| `requirement-project-folder` | Layout and install locations |
| `requirement-shell-cli-interface` | Command surface, flags, dispatch |
| `requirement-shell-cli-zero-arguments` | Type N empty argv |
| `requirement-shell-local-self-management` | Local install lifecycle |
| `requirement-shell-output-requirements` | `out_*` SSOT |
| `requirement-operator-readable-error` | Operator error wording |
| `requirement-shell-cli-storage` | Scratch/cache resolve |
| `requirement-shell-idempotency` | Re-run safety |
| `requirement-shell-interactive-vs-noninteractive` | Mode policy |
| `requirement-shell-modular-function-design` | Prefixes / single-file modularity |
| `requirement-shell-script-coding` | POSIX sh coding style |
| `requirement-three-layer-privilege-model` | Privilege + working with sudoers fragment files |
| `requirement-sudoer-json-file` | JSON sudoer file body (`{{PRJ_NAME}}` only) |
| `requirement-grok-auth-backup` | Grok auth backup operations SSOT |
| `requirement-domain-grok-cli` | Domain four pillars |
| `docs/requirements/index.md` | Registry SSOT |

---

## 8. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active | Specialized class law for folder-backup (left genesis; then named selfmanaged as origin) |
| 2026-08-13 | Active | Origin retarget: A=cli-template → B=folder-backup |
| 2026-08-15 | Active | Residual: JSON sudoer file → `requirement-sudoer-json-file` |
| 2026-08-19 | Active (1.1.0) | Residual: **considered — no dest approver and no approval subject**; **considered — no dest fence conditions**. §1.1 Human-facing. Version SSOT note 1.9.0. |
| 2026-08-22 | Active (1.2.0) | Identity retarget to grok-cli; ops residual → grok-auth-backup; domain → grok-cli. Version SSOT 1.0.0. |

---

**Last Updated**: 2026-08-22  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
