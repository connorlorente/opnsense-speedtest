# os-speedtest

OPNsense plugin: **Reporting -> Speed Test**. Runs the Ookla Speedtest CLI from the firewall.

- Run a test from the GUI, with latest result, history graph and table
- Scheduled tests (every N hours), server selection, bind to a specific interface
- Ookla CLI downloaded automatically (checksum-pinned)

## Install from this repo

On the firewall, as root (SSH, then option 8 for a shell):

    fetch -o - https://github.com/connorlorente/opnsense-speedtest/archive/refs/heads/main.tar.gz | tar -xz -C /tmp
    sh /tmp/opnsense-speedtest-main/install.sh

`install.sh` copies `src/` into `/usr/local`, refreshes the menu/ACL caches, restarts configd and
downloads the Ookla CLI to `/usr/local/bin/speedtest`. Re-run it to upgrade.

Then open **Reporting -> Speed Test**, tick **Accept Ookla terms** under Settings, save, and run a test.
Nothing runs until you accept Ookla's EULA / Terms / Privacy Policy.

## Uninstall

    sh /tmp/opnsense-speedtest-main/install.sh --uninstall

(fetch the repo again first if `/tmp` was cleared). This removes the plugin files, the Ookla CLI and the
scheduled job. Kept: the history in `/var/db/speedtest` (`rm -rf` it for a full wipe) and the inert
`<OPNsense><Speedtest>` block in `/conf/config.xml`.

## Build a .pkg instead

Put this folder at `plugins/benchmarks/speedtest` in the [OPNsense plugins tree](https://github.com/opnsense/plugins)
and run `make package`. Install with `pkg add`; remove with `pkg delete os-speedtest` (or System -> Firmware -> Plugins).
The `+POST_INSTALL.post` / `+PRE_DEINSTALL.pre` hooks do the CLI download and cleanup in that case.
Do not mix the two methods: remove one before using the other.

## Layout

- `src/opnsense/scripts/OPNsense/Speedtest/speedtest.py` runs the CLI and stores results in `/var/db/speedtest/`
- `src/opnsense/scripts/OPNsense/Speedtest/install_cli.sh` downloads the Ookla CLI
- `src/opnsense/service/conf/actions.d/actions_speedtest.conf` configd actions
- `src/etc/inc/plugins.inc.d/speedtest.inc` cron schedule hook
- `src/opnsense/mvc/app/...` model, API controllers, page, menu, ACL
- `tests/` parser test: `python tests/test_speedtest.py`

## Status

Written without access to a live OPNsense box. Static checks pass (PHP lint, XML, shell syntax, parser test),
but try it on a VM or snapshot first.
