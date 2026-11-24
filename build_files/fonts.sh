#!/bin/bash
# Terminal fonts from the Nerd Fonts release (IVA-66). Called by build.sh.
#
# Only the "Nerd Font Mono" family in Regular, Bold, Italic and Bold Italic:
# that's what the terminals use, and the full IosevkaTerm set is 1.1 GB.
# Fonts are installed, not made the default; GNOME keeps Adwaita Mono.

set -ouex pipefail

# Renovate bumps this (customManagers in .github/renovate.json5).
# renovate: datasource=github-releases depName=ryanoasis/nerd-fonts
NERD_FONTS_VERSION="v3.5.1"

STYLES=(Regular Bold Italic BoldItalic)
release="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"
work=$(mktemp -d)

# Checksums come from the same release. This catches a corrupt or swapped
# download, and keeps Renovate's version bumps working without a hash edit.
curl -fsSL --retry 3 -o "$work/SHA-256.txt" "${release}/SHA-256.txt"

# install_nerd_font <archive> <font file prefix> <license file> <install dir>
install_nerd_font() {
    local archive=$1 prefix=$2 license=$3 dir=$4
    curl -fsSL --retry 3 -o "$work/$archive" "${release}/${archive}"
    (cd "$work" && grep -E "^[0-9a-f]{64}  ${archive}\$" SHA-256.txt | sha256sum -c -)

    local files=("$license")
    for style in "${STYLES[@]}"; do files+=("${prefix}-${style}.ttf"); done
    install -d -m755 "$dir"
    tar -xJf "$work/$archive" -C "$dir" --no-same-owner "${files[@]}"
    chmod 644 "$dir"/*
}

install_nerd_font IosevkaTerm.tar.xz   IosevkaTermNerdFontMono   LICENSE.md /usr/share/fonts/iosevka-term-nerd-font-mono
install_nerd_font JetBrainsMono.tar.xz JetBrainsMonoNerdFontMono OFL.txt    /usr/share/fonts/jetbrains-mono-nerd-font-mono
rm -rf "$work"

# Fedora keeps the system font cache in /usr/lib/fontconfig/cache, so it ships in the image.
fc-cache -f

# Check: fontconfig sees all 4 styles of both families.
for family in "IosevkaTerm Nerd Font Mono" "JetBrainsMono Nerd Font Mono"; do
    count=$(fc-list ":family=${family}" style | wc -l)
    if [[ "$count" -ne ${#STYLES[@]} ]]; then
        set +x
        echo "ERROR: fontconfig finds ${count} styles of '${family}', expected ${#STYLES[@]}" >&2
        fc-list ":family=${family}" >&2
        exit 1
    fi
done
