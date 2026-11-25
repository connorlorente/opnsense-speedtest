#!/bin/sh
# Sign the package feed (run on the machine that holds the repository signing key).
#
#   tools/publish.sh <feed checkout> [package ...]
#
# <feed checkout> is a checkout of this repository's `packages` branch. The given packages
# (default: everything in ./dist) replace older versions of the same package in repo/<series>
# and the catalog is signed again: pkg lists only what is in the folder at signing time, so every
# package of the feed must be present. Commit and push the feed checkout afterwards.
#
# One-time key setup (keep the private key off the repo):
#   openssl genrsa -out /root/speedtest-repository.key 4096 && chmod 600 /root/speedtest-repository.key
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FEED="${1:?usage: $0 <feed checkout> [package ...]}"
shift
SERIES="${SERIES:-$(opnsense-version -a)}"
KEY="${KEY:-/root/speedtest-repository.key}"
DIR="${FEED}/repo/${SERIES}"

if [ "$#" -eq 0 ]; then
    set -- "${ROOT}"/dist/*.pkg
fi
mkdir -p "${DIR}"
for PACKAGE in "$@"; do
    NAME="$(pkg query -F "${PACKAGE}" %n)"
    case "${NAME}" in
        *-devel) echo "Refusing development package ${PACKAGE}" >&2; exit 1 ;;
    esac
    for OLD in "${DIR}/${NAME}"-[0-9]*.pkg; do
        [ -e "${OLD}" ] && [ "$(pkg query -F "${OLD}" %n)" = "${NAME}" ] && rm -f "${OLD}"
    done
    cp "${PACKAGE}" "${DIR}/"
done
pkg repo "${DIR}" "rsa:${KEY}"
# pkg 2.x writes the catalog as *.pkg, older pkg as *.tzst; a client may ask for either name,
# so a leftover *.tzst must never keep serving an old catalog
for ARCHIVE in packagesite data; do
    cp "${DIR}/${ARCHIVE}.pkg" "${DIR}/${ARCHIVE}.tzst"
done
# client side of the feed: installer + the public half of the signing key
cp "${ROOT}/feed/install.sh" "${FEED}/install.sh"
openssl rsa -in "${KEY}" -pubout -out "${FEED}/speedtest-repository.pub" 2> /dev/null
ls -1 "${DIR}"
