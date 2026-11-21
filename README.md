# bronk

Personal Fedora Silverblue image built on
[`ghcr.io/ublue-os/silverblue-main:45`](https://github.com/ublue-os/main).
GitHub Actions builds it weekly, signs it with cosign and publishes it
publicly to `ghcr.io/ivanbalhawan/bronk`. Pulling needs no login; machines
trust it through the cosign signature. Never put secrets in this repo or the
image: machine-specific secrets are set up on the machine after install.

## What's different from silverblue-main

- Extra packages: `bat`, `btop`, `eza`, `fastfetch`, `fd-find`, `fzf`, `neovim`,
  `pipx`, `ranger`, `ripgrep`, `tldr`, `uv`, `zoxide`
- `podman.socket` enabled
- Anything under [`system_files/`](./system_files) is copied onto `/`

## Using it

From stock Silverblue, rebase in two steps. The first is unverified because
stock Silverblue doesn't know this image's signing key yet. The second
enforces signatures:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/ivanbalhawan/bronk:latest
systemctl reboot

sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ivanbalhawan/bronk:latest
systemctl reboot
```

## Verifying the signature

```bash
cosign verify --key cosign.pub ghcr.io/ivanbalhawan/bronk:latest
```

## Rollback

```bash
sudo bootc rollback && systemctl reboot   # or pick the previous entry in the boot menu
```

## Developing

| What | Where |
| --- | --- |
| Image name, description, tags, BIB image | [`image-template.env`](./image-template.env) |
| Base image | [`Containerfile`](./Containerfile) |
| Packages, services, other changes | [`build_files/build.sh`](./build_files/build.sh) |
| Files to drop onto `/` | [`system_files/`](./system_files) |
| CI build, sign and push | [`.github/workflows/build.yml`](./.github/workflows/build.yml) |
| Installer ISO settings | [`disk_config/iso.toml`](./disk_config/iso.toml) |
| VM disk settings | [`disk_config/disk.toml`](./disk_config/disk.toml) |

Local loop:

```bash
just build            # -> localhost/bronk:latest
just build-qcow2      # disk image from the LOCAL build
just run-vm-qcow2     # boot it
just --list           # everything else
```

Installer ISO, built locally from the published image (only needed for new installs):

```bash
podman pull ghcr.io/ivanbalhawan/bronk:latest
just build-iso ghcr.io/ivanbalhawan/bronk latest   # -> output/bootiso/install.iso
```

Tags published by CI: `latest`, `45`, `YYYYMMDD`, `latest-YYYYMMDD`, plus
git-SHA variants.

Reference for the upstream template (Justfile recipes, disk builds, NVIDIA):
[`docs/template-README.md`](./docs/template-README.md).
