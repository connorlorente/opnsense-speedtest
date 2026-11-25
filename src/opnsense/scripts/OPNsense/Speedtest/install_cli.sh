#!/bin/sh
# Downloads Ookla's official FreeBSD CLI (not redistributable, so not bundled).
# The FreeBSD 13 build only links base libs with stable sonames, so it runs on FreeBSD 14 too.
set -e
VER=1.2.0
FBSD=13
SHA256=23b20119066df5b08c4f3a8920334ccaab0783780f9b2494629394d1ef33e6f8  # update together with VER

[ "$(uname -m)" = "amd64" ] || { echo "unsupported architecture $(uname -m)" >&2; exit 1; }

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fetch -q -T 30 -o "$T/cli.pkg" "https://install.speedtest.net/app/cli/ookla-speedtest-$VER-freebsd$FBSD-x86_64.pkg"
[ "$(sha256 -q "$T/cli.pkg")" = "$SHA256" ] || { echo "checksum mismatch, refusing to install" >&2; exit 1; }
tar -xf "$T/cli.pkg" -C "$T"
B=$(find "$T" -type f -name speedtest | head -n 1)
[ -n "$B" ] || { echo "speedtest binary not found in package" >&2; exit 1; }
install -m 0755 "$B" /usr/local/bin/speedtest
/usr/local/bin/speedtest --version | head -n 1
