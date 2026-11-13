#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y \
    bat \
    btop \
    eza \
    fastfetch \
    fd-find \
    fzf \
    neovim \
    pipx \
    ranger \
    ripgrep \
    uv \
    zoxide



# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

#### Workaround: Fedora repos for ISO builds
# F45 ships Fedora's repo files in /usr/share/dnf5/repos.d, but bootc-image-builder
# (anaconda-iso) only reads /etc/yum.repos.d, so ISO builds can't find any packages.
# Copies in /etc override the vendor files of the same name, so dnf sees no duplicates.
# Keep this last so a dnf upgrade above can't leave the copies stale.
# Remove once bootc-image-builder reads /usr/share/dnf5/repos.d.
cp -v /usr/share/dnf5/repos.d/fedora*.repo /etc/yum.repos.d/
