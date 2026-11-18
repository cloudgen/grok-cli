**file**: docs/requirements/requirement-actor-role-subject.md  
**Status**: Active (Version 1.0.1)  
**Area**: class  
**Key**: `requirement-actor-role-subject`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This file is the light who-is-who catalog for grok-cli. It names who runs each family of commands, in what role, and for whom. This product has no dest review, so the table has three columns: Actor, Role, Subject. Subject is **None** on every row.

The class file points here. It does not print this table.

**Out of scope:** command text and flags (`requirement-shell-cli-interface`); menu numbers (`requirement-shell-cli-default-interaction`); the narrow backup grant (`requirement-three-layer-privilege-model`); what each verb does (`requirement-domain-grok-cli`, `requirement-grok-auth-backup`, `requirement-grok-setup`).

### 1.1 Human-facing

This login runs grok-cli. There is no second person who stamps a request.

| You | Another role | Not this |
|-----|--------------|----------|
| This login, in one of four roles | Nobody else approves the command | An approver account, a dest queue, a Submitter column |

**Includes:** installer, operator, self-manager, and tester. **Excludes:** an approver column; inventing a dedicated review account.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Install this program | This login, installer, subject None | `grok-cli install` |
| Open the daily menu | This login, operator, subject None | `grok-cli` |
| Refresh this program | This login, self-manager, subject None | `grok-cli self-update` |
| Exercise a fixture | This login, tester, subject None | `grok-cli rc-test --rc-root "$tmpdir" --rc bashrc --case create` |

---

## 2. Core Rules (Mandatory)

### 2.1 Table

| Actor | Role | Subject |
|-------|------|---------|
| This login | installer: checkout `install`, `uninstall`, `where-is-me`; off-terminal empty argv places the program | None |
| This login | operator: `menu` / `main`, `help`, `version`, `about`, `run`, `check-session`, `setup`, `update-grok`, `reinstall`, `backup`, `sync-auth`, `sync-auth-from-remote`, `sync-auth-to-remote`, `sync-to-remote`, `add-crontab`, `print-sudoers`, `print-sudoers-install-script`, `remove-project-sudoers`, `generate-sudoer-request`, `submit-sudoer-request` | None |
| This login | self-manager: `version-check`, `self-update`, `self-uninstall` | None |
| This login | tester: `rc-test`; test switches `--uname-s` and `--uname-a` | None |

1. The printed table **MUST** be these three columns only. **MUST NOT** add Submitter or Approver.
2. Every routed family a person runs **MUST** appear on one row above. Help and install stay on this table with Subject **None**.
3. Subject **MUST** stay **None**. A command is not a dest request for another person.
4. The narrow `sudo grok-cli backup` deposit is still this login in the operator role. That grant is not an approver and not a second actor.
5. If a dest review machine is later implemented, this three-column file **MUST** be replaced by the full catalog. **MUST NOT** keep this table as that coverage. **MUST NOT** invent that machine in this change.

### 2.2 Implementation Notes

| Item | Value |
|------|--------|
| Product | grok-cli |
| Dest review | None |
| Columns | Actor, Role, Subject |
| Actor | This login |
| Roles | installer, operator, self-manager, tester |
| Subject | None |
| Proof | **TP-ARS-01** have (`tests/test_cli.sh` reads this table) |

---

## 3. Design Principles

- **Caution:** No dest review means no invented reviewer.
- **Intentional:** Four roles cover the families people run.
- **Anti-fragile:** Subject stays None when a later verb is added to an existing family.
- **Over-protect:** Three columns. The backup grant does not grow an approver.

---

## 4. Protection Rule

**MUST NOT** add an Approver column, add a Submitter column, invent an approver account, move this table back onto `requirement-class-software-dev`, or mark **TP-ARS-01** have before the suite asserts the three columns and Subject **None**.

---

## Under command line for normal user only

On Termux, Git Bash, and Windows cmd this login still holds every role in §2.1. Backup, sync-auth, and sudoers stay unused on that class (the menu hides them). The installer, self-manager, tester, and the rest of the operator family still run as this login.

| MUST | MUST NOT |
|------|----------|
| Keep this login as the only actor | Enable an admin approver or a dedicated review account on that class |
| Leave backup and sudoers unused on that class | Call those unused rows a different person |

**This requirement:** the who-is-who table does not grow a root actor for Termux, Git Bash, or Windows cmd.

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | The table has Actor, Role, and Subject only (**TP-ARS-01**) |
| AC-2 | Install and help are present and Subject is **None** |
| AC-3 | The file does not name an approver account |
| AC-4 | `requirement-class-software-dev` points here and does not reprint the table |

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-ARS-01** | `tests/test_cli.sh` | have — three columns; install and help; Subject None; no Approver column |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`.

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-class-software-dev.md` | Points here; does not own the table |
| `docs/requirements/requirement-shell-cli-interface.md` | Verb families this table assigns |
| `docs/requirements/requirement-three-layer-privilege-model.md` | Narrow backup grant; not an approver |

---

## Terminologies

### Actor / role / subject

**Definition:** Actor / role / subject is the light catalog for a command-line program that has no dest approver: who runs a verb, in what role, and for whom. The printed table has three columns — Actor, Role, Subject. It must not grow an Approver column.

**Human daily-life explanation:** Actor / role / subject is the short who-is-who list for a kitchen that has no stamp person: who cooks, in what job, and whose cake it is. You still write the list. You do not add a fake teacher signature.

**Daily-life example:** A home bake has a mixer (actor), the job “mix” (role), and None for whose form it is (subject) because nobody dest-submits. You do not invent a vice-principal so the sheet looks official.

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-11-17 | Active 1.0.0 | Light catalog. This login is installer, operator, self-manager, and tester. Subject is None. No approver. |
| 2026-11-18 | Active 1.0.1 | Tester row sample uses `rc-test --rc-root` and `--rc` |

---

**Last Updated**: 2026-11-18  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
