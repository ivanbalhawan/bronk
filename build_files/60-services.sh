#!/bin/bash
# Systemd units to enable. 90-checks.sh checks each one is enabled.

set -ouex pipefail

systemctl enable podman.socket
# Installs the Flatpak apps in /usr/share/flatpak/preinstall.d at boot (IVA-43)
systemctl enable bronk-flatpak-preinstall.service
