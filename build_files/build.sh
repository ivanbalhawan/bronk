#!/bin/bash
# Runs the numbered build scripts next to it, in order (IVA-49):
#   10-files     system_files/ onto /
#   20-signing   image signature trust (docs/signing.md)
#   30-packages  dnf5 removals and installs, base-package guard
#   40-fonts     Nerd Fonts (IVA-66)
#   45-kanata    kanata binary (IVA-71)
#   50-launcher  app grid: hide extras, default folders (IVA-67)
#   60-services  systemd units to enable
#   70-branding  os-release, logos, login screen, boot splash (IVA-65)
#   80-desktop   checks for the default shortcuts and accent color (IVA-72)
#   90-checks    smoke checks
#   99-iso-repos Fedora repos for ISO builds; keep it last
# To add a step, add an executable NN-name.sh; the number sets its place.

set -ouex pipefail

scripts=("$(dirname "$0")"/[0-9][0-9]-*.sh)
[[ -e "${scripts[0]}" ]] || { echo "ERROR: no numbered build scripts found" >&2; exit 1; }
for script in "${scripts[@]}"; do
    "$script"
done
