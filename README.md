# os-speedtest

OPNsense plugin: **Reporting -> Speed Test**. Runs the Ookla Speedtest CLI from the firewall.

- Run a test from the GUI, with latest result, history graph and table
- Scheduled tests (every N hours), server selection, bind to a specific interface
- Ookla CLI downloaded automatically (checksum-pinned)

## Install

### Option 1: package feed (recommended; available after the first tagged release)

    fetch -qo - https://raw.githubusercontent.com/connorlorente/opnsense-speedtest/packages/install.sh | sh

This adds a signed pkg repository (`/usr/local/etc/pkg/repos/speedtest.conf`) and its public key. Then install
**os-speedtest** from System -> Firmware -> Plugins, or `pkg install os-speedtest`. Updates arrive with normal firmware updates.

Remove it: uninstall the plugin, then delete `/usr/local/etc/pkg/repos/speedtest.conf` and
`/usr/local/etc/pkg/keys/speedtest-repository.pub`.

### Option 2: straight from this repo (no package)

On the firewall, as root (SSH, then option 8 for a shell):

    fetch -o - https://github.com/connorlorente/opnsense-speedtest/archive/refs/heads/main.tar.gz | tar -xz -C /tmp
    sh /tmp/opnsense-speedtest-main/install.sh

`install.sh` copies `src/` into `/usr/local`, refreshes the menu/ACL caches, restarts configd and
downloads the Ookla CLI to `/usr/local/bin/speedtest`. Re-run it to upgrade.
Uninstall: `sh /tmp/opnsense-speedtest-main/install.sh --uninstall` (fetch the repo again if `/tmp` was cleared).
This removes the plugin files, the Ookla CLI and the scheduled job.

### Option 3: build the package yourself

On an OPNsense machine of the target release (needs `git`; `pkg install git`):

    git clone https://github.com/connorlorente/opnsense-speedtest.git
    cd opnsense-speedtest
    tools/build.sh                 # package in ./dist
    pkg add -f dist/os-speedtest-*.pkg

`tools/build.sh` clones the opnsense/plugins build framework for this release into `/tmp` and builds the plugin there.

### After installing

Open **Reporting -> Speed Test**, tick **Accept Ookla terms** under Settings, save, and run a test.
Nothing runs until you accept Ookla's EULA / Terms / Privacy Policy.

Uninstalling by any method keeps your history in `/var/db/speedtest` (`rm -rf` it for a full wipe) and the inert
`<OPNsense><Speedtest>` block in `/conf/config.xml`. Package removal (`pkg delete os-speedtest` or the GUI) removes the
CLI and the cron job through the `+PRE_DEINSTALL.pre` hook. Do not mix methods: remove one before using another.

## Upgrading

- **Package feed:** System -> Firmware -> Check for updates, or `pkg upgrade os-speedtest`. Settings and history are kept;
  an existing Ookla CLI is kept too.
- **Repo install:** fetch the new tarball and re-run `install.sh`. Settings and history are kept. It does not remove files a
  newer version dropped, and it only downloads the CLI if missing (delete `/usr/local/bin/speedtest` to force a refresh).
- **Self-built package:** rebuild and `pkg add -f dist/os-speedtest-*.pkg`.

## Publishing a release (maintainer)

Packages are built and signed by GitHub Actions (`.github/workflows/release.yml`), so no key lives on your machine.

One-time setup:
1. Generate a signing key and store it as the repo secret **FEED_SIGNING_KEY** (Settings -> Secrets and variables -> Actions),
   then delete the local file: `openssl genrsa -out k.pem 4096` and paste the contents of `k.pem`.
2. Optional: set the repo variable **OPNSENSE_SERIES** (e.g. `25.7`) to build against that opnsense/plugins branch; default is `master`.

Each release: `git tag v0.2 && git push origin v0.2`. The tag sets the package version, a FreeBSD VM builds the package,
the feed is signed with the secret and pushed to the `packages` branch. Check the Actions log on the first run.

## Layout

- `src/opnsense/scripts/OPNsense/Speedtest/speedtest.py` runs the CLI and stores results in `/var/db/speedtest/`
- `src/opnsense/scripts/OPNsense/Speedtest/install_cli.sh` downloads the Ookla CLI
- `src/opnsense/service/conf/actions.d/actions_speedtest.conf` configd actions
- `src/etc/inc/plugins.inc.d/speedtest.inc` cron schedule hook
- `src/opnsense/mvc/app/...` model, API controllers, page, menu, ACL
- `.github/workflows/release.yml`, `tools/build.sh`, `tools/publish.sh`, `feed/install.sh` package build, feed signing and the feed installer
- `tests/` parser test: `python tests/test_speedtest.py`

## Status

Written without access to a live OPNsense box. Static checks pass (PHP lint, XML, shell syntax, parser test),
but try it on a VM or snapshot first.
