# Lessons — grok-cli

Durable failure modes. **Always re-check on product review.**

| ID | Mode | Prevention | Status |
|----|------|------------|--------|
| L-TYPE-N-01 | TTY empty argv becomes install-ensure (menu stolen) | TTY → `app_default`; off-TTY Type O only; TP-CLI-07 PTY | open watch |
| L-ARGV-01 | Off-TTY empty argv draws or hangs the numbered menu | Off-TTY empty argv is Type O ensure; `menu` off-TTY is help; TP-CLI-07/13 | open watch |
| L-ARGV-02 | Overlay flags-only (`--debug`) treated as help because empty argv was `$# -eq 0` | Empty argv = no command token after flag parse; TP-CLI-29 | open watch |
| L-ONLINE-01 | Drop channel / dual-mode matrix while advertising `curl\|sh` | `requirement-shell-online-install` matrix; TP-ONL-* · TP-CLI-04/10 | open watch |
| L-UNIN-01 | Non-interactive uninstall succeeds without force | TP-LC-05 confirm fail-closed | open watch |
| L-INST-MODE-01 | Install leaves `0711`/`0700` (chmod +x after mktemp) so non-owners cannot run shell ship unit | absolute `chmod 0755` + heal on reinstall; TP-LC-09/10; local-self-management §2.3.1 | open watch |
| L-DEPOSIT-01 | Unprivileged write to `/var/grok-cli` or silent deposit success without grant | fail-closed + `sudo grok-cli backup`; TP-GROK-CLI-12 | open watch |
| L-AUTH-01 | Backup without valid grok session, or printing tokens | session gate; never print JWT/refresh; TP-GROK-CLI-03..06 | open watch |
| L-AUTH-02 | Elevated `backup` probes `/root/.grok` (sudo `env_reset`) then calls a valid grant “refused” | Pin `HOME`/`GROK_HOME` to `SUDO_USER`; grant-present child fail → `grok login`; TP-GROK-CLI-39/40 | open watch |
| L-SYNC-01 | sync-auth uses sudo or leaves home `auth.json` world-readable | Type 0 only; dest 0600; TP-GROK-CLI-09/10 | open watch |
| L-SUDOERS-01 | Auto-write `/etc/sudoers.d` or `NOPASSWD: ALL` fragment | print-only + install-script handoff; narrow Cmnd; TP-GROK-CLI-01/02/14 | open watch |
| L-SUDOERS-02 | Local `~/.local/bin` treated as production-secure for sudoers (user rewrites binary/stage → jailbreak) | trust tier **S13**; `--allow-test-local`; global preferred; TP-GROK-CLI-01/01b | open watch |
| L-SUDOERS-03 | Confuse draft removal with host elev removal (or Type 0 delete under `/etc`) | `remove-project-sudoers` draft-only + admin script uninstall; TP-GROK-CLI-15 | open watch |
| L-SUDOERS-04 | Shared `/etc/sudoers.d/{{APP_NAME}}` basename overwrites another user’s fragment on multi-user host | Per-user draft + installed `{{APP_NAME}}-<user>`; multi-draft list/choose; TP-GROK-CLI-14/15/15b | open watch |
| L-SUDOERS-05 | Generate fragment as wrong user (`id -un` mismatch with backup operator) | Generate as elevating login; User lines = invoking user; review fragment before install | open watch |
| L-PUSH-VAULT-01 | Bare `git push` uses wrong active SSH vault when default face ≠ repository-user | Pre-git report + `GIT_SSH_COMMAND -i` / activate matching vault (SK-COMMIT-CHECK §3.3); incident 20260810-001 | open watch |
| L-OVERWRITE-01 | Accidental skip of auth snapshot overwrite (backup must replace same basenames) | TP-GROK-CLI-08 | open watch |
| L-SETU-01 | `set -u` crash with unset HOME | TP-CLI-11 | open watch |
| L-STOR-01 | Shared world-writable storage / stage roots not matching sudoers wildcards; shm cache looking like a ram-drive project folder | util_resolve_storage; preferred `/dev/shm/cache/cache-${APP_NAME}`; TP-CLI-12 · TP-GROK-CLI-02 | open watch |
| L-INBOUND-01 | Submit probes only home `sudoer-approving` (or Type 0 `mkdir` inbound) | Public inbound first (`/var/sudoer-cli/sudoer-request`); no mkdir; TP-GROK-CLI-21/21b | open watch |
| L-SUDOERS-06 | `[OK] submit` inbound drops `backup` while purpose still names the grant | Inbound is sibling **re-encode**; count `commands[].args` before approve; INC-20260817-001 | open watch |
| L-OUTPUT-01 | Submit fail-closed `[ERROR]` uses inbound/verb/sibling-re-encode jargon; operator cannot act | Fatal submit errors must name the missing grant, do-not-approve request id, and next command (`generate-sudoer-request`); **requirement-operator-readable-error**; TP-25*; incomplete inbound JSON is **not** a standing expected class (owner); INC-20260817-002 | open watch |
| L-TEST-REVIEW-01 | Green emit TP-22 + stub TP-20 + S14 Pass miss sibling decode drop | Assert inbound after **real** sudoer-cli; pretty + compact fixtures; do not treat `tests/run.sh` PASS as grant fidelity; INC-20260817-001 | open watch |
| L-PROMPT-CAPTURE-01 | TTY menu `sync-auth-from-remote` row (main **3**; was pick 4 before 1.8.0) hangs because `_spec=$(prompt_ask …)` swallows the prompt | **MUST NOT** `$()` `prompt_ask` / any `read` helper; current-shell `PROMPT_ASK_VALUE`; TP-CLI-15 · TP-GROK-CLI-34; mold §8.1.5; INC-20260902-001 | open watch |
| L-NEX-01 | JSON/sudoers grant samples freeze a session Unix login | Samples use `id -un`; TP-CLI-18; **PO-NON-EXPOSE-LOCAL-MACHINE** | open watch |
| L-MENU-01 | Termux / Git Bash / Windows cmd main menu still lists backup / sync-auth / sudoers (or omits the not-available line) | Hide those rows; print `backup, sync-auth and sudoers features are not available in {{label}}.`; TP-CLI-19 | open watch |
| L-MENU-02 | Logged-in main menu still lists sync-auth / sync-auth-from-remote, or the logged-in not-available line replaces the host line | Hide those two rows; **append** `sync-auth and sync-auth-from-remote features are not available for logged-in environment.`; TP-CLI-20 | open watch |
| L-MENU-03 | Termux numbered menu freezes after the header (grok/proot ignores SIGTERM; `timeout` without `-k` waits forever; reprint re-probes) | Always bound `grok -p hello`; GNU `timeout -k` or POSIX watchdog; reuse `GC_SESSION_STATUS_CACHE` on reprint; TP-GROK-CLI-44/45 · TP-CLI-21; **INC-20260907-001** | open watch |
| L-REMOTE-01 | TTY `sync-auth-from-remote` forgets the last SPEC, or default is not at the end of the prompt | Persistence `preferred-remote`; prompt `[SPEC]`; Enter uses default; TP-GROK-CLI-41 | open watch |
| L-SYNC-02 | `sync-auth` / `sync-auth-from-remote` overwrite a grok home that is already logged in | Live `grok -p hello` first (or menu cache); skip with `No sync-auth for logged-in environment.`; TP-GROK-CLI-42/43 | open watch |

**Bootstrap parent lessons:** cli-template still owns output SSOT, no basename gate, storage isolation, checkout `install`. selfmanaged owns channel `SCRIPT_URL`, Type O off-TTY empty argv, companion digest, `version-check` / `self-update` / `self-uninstall`. TTY numbered menu is grok-cli case 3 (not selfmanaged).
