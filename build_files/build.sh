#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Trust config: only accept bronk images signed with our cosign key
# The matching registries.d/bronk.yaml comes from system_files/.
install -Dm644 /ctx/cosign.pub /etc/pki/containers/bronk.pub
# Add our entry to ublue's policy.json instead of replacing the file, so their rules stay.
jq '.transports.docker["ghcr.io/ivanbalhawan/bronk"] = [{
      "type": "sigstoreSigned",
      "keyPath": "/etc/pki/containers/bronk.pub",
      "signedIdentity": {"type": "matchRepository"}
    }]' /etc/containers/policy.json > /tmp/policy.json
mv /tmp/policy.json /etc/containers/policy.json
chmod 644 /etc/containers/policy.json
# Fail the build if the entry is missing.
jq -e '.transports.docker["ghcr.io/ivanbalhawan/bronk"][0].keyPath == "/etc/pki/containers/bronk.pub"' /etc/containers/policy.json

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
    tldr \
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
