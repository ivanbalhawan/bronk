#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Trust config: only accept brokkr images signed with our cosign key
# The matching registries.d/brokkr.yaml comes from system_files/.
install -Dm644 /ctx/cosign.pub /etc/pki/containers/brokkr.pub
# Add our entry to ublue's policy.json instead of replacing the file, so their rules stay.
jq '.transports.docker["ghcr.io/ivanbalhawan/brokkr"] = [{
      "type": "sigstoreSigned",
      "keyPath": "/etc/pki/containers/brokkr.pub",
      "signedIdentity": {"type": "matchRepository"}
    }]' /etc/containers/policy.json > /tmp/policy.json
mv /tmp/policy.json /etc/containers/policy.json
chmod 644 /etc/containers/policy.json
# Fail the build if the entry is missing.
jq -e '.transports.docker["ghcr.io/ivanbalhawan/brokkr"][0].keyPath == "/etc/pki/containers/brokkr.pub"' /etc/containers/policy.json

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
