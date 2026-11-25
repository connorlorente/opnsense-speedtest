#!/bin/sh
# Add the signed os-speedtest package feed (published on the `packages` branch).
set -eu

BASE_URL='https://raw.githubusercontent.com/connorlorente/opnsense-speedtest/packages'
KEY_DIR='/usr/local/etc/pkg/keys'
KEY_PATH="${KEY_DIR}/speedtest-repository.pub"
REPO_PATH='/usr/local/etc/pkg/repos/speedtest.conf'

if [ "$(id -u)" -ne 0 ]; then
    echo 'Run this installer as root.' >&2
    exit 1
fi
SERIES="$(opnsense-version -a)"

TEMP_DIR="$(mktemp -d /tmp/speedtest-repository.XXXXXX)"
trap 'rm -rf "${TEMP_DIR}"' EXIT HUP INT TERM

fetch -qo "${TEMP_DIR}/speedtest-repository.pub" "${BASE_URL}/speedtest-repository.pub"

install -d -m 0755 "${KEY_DIR}" /usr/local/etc/pkg/repos
install -m 0644 "${TEMP_DIR}/speedtest-repository.pub" "${KEY_PATH}"
cat > "${REPO_PATH}" <<CONF
Speedtest: {
  url: "${BASE_URL}/repo/${SERIES}",
  mirror_type: "none",
  signature_type: "pubkey",
  pubkey: "${KEY_PATH}",
  priority: 1,
  enabled: yes
}
CONF
chmod 0644 "${REPO_PATH}"

pkg update -f

echo 'Speedtest repository added. Open System -> Firmware -> Plugins to install os-speedtest.'
