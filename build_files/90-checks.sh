#!/bin/bash
# Smoke checks: fail the build if an installed tool doesn't run, or a file or
# service the earlier scripts set up is missing (IVA-23).

set -ouex pipefail

# Keep in sync with the dnf5 install list in 30-packages.sh, plus kanata (45-kanata.sh): "<package> <command to run>"
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
tailscale tailscale version
tldr     tldr --version
uv       uv --version
zoxide   zoxide --version
kanata   kanata --version
CHECKS
systemd-sysusers --dry-run /usr/lib/sysusers.d/bronk-groups.conf
systemctl is-enabled podman.socket
systemctl is-enabled bronk-flatpak-preinstall.service
systemctl is-enabled tailscaled.service
ls /usr/share/flatpak/preinstall.d/*.preinstall
if rpm -q firefox; then echo "ERROR: firefox package still installed" >&2; exit 1; fi
