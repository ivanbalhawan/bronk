# bronk_ wallpapers

> **How the image uses this kit** (IVA-68): the **3840×2160** set is installed from `system_files/usr/share/backgrounds/bronk/`, and `gnome/gnome-background-properties/bronk.xml` from `system_files/usr/share/gnome-background-properties/`. The default-wallpaper settings are in `system_files/usr/share/glib-2.0/schemas/zz1-bronk.gschema.override`, next to the login-screen logo, not in a separate `zz0-` file. The 2560×1600 set isn't in the repo; it's in the original `bronk-wallpapers.zip`.

Seven designs, each as a dark and a light version, at two sizes.

| Design | Logo? |
| --- | --- |
| terminal-grid | yes: lockup bottom-left, label top-left |
| forge-ember | no |
| runic | no (bronk in Elder Futhark runes, decorative) |
| one-block | implied: a single cursor block |
| tunnel | implied: cursor block at the vanishing point |
| yggdrasil | no |
| horizon | implied: cursor block on the horizon |

```
3840x2160/bronk-<design>-{dark,light}.png    16:9
2560x1600/bronk-<design>-{dark,light}.png    16:10
gnome/gnome-background-properties/bronk.xml  adds all 7 to Settings > Appearance
gnome/glib-2.0/schemas/zz0-bronk-background.gschema.override   default wallpaper
contact-sheet.png                            everything at a glance
```

## How GNOME uses them

`bronk.xml` lists each design once, with a light file (`<filename>`) and a dark file (`<filename-dark>`). GNOME picks one or the other when you switch between light and dark style. Each entry points at one size, so install the set that fits your screens:

- **3840×2160**: the safe default. With `zoom` it fills 16:10 screens too, cropping a little off the left and right. Every design is centred, so nothing important gets cut.
- **2560×1600**: smaller files, a native fit for 16:10 laptops.

The schema override sets **yggdrasil** as the default (light + dark, plus the lock screen). To use a different one, change the slug in that file. It only applies to users who haven't picked their own wallpaper; anyone who has keeps theirs.

## Bake into the image

```dockerfile
COPY wallpapers/3840x2160/ /usr/share/backgrounds/bronk/
COPY wallpapers/gnome/gnome-background-properties/bronk.xml /usr/share/gnome-background-properties/bronk.xml
COPY wallpapers/gnome/glib-2.0/schemas/zz0-bronk-background.gschema.override /usr/share/glib-2.0/schemas/
RUN glib-compile-schemas /usr/share/glib-2.0/schemas
```

The paths in `bronk.xml` and the override expect `/usr/share/backgrounds/bronk/`. If you install somewhere else, update both.

## Try them now without rebuilding

```bash
mkdir -p ~/.local/share/backgrounds/bronk
cp 3840x2160/*.png ~/.local/share/backgrounds/bronk/
gsettings set org.gnome.desktop.background picture-uri      "file://$HOME/.local/share/backgrounds/bronk/bronk-tunnel-light.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.local/share/backgrounds/bronk/bronk-tunnel-dark.png"
```
