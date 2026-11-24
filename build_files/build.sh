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
# ublue main images don't ship RPM Fusion: codecs (ffmpeg, Mesa VA-API drivers)
# come from negativo17's fedora-multimedia repo. Don't add RPM Fusion, its
# packages conflict with negativo17's (IVA-45).

# Replace the Firefox package with the Flathub version (in preinstall.d, IVA-43).
# Both use the org.mozilla.firefox app ID, so the dock pin and default browser
# in GNOME's defaults keep working. Done before the guard below on purpose.
dnf5 remove -y firefox firefox-langpacks

# Guard: record the base image's packages, to check below that the install
# doesn't change any of them (IVA-23)
rpm_list() { rpm -qa --qf '%{NAME}.%{ARCH} %{EVR}\n' | grep -v '^gpg-pubkey' | LC_ALL=C sort; }
rpm_list > /tmp/rpms-base.txt

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

# Guard: fail if the install upgraded, downgraded or removed any base package.
# dnf5 uses the live Fedora repos, which can be ahead of the base image (a partial
# upgrade) or replace a package ublue swapped or pinned. When this trips, decide
# on purpose: wait a day for the base to catch up, drop the package, or allow
# that one change by adding its NAME.ARCH below.
ALLOWED_BASE_CHANGES=()
rpm_list > /tmp/rpms-after.txt
changed=$(LC_ALL=C comm -23 /tmp/rpms-base.txt /tmp/rpms-after.txt)
for allowed in "${ALLOWED_BASE_CHANGES[@]}"; do
    changed=$(grep -v "^${allowed} " <<<"$changed" || true)
done
if [[ -n "$changed" ]]; then
    set +x
    echo "ERROR: the package install changed base image packages (old versions shown):" >&2
    echo "$changed" >&2
    exit 1
fi
echo "Base package check passed; $(LC_ALL=C comm -13 /tmp/rpms-base.txt /tmp/rpms-after.txt | wc -l) packages added (or allowed changes)"

### Fonts: IosevkaTerm and JetBrains Mono Nerd Fonts (IVA-66)
/ctx/fonts.sh

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
# Installs the Flatpak apps in /usr/share/flatpak/preinstall.d at boot (IVA-43)
systemctl enable bronk-flatpak-preinstall.service

### Branding: os-release name, logos, login screen, boot splash, fastfetch (IVA-65)
/ctx/branding.sh

#### Smoke checks: fail the build if an installed tool doesn't run (IVA-23)
# Keep in sync with the dnf5 install list above: "<package> <command to run>"
# The build has no terminal; TERM is set because some tools (ranger) need one even for --version.
while read -r pkg cmd; do
    if ! out=$(TERM=xterm-256color bash -c "$cmd" </dev/null 2>&1); then
        set +x
        echo "ERROR: ${pkg}: '${cmd}' failed:" >&2
        echo "$out" >&2
        exit 1
    fi
done <<'CHECKS'
bat      bat --version
btop     btop --version
eza      eza --version
fastfetch fastfetch --version
fd-find  fd --version
fzf      fzf --version
neovim   nvim --version
pipx     pipx --version
ranger   ranger --version
ripgrep  rg --version
tldr     tldr --version
uv       uv --version
zoxide   zoxide --version
CHECKS
systemctl is-enabled podman.socket
systemctl is-enabled bronk-flatpak-preinstall.service
ls /usr/share/flatpak/preinstall.d/*.preinstall
if rpm -q firefox; then echo "ERROR: firefox package still installed" >&2; exit 1; fi

#### Workaround: Fedora repos for ISO builds
# F45 ships Fedora's repo files in /usr/share/dnf5/repos.d, but bootc-image-builder
# (anaconda-iso) only reads /etc/yum.repos.d, so ISO builds can't find any packages.
# Copies in /etc override the vendor files of the same name, so dnf sees no duplicates.
# Keep this last so a dnf upgrade above can't leave the copies stale.
# Remove once bootc-image-builder reads /usr/share/dnf5/repos.d.
cp -v /usr/share/dnf5/repos.d/fedora*.repo /etc/yum.repos.d/
