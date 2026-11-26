#!/bin/bash
# App grid cleanup (IVA-67). Runs after 30-packages.sh.
# Folders come from system_files/etc/dconf/db/local.d/10-bronk-app-folders.

set -ouex pipefail

# Hide from the app grid; the apps stay installed and runnable.
#   btop, nvim, ranger: terminal apps, run from Ptyxis
#   Yelp (Help), Tour, Malcontent (Parental Controls), System Monitor (Resources replaces it)
HIDDEN=(
    btop
    nvim
    ranger
    org.gnome.Yelp
    org.gnome.Tour
    org.freedesktop.MalcontentControl
    org.gnome.SystemMonitor
)
for app in "${HIDDEN[@]}"; do
    f="/usr/share/applications/${app}.desktop"
    [[ -f "$f" ]] || { echo "ERROR: $f not found; update HIDDEN" >&2; exit 1; }
    sed -i -e '/^NoDisplay=/d' -e '/^\[Desktop Entry\]$/a NoDisplay=true' "$f"
done
update-desktop-database /usr/share/applications

# Compile the dconf defaults (app folders) into /etc/dconf/db/local
dconf update

### Checks
set +x
for app in "${HIDDEN[@]}"; do
    grep -qx "NoDisplay=true" "/usr/share/applications/${app}.desktop" \
        || { echo "ERROR: ${app} isn't hidden" >&2; exit 1; }
done
for pkg in htop nvtop; do
    if rpm -q "$pkg" >/dev/null; then echo "ERROR: $pkg still installed" >&2; exit 1; fi
done
folders=$(DCONF_PROFILE=/dev/stdin dconf read /org/gnome/desktop/app-folders/folder-children <<<"system-db:local")
[[ "$folders" == "['Utilities', 'System', 'Tweaks']" ]] \
    || { echo "ERROR: app folders not in the dconf db (got: ${folders})" >&2; exit 1; }
echo "Launcher checks passed"
