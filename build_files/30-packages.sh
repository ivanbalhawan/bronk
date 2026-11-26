#!/bin/bash
# Fedora packages: removals, installs, and a guard that the install leaves the
# base image's packages alone (IVA-23). Add each new tool to the smoke checks
# in 90-checks.sh too.

set -ouex pipefail

# Packages can be installed from any enabled yum repo on the image.
# ublue main images don't ship RPM Fusion: codecs (ffmpeg, Mesa VA-API drivers)
# come from negativo17's fedora-multimedia repo. Don't add RPM Fusion, its
# packages conflict with negativo17's (IVA-45).

# Replace the Firefox package with the Flathub version (in preinstall.d, IVA-43).
# Both use the org.mozilla.firefox app ID, so the dock pin and default browser
# in GNOME's defaults keep working. Done before the guard below on purpose.
dnf5 remove -y firefox firefox-langpacks
# htop and nvtop: Resources and btop cover them (IVA-67). Nothing depends on either.
dnf5 remove -y htop nvtop

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

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

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
