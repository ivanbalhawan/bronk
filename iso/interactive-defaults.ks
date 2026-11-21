# Kickstart defaults for the bronk installer (copied to
# /usr/share/anaconda/interactive-defaults.ks; @PAYLOAD_IMAGE@ is filled in at build time).

# Install the image from the registry with bootc. The ISO's
# /etc/containers/policy.json (from bronk) checks its signature while pulling.
bootc --source-imgref registry:@PAYLOAD_IMAGE@ --target-imgref @PAYLOAD_IMAGE@

# Start the installed system on a signature-enforced origin (IVA-39). The bootc
# kickstart command has no option for that, so switch the origin in place.
#
# bootc switch needs the disk's top level at /sysroot in the installed system.
# Anaconda sets that up for ostreecontainer installs but not for bootc ones
# (PrepareBootcMountTargetsTask), so this script does it itself.
# --erroronfail: stop the install rather than finish with an unenforced origin.
%post --nochroot --erroronfail
set -euo pipefail
physroot=/mnt/sysimage
deploy=$(ls -d "${physroot}"/ostree/deploy/*/deploy/*/ | head -n1)
deploy=${deploy%/}

mounted=()
cleanup() { for m in "${mounted[@]}"; do umount "$m" || true; done; }
trap cleanup EXIT
mount --bind "${physroot}" "${deploy}/sysroot" && mounted=("${deploy}/sysroot")
# Anaconda normally has these mounted already; bind them if it doesn't
for api in /proc /sys /dev; do
    if ! mountpoint -q "${deploy}${api}"; then
        mount --bind "${api}" "${deploy}${api}" && mounted=("${deploy}${api}" "${mounted[@]}")
    fi
done
chroot "${deploy}" bootc switch --mutate-in-place --enforce-container-sigpolicy \
    --transport registry @PAYLOAD_IMAGE@

grep -H '^container-image-reference=' "${deploy}.origin"
grep -q '^container-image-reference=ostree-image-signed:' "${deploy}.origin"
%end
