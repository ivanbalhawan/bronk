#!/bin/bash
# Checks for the default keyboard shortcuts and accent color (IVA-72).
# Runs after 70-branding.sh, which compiles the gschema overrides.
# The settings themselves are in system_files/: zz1-bronk.gschema.override
# and /etc/dconf/db/local.d/20-bronk-keybindings.

set -ou pipefail

fail() { echo "ERROR: desktop: $*" >&2; exit 1; }
gs() { GSETTINGS_BACKEND=memory gsettings get "$1" "$2"; }
db() { DCONF_PROFILE=/dev/stdin dconf read "$1" <<<"system-db:local"; }

while read -r schema key want; do
    got=$(gs "$schema" "$key")
    [[ "$got" == "$want" ]] || fail "${schema} ${key} is ${got}, want ${want}"
done <<'EXPECT'
org.gnome.desktop.interface accent-color 'orange'
org.gnome.desktop.wm.keybindings close ['<Super>q']
org.gnome.desktop.wm.keybindings cycle-windows ['<Alt>Tab']
org.gnome.desktop.wm.keybindings cycle-windows-backward ['<Shift><Alt>Tab']
org.gnome.desktop.wm.keybindings switch-applications @as []
org.gnome.desktop.wm.keybindings switch-applications-backward @as []
org.gnome.desktop.wm.keybindings toggle-fullscreen ['<Super>f']
org.gnome.desktop.wm.keybindings toggle-maximized ['<Shift><Super>f']
org.gnome.settings-daemon.plugins.media-keys screensaver ['<Shift><Super>l']
org.gnome.settings-daemon.plugins.media-keys www ['<Super>b']
EXPECT

base=/org/gnome/settings-daemon/plugins/media-keys
[[ "$(db ${base}/custom-keybindings)" == "['${base}/custom-keybindings/custom0/', '${base}/custom-keybindings/custom1/']" ]] \
    || fail "custom-keybindings list not in the dconf db"
[[ "$(db ${base}/custom-keybindings/custom0/binding)" == "'<Super>t'" ]] || fail "terminal shortcut missing"
[[ "$(db ${base}/custom-keybindings/custom1/binding)" == "'<Shift><Control>Escape'" ]] || fail "Resources shortcut missing"
# The commands the custom shortcuts run must exist
command -v ptyxis >/dev/null || fail "ptyxis not installed (Super+T)"
[[ -f /usr/share/flatpak/preinstall.d/net.nokyan.Resources.preinstall ]] || fail "Resources isn't preinstalled (Ctrl+Shift+Esc)"
echo "Desktop checks passed"
