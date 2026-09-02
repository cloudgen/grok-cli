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
| `test_cli.sh` | CLI surface, empty argv (TTY menu / off-TTY Type O), help lists online verbs | **TP-CLI-*** |
| `test_local_lifecycle.sh` | install / uninstall / where-is-me | **TP-LC-*** |
| `test_domain_grok_cli.sh` | session gate + backup/sync-auth + sync-auth-from-remote + add-crontab + sudoers print + JSON grant + submit inbound | **TP-GROK-CLI-*** |
| `test_grok_setup.sh` | `setup` fetches xAI channel + artifact (fake curl; no public net; no `install.sh`) | **TP-VCLI-*** |
| `test_online_install.sh` | Channel `curl|sh` ensure, checksum mismatch, version-check, self-uninstall (fake curl) | **TP-ONL-*** |

## Isolation

- Temp `HOME` + `USER_BIN` for install tests  
- **No** public network  
- **No** write to `/etc/sudoers.d` (suite never installs sudoers)  
- Auth fixtures are synthetic (no live tokens)  
- Backup **success** uses writable `GROK_CLI_ROOT` override (not `/var/grok-cli`)

## Ship unit under test

`src/grok-cli`

## Maps

Product TP map: `reviews/test-plan.md`  
RTM: `reviews/requirement-test-matrix.md`
