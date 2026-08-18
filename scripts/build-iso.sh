#!/usr/bin/env bash
set -Eeuo pipefail

MINT_VERSION="${MINT_VERSION:-22.3}"
MINT_ISO="linuxmint-${MINT_VERSION}-xfce-64bit.iso"
MIRROR="${MINT_MIRROR:-https://pub.linuxmint.io/stable/${MINT_VERSION}}"
ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
WORK="${ROOT}/build"
SOURCE="${WORK}/${MINT_ISO}"
ISO_TREE="${WORK}/iso"
SQUASH_ROOT="${WORK}/squashfs-root"
OUTPUT="${ROOT}/dist/exp-mint-${MINT_VERSION}-xfce-amd64.iso"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

cleanup() {
  for path in dev/pts dev proc sys; do
    mountpoint -q "${SQUASH_ROOT}/${path}" && umount -lf "${SQUASH_ROOT}/${path}" || true
  done
}
trap cleanup EXIT

rm -rf "${WORK}" "${ROOT}/dist"
mkdir -p "${WORK}" "${ISO_TREE}" "${ROOT}/dist"

curl --fail --location --retry 5 -o "${SOURCE}" "${MIRROR}/${MINT_ISO}"
curl --fail --location --retry 5 -o "${WORK}/sha256sum.txt" "${MIRROR}/sha256sum.txt"
if ! awk -v iso="${MINT_ISO}" '$2 == iso || $2 == "*" iso { print }' \
  "${WORK}/sha256sum.txt" > "${WORK}/expected.sha256" || \
  [[ ! -s "${WORK}/expected.sha256" ]]; then
  echo "ERROR: ${MINT_ISO} was not found in the official Linux Mint checksum file." >&2
  exit 1
fi
(cd "${WORK}" && sha256sum --check expected.sha256)

xorriso -osirrox on -indev "${SOURCE}" -extract / "${ISO_TREE}"
chmod -R u+w "${ISO_TREE}"
unsquashfs -d "${SQUASH_ROOT}" "${ISO_TREE}/casper/filesystem.squashfs"

rsync -a "${ROOT}/overlay/" "${SQUASH_ROOT}/"
install -Dm0644 "${ROOT}/assets/exp-mint-wallpaper.png" \
  "${SQUASH_ROOT}/usr/share/backgrounds/exp-mint/exp-mint.png"
install -Dm0644 "${ROOT}/assets/exp-mint-mark.svg" \
  "${SQUASH_ROOT}/usr/share/icons/hicolor/scalable/apps/exp-mint.svg"

convert -background none "${ROOT}/assets/exp-mint-mark.svg" -resize 210x210 \
  "${SQUASH_ROOT}/usr/share/plymouth/themes/exp-mint/logo.png"
convert -background none "${ROOT}/assets/exp-mint-mark.svg" -resize 256x256 \
  "${SQUASH_ROOT}/etc/calamares/branding/exp-mint/exp-mint-logo.png"
convert "${ROOT}/assets/exp-mint-wallpaper.png" -resize '1280x720^' \
  -gravity center -extent 1280x720 \
  "${SQUASH_ROOT}/etc/calamares/branding/exp-mint/exp-mint-welcome.png"
convert "${ROOT}/assets/exp-mint-wallpaper.png" -resize '1024x768^' -gravity center -extent 1024x768 \
  "${SQUASH_ROOT}/boot/grub/themes/exp-mint/background.png"
convert -size 8x36 xc:'#69e6a4' "${SQUASH_ROOT}/boot/grub/themes/exp-mint/select_c.png"
cp "${SQUASH_ROOT}/boot/grub/themes/exp-mint/select_c.png" "${SQUASH_ROOT}/boot/grub/themes/exp-mint/select_w.png"
cp "${SQUASH_ROOT}/boot/grub/themes/exp-mint/select_c.png" "${SQUASH_ROOT}/boot/grub/themes/exp-mint/select_e.png"
chmod +x "${SQUASH_ROOT}/etc/skel/Desktop/exp-mint-installer.desktop"

cp -a "${SQUASH_ROOT}/boot/grub/themes/exp-mint" "${ISO_TREE}/boot/grub/themes/"
cp "${SQUASH_ROOT}/boot/grub/themes/exp-mint/background.png" "${ISO_TREE}/boot/grub/exp-mint-background.png"

# Give both live-boot GRUB configurations the theme without changing their menu entries.
while IFS= read -r cfg; do
  grep -q 'EXP Mint live theme' "${cfg}" || sed -i '1i # EXP Mint live theme\nset theme=/boot/grub/themes/exp-mint/theme.txt\nexport theme' "${cfg}"
done < <(find "${ISO_TREE}/boot/grub" -maxdepth 2 -name 'grub.cfg' -type f)

mount --bind /dev "${SQUASH_ROOT}/dev"
mount --bind /dev/pts "${SQUASH_ROOT}/dev/pts"
mount -t proc proc "${SQUASH_ROOT}/proc"
mount -t sysfs sys "${SQUASH_ROOT}/sys"
cp /etc/resolv.conf "${SQUASH_ROOT}/etc/resolv.conf"
chroot "${SQUASH_ROOT}" apt-get update
chroot "${SQUASH_ROOT}" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends calamares calamares-settings-lubuntu

# Keep Ubuntu's maintained Noble installer module wiring, but use EXP Mint's
# identity and artwork. This avoids fragile hand-written partition recipes.
if [[ -f "${SQUASH_ROOT}/etc/calamares/settings.conf" ]]; then
  sed -Ei 's/^([[:space:]]*branding:[[:space:]]*).*/\1exp-mint/' \
    "${SQUASH_ROOT}/etc/calamares/settings.conf"
else
  echo "ERROR: Calamares installed without /etc/calamares/settings.conf." >&2
  exit 1
fi

# Remove the old Linux Mint live-installer launchers so there is one clear path.
find "${SQUASH_ROOT}/usr/share/applications" "${SQUASH_ROOT}/etc/skel/Desktop" \
  -type f -name '*.desktop' -print0 2>/dev/null | while IFS= read -r -d '' desktop; do
    if grep -Eqi '(^Name=.*Install Linux Mint|live-installer|ubiquity)' "${desktop}"; then
      rm -f "${desktop}"
    fi
  done

chroot "${SQUASH_ROOT}" plymouth-set-default-theme -R exp-mint
chroot "${SQUASH_ROOT}" update-grub || true
chroot "${SQUASH_ROOT}" apt-get clean
rm -rf "${SQUASH_ROOT}/var/lib/apt/lists/"*
cleanup

rm -f "${ISO_TREE}/casper/filesystem.squashfs"
mksquashfs "${SQUASH_ROOT}" "${ISO_TREE}/casper/filesystem.squashfs" -comp xz -b 1M -noappend
du -sx --block-size=1 "${SQUASH_ROOT}" | cut -f1 > "${ISO_TREE}/casper/filesystem.size"

rm -f "${ISO_TREE}/md5sum.txt"
(cd "${ISO_TREE}" && find . -type f -print0 | sort -z | xargs -0 md5sum > md5sum.txt)

xorriso -as mkisofs \
  -r -V "EXP Mint ${MINT_VERSION}" -o "${OUTPUT}" \
  -J -joliet-long -l -iso-level 3 \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -partition_offset 16 \
  -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-gpt-basdat "${ISO_TREE}"

sha256sum "${OUTPUT}" > "${OUTPUT}.sha256"
echo "Built ${OUTPUT}"
