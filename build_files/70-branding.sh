#!/bin/bash
# bronk name and logo wherever the OS shows them (IVA-65). Runs
# after system_files/ is copied in. Source artwork lives in branding/.

set -ouex pipefail

### os-release: the name GNOME, fastfetch, the boot menu and first-boot setup show
# Only display fields change. ID=fedora, VERSION_ID, VARIANT_ID and CPE_NAME stay:
# dnf, toolbox, distrobox and Flatpak use them to recognise Fedora.
# Edit the base's file in place, so its version fields stay current.
sed -i \
    -e 's/^NAME=.*/NAME="bronk"/' \
    -e 's/^PRETTY_NAME="Fedora Linux /PRETTY_NAME="bronk /' \
    -e 's/^LOGO=.*/LOGO=bronk/' \
    -e 's/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME="bronk"/' \
    -e 's/^ANSI_COLOR=.*/ANSI_COLOR="0;38;2;255;106;0"/' \
    -e 's|^HOME_URL=.*|HOME_URL="https://github.com/ivanbalhawan/bronk"|' \
    -e 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/ivanbalhawan/bronk/issues"|' \
    /usr/lib/os-release

### Icons (the LOGO= name above) and the login-screen logo override
gtk-update-icon-cache -f /usr/share/icons/hicolor
glib-compile-schemas --strict /usr/share/glib-2.0/schemas

### Boot splash: keep Fedora's "bgrt" theme (laptop maker's logo + spinner) and
# swap only its watermark, the Fedora wordmark at the bottom of the screen.
# The file belongs to fedora-logos; every build re-applies this on top of the base.
install -m644 /usr/share/bronk/plymouth-watermark.png /usr/share/plymouth/themes/spinner/watermark.png

# Plymouth runs from the initramfs, so rebuild it to pick up the new watermark.
# dracut reads the base's config (/usr/lib/dracut/dracut.conf.d: no hostonly,
# ostree and bootc modules), so it builds the same initramfs as the base.
kver=$(ls /usr/lib/modules)
[[ $(wc -w <<<"$kver") -eq 1 ]] || { echo "ERROR: expected one kernel, found: $kver" >&2; exit 1; }
dracut --force --kver "$kver" "/usr/lib/modules/${kver}/initramfs.img"
chmod 0600 "/usr/lib/modules/${kver}/initramfs.img"

### Checks
set +x
fail() { echo "ERROR: branding: $*" >&2; exit 1; }
. /usr/lib/os-release
[[ "$NAME" == "bronk" ]]                || fail "os-release NAME is '$NAME'"
[[ "$PRETTY_NAME" == bronk\ * ]]        || fail "os-release PRETTY_NAME is '$PRETTY_NAME'"
[[ "$ID" == "fedora" ]]                 || fail "os-release ID changed to '$ID'"
[[ -n "$VERSION_ID" ]]                  || fail "os-release VERSION_ID is missing"
[[ "$LOGO" == "bronk" ]]                || fail "os-release LOGO is '$LOGO'"
[[ -f /usr/share/icons/hicolor/scalable/apps/bronk.svg ]] || fail "bronk icon missing"
logo=$(GSETTINGS_BACKEND=memory gsettings get org.gnome.login-screen logo)
[[ "$logo" == "'/usr/share/pixmaps/bronk-gdm-logo.png'" ]] || fail "login-screen logo is $logo"
for key in "background picture-uri" "background picture-uri-dark" "screensaver picture-uri"; do
    uri=$(GSETTINGS_BACKEND=memory gsettings get org.gnome.desktop.${key})
    file=${uri#\'file://}; file=${file%\'}
    [[ "$file" == /usr/share/backgrounds/bronk/* && -f "$file" ]] || fail "org.gnome.desktop.${key} is ${uri}"
done
xmllint --noout /usr/share/gnome-background-properties/bronk.xml || fail "bronk.xml doesn't parse"
for f in $(grep -o '/usr/share/backgrounds/bronk/[^<]*' /usr/share/gnome-background-properties/bronk.xml); do
    [[ -f "$f" ]] || fail "bronk.xml lists missing wallpaper $f"
done
cmp -s /usr/share/bronk/plymouth-watermark.png <(lsinitrd -f usr/share/plymouth/themes/spinner/watermark.png "/usr/lib/modules/${kver}/initramfs.img") \
    || fail "initramfs doesn't have the bronk Plymouth watermark"
fastfetch --config /etc/xdg/fastfetch/config.jsonc --pipe true --structure OS | grep -q bronk \
    || fail "fastfetch doesn't show bronk"
echo "Branding checks passed"
