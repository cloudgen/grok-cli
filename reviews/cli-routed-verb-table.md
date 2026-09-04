# Live command list — grok-cli

This file is the kept list of commands `app_main` actually runs: name, function, who may run it, date on that function’s comment, and the same one-line explanation `help` prints. It is **not** help text as the routing inventory.

**Ship unit:** `src/grok-cli`  
**Dispatcher:** `app_main`  
**Scan date:** 2026-09-03  
**Mode:** incremental (channel install + Type O off-TTY empty argv)  
**Copied:** 21 live + 1 not-yet-wired · **Re-checked:** `ensure` (`inst_channel_ensure`) · `version-check` · `self-update` · `self-uninstall`  
**Inventory:** dispatcher `case "${COMMAND}"` — not `app_help` for routing; help one-liners copied into **human-readable**

## Live commands

| verb | handler | privilege | last modified date | human-readable |
|------|---------|-----------|--------------------|----------------|
| about | `app_about` | you (Type 0) | 2026-08-03 | `about: Show diagnostics (incl. sudoers trust tier)` |
| add-crontab | `gc_add_crontab` | you (Type 0) | 2026-09-02 | `add-crontab: Add backup and sync-auth jobs to this login's crontab` |
| backup | `gc_backup` | change-the-computer (Type 1) | missing | `backup: Push ~/.grok/auth.* to /var/grok-cli` |
| check-session | `gc_check_session` | you (Type 0) | missing | `check-session: Confirm grok is logged in` |
| generate-sudoer-request | `gc_generate_sudoer_request` | you (Type 0) | 2026-08-17 | `generate-sudoer-request: Write a JSON grant you can read` |
| help | `app_help` | you (Type 0) | missing | `help: Show this help` |
| main | `app_default` | you (Type 0) | 2026-09-03 | `main: Same as menu` |
| menu | `app_default` | you (Type 0) | 2026-09-03 | `menu: Show the numbered list of live commands` |
| install | `inst_local_install` | you (Type 0) | 2026-08-09 | `install: Install grok-cli (root→global, user→~/.local/bin)` |
| version-check | `ver_check` | you (Type 0) | 2026-09-02 | `version-check: Compare local vs remote VERSION on SCRIPT_URL` |
| self-update | `inst_self_update` | you (Type 0) | 2026-09-02 | `self-update: Re-download grok-cli from SCRIPT_URL` |
| self-uninstall | `inst_self_uninstall` | you (Type 0) | 2026-09-02 | `self-uninstall: Same remove as uninstall (channel name)` |
| setup | `gc_setup` | you (Type 0) | 2026-09-04 | `setup: Install grok from x.ai (channel + artifact; skip if grok already runs here)` |
| print-sudoers | `gc_print_sudoers` | you (Type 0) | 2026-08-14 | `print-sudoers: Emit sudoers draft` |
| print-sudoers-install-script | `gc_print_sudoers_install_script` | you (Type 0) | 2026-08-09 | `print-sudoers-install-script: Write admin install script` |
| remove-project-sudoers | `gc_remove_project_sudoers` | you (Type 0) | 2026-08-09 | `remove-project-sudoers: Remove sudoers draft only` |
| submit-sudoer-request | `gc_submit_sudoer_request` | you (Type 0) | 2026-08-17 | `submit-sudoer-request: Queue the JSON grant inbound` |
| sync-auth | `gc_sync_auth` | you (Type 0) | missing | `sync-auth: Copy /var/grok-cli/auth.* into ~/.grok` |
| sync-auth-from-remote | `gc_sync_auth_from_remote` | you (Type 0) | 2026-09-02 | `sync-auth-from-remote: Copy a remote host's auth.* into ~/.grok` |
| uninstall | `inst_local_uninstall` | you (Type 0) | 2026-08-03 | `uninstall: Remove managed binary (confirm or --force); not sudoers` |
| version | `app_version` | you (Type 0) | missing | `version: Show local version` |
| where-is-me | `app_where_is_me` | you (Type 0) | 2026-08-03 | `where-is-me: Show running and install paths` |

A TTY main menu **MUST** print daily-work **human-readable** lines as a **numbered list**, with related grant/draft verbs behind family row **`sudoers`** (submenu; **Back 8**, **Exit 9**). Header is **`APP_NAME(APP_VERSION)`**; the next line is **logged in** / **logged out**. grok-cli is **case 3**: verb **`menu`** (alias **`main`**). Off-TTY empty argv is Type O ensure (not this list). **Exclude** `help`, `menu`/`main`, `check-session` (status is under the title), install/setup, self-managed (`install`, `uninstall`, `self-update`, `self-uninstall`, `where-is-me`), diagnostics (`version`, `about`, `version-check`), and test-purpose. **`sudoers` is not a live dispatcher token.** Main **N = 5**; submenu **K = 5**; **Exit 9**. Internal `ensure` is not a help verb.

## Not yet wired

| verb | handler | privilege | last modified date | human-readable | status |
|------|---------|-----------|--------------------|----------------|--------|
| restore | — | — | — | — | forbidden — domain law says do not wire it (retired folder-archive). **Not** a planned Gap. |

---

**Last Updated:** 2026-09-03 (main menu header `APP_NAME(APP_VERSION)`; session line; drop `check-session` row; **N = 5**)  
**Alignment:** term `cli-routed-verb-table` · **`SK-CLI-ROUTED-VERB-TABLE`** · **`SK-CLI-DEFAULT-INTERACTION`**
