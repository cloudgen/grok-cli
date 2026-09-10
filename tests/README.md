# Tests — grok-cli

## Run

```sh
./tests/run.sh
# or
sh tests/run.sh
```

Exit **0** when all assertions pass; **1** on failure; **2** if ship unit missing.

## Layout

| File | Focus | TP families |
|------|--------|-------------|
| `run.sh` | Entrypoint | — |
| `helpers.sh` | Asserts + isolated HOME | — |
| `test_cli.sh` | CLI surface, empty argv (TTY menu / off-TTY Type O; overlay `--debug` / `--quiet` follow 0-argv), this-login-only menu hide, logged-in hide of sync-auth / sync-auth-from-remote, Termux menu does not freeze on hanging grok, reprint does not re-probe, probe always bounded, `--debug` menu elapsed of each paint step | **TP-CLI-*** |
| `test_local_lifecycle.sh` | install / uninstall / where-is-me | **TP-LC-*** |
| `test_domain_grok_cli.sh` | live `grok -p hello` session gate (incl. elevated `SUDO_USER` home; SIGTERM-ignoring hang bound; `proot` on PATH → reaper else simple `-p`) + backup/sync-auth + sync-auth-from-remote (incl. TTY menu row 3 SPEC prompt + preferred-remote default) + add-crontab + sudoers print + JSON grant + submit inbound | **TP-GROK-CLI-*** |
| `test_grok_setup.sh` | `setup` / `update-grok` fetch xAI channel + artifact (fake curl; no public net; no `install.sh`); Android wrapper `--kill-on-exit` / `proot-exit-reaper` / `-p` SIGKILL; heal stale wrapper on skip | **TP-VCLI-*** |
| `test_online_install.sh` | Channel `curl|sh` ensure, checksum mismatch, version-check, version-aware self-update start line, self-uninstall (fake curl) | **TP-ONL-*** |

## Isolation

- Temp `HOME` + `USER_BIN` for install tests  
- **No** public network  
- **No** write to `/etc/sudoers.d` (suite never installs sudoers)  
- Auth fixtures are synthetic (no live tokens); session tests inject a fake `GROK_BIN` (never `grok -p hello` against xAI)  
- Backup **success** uses writable `GROK_CLI_ROOT` override (not `/var/grok-cli`)

## Ship unit under test

`src/grok-cli`

## Maps

Product TP map: `reviews/test-plan.md`  
RTM: `reviews/requirement-test-matrix.md`
