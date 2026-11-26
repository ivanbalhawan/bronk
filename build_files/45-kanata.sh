#!/bin/bash
# kanata keyboard remapper binary (IVA-71).
# Only the binary: the config, user service and udev rule come from the dotfiles.
# The uinput group it needs is in system_files/usr/lib/sysusers.d/bronk-groups.conf.

set -ouex pipefail

# Renovate bumps this (customManagers in .github/renovate.json5).
# renovate: datasource=github-releases depName=jtroo/kanata
KANATA_VERSION="v1.12.0"

release="https://github.com/jtroo/kanata/releases/download/${KANATA_VERSION}"
work=$(mktemp -d)

# Checksums come from the same release, as for the Nerd Fonts (40-fonts.sh).
curl -fsSL --retry 3 -o "$work/sha256sums" "${release}/sha256sums"
curl -fsSL --retry 3 -o "$work/linux-binaries-x64.zip" "${release}/linux-binaries-x64.zip"
(cd "$work" && grep -E '^[0-9a-f]{64}  linux-binaries-x64\.zip$' sha256sums | sha256sum -c -)

# The plain build, not kanata_linux_cmd_allowed_x64: the keymap doesn't use cmd actions,
# and the plain build can't run shell commands from a config.
unzip -q -d "$work" "$work/linux-binaries-x64.zip" kanata_linux_x64
install -m755 "$work/kanata_linux_x64" /usr/bin/kanata
rm -rf "$work"

kanata --version
