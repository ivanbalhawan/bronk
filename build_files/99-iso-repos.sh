#!/bin/bash
# Workaround: Fedora repos for ISO builds.
# F45 ships Fedora's repo files in /usr/share/dnf5/repos.d, but bootc-image-builder
# (anaconda-iso) only reads /etc/yum.repos.d, so ISO builds can't find any packages.
# Copies in /etc override the vendor files of the same name, so dnf sees no duplicates.
# Keep this script last so a dnf upgrade before it can't leave the copies stale.
# Remove once bootc-image-builder reads /usr/share/dnf5/repos.d.

set -ouex pipefail

cp -v /usr/share/dnf5/repos.d/fedora*.repo /etc/yum.repos.d/
