# bronk_ brand kit

> **How the image uses this kit** (IVA-65, `build_files/branding.sh`):
>
> - `svg/bronk-icon.svg` and `png/bronk-icon/*` are installed as the `bronk` icon in `system_files/usr/share/icons/hicolor/`. `LOGO=bronk` in os-release points at it.
> - `system_files/usr/share/pixmaps/bronk-gdm-logo.png` (login screen) and `system_files/usr/share/bronk/plymouth-watermark.png` (boot splash) are `png/bronk-lockup-1024w.png` scaled to 96 px and 43 px high.
> - The boot splash is **not** the `plymouth/bronk` script theme below. The image keeps Fedora's `bgrt` theme (the laptop maker's logo and a spinner) and only replaces its Fedora watermark with the bronk lockup. The script theme is kept here untested, for later.
> - The fastfetch logo is ASCII art in `system_files/usr/share/bronk/fastfetch-logo.txt`, drawn from the mark.

The mark is a blocky **b** plus an orange cursor block, drawn on a 64-unit grid. The wordmark is JetBrains Mono ExtraBold, converted to outlines (no font needed to open these files). The cursor stays orange; everything else is ink `#f5f5f0` on dark or `#0d0d0d` on light.

| Token | Hex |
| --- | --- |
| bg | `#0d0d0d` |
| surface | `#161616` |
| ink | `#f5f5f0` |
| accent | `#ff6a00` |

## svg/

| File | Use |
| --- | --- |
| `bronk-mark.svg` | Mark on dark backgrounds (transparent) |
| `bronk-mark-on-light.svg` | Mark on light backgrounds |
| `bronk-mark-mono-black.svg` / `-mono-white.svg` | One-colour (stickers, engraving, single-ink print) |
| `bronk-lockup.svg` / `-on-light.svg` | Mark + `bronk_` wordmark |
| `bronk-icon.svg` | Orange app tile: the main Bronk-branded app (welcome, updater) |
| `bronk-icon-dark.svg` | Dark app tile: everything else |

## png/

Both icon tiles at 16, 24, 32, 48, 64, 128, 256, 512; the mark at 512; lockups at 1024 wide.

For a hicolor icon theme in the image:

```
/usr/share/icons/hicolor/scalable/apps/bronk.svg      <- svg/bronk-icon.svg
/usr/share/icons/hicolor/<N>x<N>/apps/bronk.png       <- png/bronk-icon/<N>x<N>.png
```

## plymouth/bronk/

A Plymouth `script` theme: black screen, the b centred, the orange cursor blinking at about terminal speed. Also handles the LUKS passphrase prompt (shown under the mark as `unlock  ****`) and boot messages (bottom of the screen).

**Not boot-tested.** The script follows Plymouth's documented script API, but I could not run it here. Test it before baking it into the image (below).

### Try it on a running Silverblue system

`/usr` is read-only, so use a temporary overlay (it's gone after reboot):

```bash
sudo rpm-ostree usroverlay
sudo cp -r plymouth/bronk /usr/share/plymouth/themes/
sudo plymouth-set-default-theme bronk
sudo plymouthd --debug --debug-file=/tmp/plymouth.log
sudo plymouth show-splash
sleep 8
sudo plymouth ask-for-password --prompt="unlock"   # try the prompt
sudo plymouth quit
```

Do this from a TTY (Ctrl+Alt+F3), not inside a GNOME session, or the splash won't be visible. If something is off, `/tmp/plymouth.log` shows script errors.

### Bake it into the image

```dockerfile
COPY plymouth/bronk /usr/share/plymouth/themes/bronk
RUN plymouth-set-default-theme bronk
```

The theme only shows at boot once it's inside the **initramfs**, so the initramfs has to be regenerated in the build after that step. How you do that depends on your base. Images built on the Universal Blue / bootc pattern usually run `dracut` in the Containerfile against the image's kernel; follow whatever your base already does rather than adding a second regeneration. I'm not certain of the exact incantation for your setup, so check it against your build.

### Sizing

The mark is rendered at 160 px. On HiDPI panels Plymouth may scale it by the device scale factor. If it looks too big or small, regenerate `b.png` / `cursor.png` at a different size: keep the cursor at 12/64 × 8/64 of the mark size, so the script's positioning still lines up.
