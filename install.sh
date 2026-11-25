#!/bin/sh
# Install os-speedtest on an OPNsense firewall straight from a checkout of this repo (no pkg build).
# Run as root:  sh install.sh              install / upgrade
#               sh install.sh --uninstall
set -e
cd "$(dirname "$0")"

reload() {
    /usr/local/etc/rc.configure_plugins   # menu + ACL caches
    service configd restart               # pick up actions.d
}

if [ "$1" = "--uninstall" ]; then
    rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/Speedtest \
           /usr/local/opnsense/mvc/app/models/OPNsense/Speedtest \
           /usr/local/opnsense/mvc/app/views/OPNsense/Speedtest \
           /usr/local/opnsense/scripts/OPNsense/Speedtest
    rm -f /usr/local/opnsense/www/js/speedtest_gauges.js \
          /usr/local/opnsense/www/js/widgets/Speedtest.js \
          /usr/local/opnsense/www/js/widgets/Metadata/Speedtest.xml
    rm -f /usr/local/opnsense/service/conf/actions.d/actions_speedtest.conf \
          /usr/local/etc/inc/plugins.inc.d/speedtest.inc \
          /usr/local/bin/speedtest
    reload
    /usr/local/sbin/pluginctl -s cron restart || true   # drops the scheduled job
    echo "Removed. History in /var/db/speedtest was kept (rm -rf it for a full wipe)."
    exit 0
fi

tar -C src -cf - . | tar -C /usr/local -xpf -    # src/ mirrors /usr/local
reload
[ -x /usr/local/bin/speedtest ] || /bin/sh /usr/local/opnsense/scripts/OPNsense/Speedtest/install_cli.sh ||
    echo "WARNING: Ookla CLI download failed; use the Install button in Reporting -> Speed Test"
echo "Done. Open Reporting -> Speed Test."
