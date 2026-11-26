#!/bin/bash
# Systemd units to enable. 90-checks.sh checks each one is enabled.

set -ouex pipefail

systemctl enable podman.socket
# Installs the Flatpak apps in /usr/share/flatpak/preinstall.d at boot (IVA-43)
systemctl enable bronk-flatpak-preinstall.service
# Tailscale daemon (IVA-46). Each machine logs in by hand after install with
# `sudo tailscale up`; never bake an auth key into the image. Node state lives
# in /var/lib/tailscale, so it survives image updates.
systemctl enable tailscaled.service
