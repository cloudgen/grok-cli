# Live command list — grok-cli

This file is the kept list of commands `app_main` actually runs: name, function, who may run it, date on that function’s comment, and the same one-line explanation `help` prints. It is **not** help text as the routing inventory.

**Ship unit:** `src/grok-cli`  
**Dispatcher:** `app_main`  
**Scan date:** 2026-08-25  
**Mode:** incremental (new dispatcher token `setup`)  
**Copied:** 16 live + 1 not-yet-wired · **Re-checked:** `setup` (`gc_setup`)  
**Inventory:** dispatcher `case "${COMMAND}"` — not `app_help` for routing; help one-liners copied into **human-readable**

## Live commands

| verb | handler | privilege | last modified date | human-readable |
|------|---------|-----------|--------------------|----------------|
| about | `app_about` | you (Type 0) | 2026-08-03 | `about: Show diagnostics (incl. sudoers trust tier)` |
| backup | `gc_backup` | change-the-computer (Type 1) | missing | `backup: Push ~/.grok/auth.* to /var/grok-cli` |
| check-session | `gc_check_session` | you (Type 0) | missing | `check-session: Confirm grok is logged in` |
| generate-sudoer-request | `gc_generate_sudoer_request` | you (Type 0) | 2026-08-17 | `generate-sudoer-request: Write a JSON grant you can read` |
| help | `app_help` | you (Type 0) | missing | `help: Show this help` |
| main | `app_default` | you (Type 0) | 2026-08-23 | `main: Same as menu` |
| menu | `app_default` | you (Type 0) | 2026-08-23 | `menu: Show the numbered list of live commands` |
| install | `inst_local_install` | you (Type 0) | 2026-08-09 | `install: Install grok-cli (root→global, user→~/.local/bin)` |
| setup | `gc_setup` | you (Type 0) | 2026-08-25 | `setup: Install grok from x.ai (curl vendor installer; skip if present)` |
| print-sudoers | `gc_print_sudoers` | you (Type 0) | 2026-08-14 | `print-sudoers: Emit sudoers draft` |
| print-sudoers-install-script | `gc_print_sudoers_install_script` | you (Type 0) | 2026-08-09 | `print-sudoers-install-script: Write admin install script` |
| remove-project-sudoers | `gc_remove_project_sudoers` | you (Type 0) | 2026-08-09 | `remove-project-sudoers: Remove sudoers draft only` |
| submit-sudoer-request | `gc_submit_sudoer_request` | you (Type 0) | 2026-08-17 | `submit-sudoer-request: Queue the JSON grant inbound` |
| sync-auth | `gc_sync_auth` | you (Type 0) | missing | `sync-auth: Copy /var/grok-cli/auth.* into ~/.grok` |
| uninstall | `inst_local_uninstall` | you (Type 0) | 2026-08-03 | `uninstall: Remove managed binary (confirm or --force); not sudoers` |
| version | `app_version` | you (Type 0) | missing | `version: Show local version` |
| where-is-me | `app_where_is_me` | you (Type 0) | 2026-08-03 | `where-is-me: Show running and install paths` |

A TTY main menu **MUST** print daily-work **human-readable** lines as a **numbered list**, with related grant/draft verbs behind family row **`sudoers`** (submenu; **Back 8**, **Exit 9**). grok-cli is **case 3**: verb **`menu`** (alias **`main`**). **Exclude** `help`, `menu`/`main`, install/setup, self-managed (`install`, `uninstall`, `where-is-me`), diagnostics (`version`, `about`), and test-purpose. **`sudoers` is not a live dispatcher token.** Main **N = 4**; submenu **K = 5**; **Exit 9**.

## Not yet wired

| verb | handler | privilege | last modified date | human-readable | status |
|------|---------|-----------|--------------------|----------------|--------|
| restore | — | — | — | — | forbidden — domain law says do not wire it (retired folder-archive). **Not** a planned Gap. |

---

**Last Updated:** 2026-08-25 (`setup` live)  
**Alignment:** term `cli-routed-verb-table` · **`SK-CLI-ROUTED-VERB-TABLE`** · **`SK-CLI-DEFAULT-INTERACTION`**
