#!/bin/sh
# Build the os-speedtest package on an OPNsense machine (needs git); the .pkg lands in ./dist.
#
#   tools/build.sh
#
# OPNsense plugins build with the framework of the opnsense/plugins repository (Mk/, Scripts/,
# Templates/). It is cloned into $WORK at the branch matching this firewall's release series and
# the plugin is built there unchanged.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERIES="${SERIES:-$(opnsense-version -a 2>/dev/null || echo master)}"  # plain FreeBSD (CI) has no opnsense-version
WORK="${WORK:-/tmp/opnsense-plugins-framework}"
UPSTREAM="${UPSTREAM:-https://github.com/opnsense/plugins.git}"
PLUGIN=benchmarks/speedtest

if [ ! -d "${WORK}/.git" ]; then
    BRANCH="stable/${SERIES}"
    git ls-remote --exit-code --heads "${UPSTREAM}" "${BRANCH}" > /dev/null 2>&1 || BRANCH=master
    echo "Fetching the plugin framework (${BRANCH})"
    git clone -q --depth 1 --branch "${BRANCH}" "${UPSTREAM}" "${WORK}"
else
    git -C "${WORK}" pull -q --ff-only || echo "Warning: could not update ${WORK}, using it as is" >&2
fi

rm -rf "${WORK:?}/${PLUGIN}"
mkdir -p "${WORK}/${PLUGIN}" "${ROOT}/dist"
# only what belongs in the package: not .git, dist, tests, feed or tools
tar -C "${ROOT}" -cf - Makefile pkg-descr ./+POST_INSTALL.post ./+PRE_DEINSTALL.pre src |
    tar -C "${WORK}/${PLUGIN}" -xf -
find "${WORK}/${PLUGIN}" -name __pycache__ -type d -prune -exec rm -rf {} +

echo "Building ${PLUGIN}"
(cd "${WORK}/${PLUGIN}" && make PLUGIN_DEVEL= package > /dev/null)
cp "${WORK}/${PLUGIN}"/work/pkg/*.pkg "${ROOT}/dist/"
ls -1 "${ROOT}/dist"
